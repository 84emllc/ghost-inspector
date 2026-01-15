#!/bin/bash

# Ghost Inspector Test Generator
# Generates test JSON files from URLs and optionally imports them via API

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/templates/template.json"

# Dependency checks
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt install jq (Linux) or brew install jq (macOS)"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed."
    exit 1
fi

# Template selection
echo "Ghost Inspector Test Generator"
echo "==============================="
echo ""
echo "Template options:"
echo "  1) Use template.json (default)"
echo "  2) Paste custom template"
echo ""
read -p "Select option [1]: " template_option

TEMPLATE=""

if [[ "$template_option" == "2" ]]; then
    echo ""
    echo "Paste your template JSON (press Enter twice when done):"
    echo ""

    custom_template=""
    empty_line_count=0

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            ((empty_line_count++)) || true
            if [[ $empty_line_count -ge 1 ]]; then
                break
            fi
        else
            empty_line_count=0
            custom_template="${custom_template}${line}"
        fi
    done

    if [[ -z "$custom_template" ]]; then
        echo "Error: No template provided."
        exit 1
    fi

    # Validate JSON
    if ! echo "$custom_template" | jq empty 2>/dev/null; then
        echo "Error: Invalid JSON in custom template."
        exit 1
    fi

    TEMPLATE="$custom_template"
    echo ""
    echo "Custom template loaded."
else
    # Check template exists
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        echo "Error: template.json not found in ${SCRIPT_DIR}"
        exit 1
    fi

    TEMPLATE=$(cat "$TEMPLATE_FILE")
    echo ""
    echo "Using template.json"
fi

# Validate template placeholders
if [[ "$TEMPLATE" != *"TEST_NAME"* ]]; then
    echo "Error: Template missing TEST_NAME placeholder."
    exit 1
fi

if [[ "$TEMPLATE" != *"START_URL"* ]]; then
    echo "Error: Template missing START_URL placeholder."
    exit 1
fi

# Function to extract base domain from URL
url_to_domain() {
    local url="$1"
    echo "$url" | sed -E 's|^https?://([^/]+).*|\1|'
}

# Function to convert URL to filename
url_to_filename() {
    local url="$1"
    local path

    # Extract path from URL (remove protocol and domain)
    path=$(echo "$url" | sed -E 's|^https?://[^/]+||')

    # Remove trailing slash
    path="${path%/}"

    # Handle root path
    if [[ -z "$path" || "$path" == "/" ]]; then
        echo "Home"
        return
    fi

    # Remove leading slash
    path="${path#/}"

    # Split by / and process each segment
    local result=""
    IFS='/' read -ra segments <<< "$path"

    for segment in "${segments[@]}"; do
        # Capitalize first letter, preserve rest (including hyphens)
        local capitalized="${segment^}"

        if [[ -z "$result" ]]; then
            result="$capitalized"
        else
            result="${result}_${capitalized}"
        fi
    done

    echo "$result"
}

# Function to convert URL to test name (human readable)
url_to_testname() {
    local url="$1"
    local path

    # Extract path from URL (remove protocol and domain)
    path=$(echo "$url" | sed -E 's|^https?://[^/]+||')

    # Remove trailing slash
    path="${path%/}"

    # Handle root path
    if [[ -z "$path" || "$path" == "/" ]]; then
        echo "Home"
        return
    fi

    # Remove leading slash
    path="${path#/}"

    # Split by / and process each segment
    local result=""
    IFS='/' read -ra segments <<< "$path"

    for segment in "${segments[@]}"; do
        # Replace hyphens/dashes with spaces, then capitalize each word
        local words=$(echo "$segment" | sed 's/[-_]/ /g')
        local capitalized=""
        for word in $words; do
            capitalized="${capitalized}${word^} "
        done
        # Trim trailing space
        capitalized="${capitalized% }"

        if [[ -z "$result" ]]; then
            result="$capitalized"
        else
            result="${result} / ${capitalized}"
        fi
    done

    echo "$result"
}

# Phase 1: Collect URLs
echo ""
echo "Paste your URLs (one per line)."
echo "Press Enter on an empty line when done:"
echo ""

urls=()
invalid_urls=()
duplicate_urls=()
line_num=0

while IFS= read -r line; do
    # Break on empty line
    [[ -z "$line" ]] && break
    ((line_num++)) || true

    # Trim whitespace
    url=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Skip if empty after trim
    [[ -z "$url" ]] && continue

    # Validate URL format
    if ! [[ "$url" =~ ^https?:// ]]; then
        invalid_urls+=("Line $line_num: $url")
        continue
    fi

    # Check for duplicates
    if [[ " ${urls[*]} " =~ " ${url} " ]]; then
        duplicate_urls+=("$url")
        continue
    fi

    urls+=("$url")
done

# Report invalid URLs
if [[ ${#invalid_urls[@]} -gt 0 ]]; then
    echo ""
    echo "Warning: Skipped ${#invalid_urls[@]} invalid URL(s):"
    for invalid in "${invalid_urls[@]}"; do
        echo "  $invalid"
    done
fi

# Report duplicate URLs
if [[ ${#duplicate_urls[@]} -gt 0 ]]; then
    echo ""
    echo "Warning: Skipped ${#duplicate_urls[@]} duplicate URL(s):"
    for dup in "${duplicate_urls[@]}"; do
        echo "  $dup"
    done
fi

# Check we have URLs
if [[ ${#urls[@]} -eq 0 ]]; then
    echo ""
    echo "No valid URLs provided. Exiting."
    exit 0
fi

# Phase 2: Confirmation
BUILD_DIR="${SCRIPT_DIR}/build"

echo ""
echo "The following test files will be created:"
echo "-----------------------------------------"

created_files=()
created_domains=()
created_urls=()
created_paths=()
duplicate_filenames=()
existing_files=()

for url in "${urls[@]}"; do
    domain="$(url_to_domain "$url")"
    filename="$(url_to_filename "$url").json"
    filepath="build/${domain}/${filename}"
    full_path="${BUILD_DIR}/${domain}/${filename}"

    # Check for duplicate filenames (same domain + filename)
    if [[ " ${created_paths[*]} " =~ " ${filepath} " ]]; then
        duplicate_filenames+=("$filepath (from $url)")
    else
        created_files+=("$filename")
        created_domains+=("$domain")
        created_urls+=("$url")
        created_paths+=("$filepath")

        # Check if file already exists
        if [[ -f "$full_path" ]]; then
            existing_files+=("$filepath")
            echo "  $filepath  <--  $url  [OVERWRITE]"
        else
            echo "  $filepath  <--  $url"
        fi
    fi
done

# Report duplicate filenames
if [[ ${#duplicate_filenames[@]} -gt 0 ]]; then
    echo ""
    echo "Warning: Skipped ${#duplicate_filenames[@]} duplicate filename(s):"
    for dup in "${duplicate_filenames[@]}"; do
        echo "  $dup"
    done
fi

# Warn about overwrites
if [[ ${#existing_files[@]} -gt 0 ]]; then
    echo ""
    echo "Warning: ${#existing_files[@]} file(s) will be overwritten."
fi

echo ""
echo "Total: ${#created_files[@]} test(s)"
echo ""
read -p "Proceed with file creation? (y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

# Phase 3: Create files
echo ""
echo "Creating test files..."

for i in "${!created_files[@]}"; do
    url="${created_urls[$i]}"
    filename="${created_files[$i]}"
    domain="${created_domains[$i]}"
    test_name="$(url_to_testname "$url")"

    # Create domain subdirectory
    domain_dir="${BUILD_DIR}/${domain}"
    mkdir -p "$domain_dir"

    # Replace placeholders
    json="${TEMPLATE//TEST_NAME/$test_name}"
    json="${json//START_URL/$url}"

    # Write file
    filepath="${domain_dir}/${filename}"
    echo "$json" > "$filepath"
    echo "  Created: build/${domain}/${filename}"
done

echo ""
echo "Done! Created ${#created_files[@]} test file(s)."

# Phase 4: Generate notes for each domain
echo ""
echo "Generating notes..."

# Get unique domains
unique_domains=($(printf '%s\n' "${created_domains[@]}" | sort -u))

# Get template name for notes
template_name="template.json"
if [[ "$template_option" == "2" ]]; then
    template_name="custom (pasted)"
fi

# Parse template settings
setting_screenshot_enabled=$(echo "$TEMPLATE" | jq -r '.screenshotCompareEnabled // "default"')
setting_screenshot_threshold=$(echo "$TEMPLATE" | jq -r '.screenshotCompareThreshold // "default"')
setting_fail_js_error=$(echo "$TEMPLATE" | jq -r '.failOnJavaScriptError // "default"')
setting_auto_retry=$(echo "$TEMPLATE" | jq -r '.autoRetry // "default"')
setting_browser=$(echo "$TEMPLATE" | jq -r '.browser // "default"')
setting_viewport=$(echo "$TEMPLATE" | jq -r '.viewportSize // "default"')
setting_region=$(echo "$TEMPLATE" | jq -r '.region // "default"')
setting_frequency=$(echo "$TEMPLATE" | jq -r '.testFrequency // "default"')
setting_insecure_certs=$(echo "$TEMPLATE" | jq -r '.disallowInsecureCertificates // "default"')
setting_max_ajax=$(echo "$TEMPLATE" | jq -r '.maxAjaxDelay // "default"')
setting_max_wait=$(echo "$TEMPLATE" | jq -r '.maxWaitDelay // "default"')
setting_final_delay=$(echo "$TEMPLATE" | jq -r '.finalDelay // "default"')
setting_step_delay=$(echo "$TEMPLATE" | jq -r '.globalStepDelay // "default"')

# Parse HTTP headers
http_headers=$(echo "$TEMPLATE" | jq -r '.httpHeaders | if length == 0 then "None" else .[] | "\(.name): \(.value)" end')

# Parse steps
steps_count=$(echo "$TEMPLATE" | jq -r '.steps | length')
steps_detail=$(echo "$TEMPLATE" | jq -r '.steps | to_entries | .[] | "\(.key + 1). **\(.value.command)** - `\(.value.value)`"')

# Format test frequency
if [[ "$setting_frequency" == "0" ]]; then
    setting_frequency="manual"
fi

# Format screenshot enabled
if [[ "$setting_screenshot_enabled" == "true" ]]; then
    setting_screenshot_enabled="enabled"
elif [[ "$setting_screenshot_enabled" == "false" ]]; then
    setting_screenshot_enabled="disabled"
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')

for domain in "${unique_domains[@]}"; do
    notes_file="${BUILD_DIR}/${domain}/_notes.txt"

    # Build tests table rows for this domain
    tests_table=""
    for i in "${!created_files[@]}"; do
        if [[ "${created_domains[$i]}" == "$domain" ]]; then
            tests_table="${tests_table}| ${created_files[$i]} | $(url_to_testname "${created_urls[$i]}") | ${created_urls[$i]} |"$'\n'
        fi
    done

    # Write markdown notes
    cat > "$notes_file" << EOF
# ${domain}

**Last Run:** ${timestamp}
**Template:** ${template_name}

---

## Tests

| File | Test Name | URL |
|------|-----------|-----|
${tests_table}
---

## Settings

| Setting | Value |
|---------|-------|
| Screenshot Compare | ${setting_screenshot_enabled} |
| Screenshot Threshold | ${setting_screenshot_threshold} |
| Fail on JS Error | ${setting_fail_js_error} |
| Auto Retry | ${setting_auto_retry} |
| Browser | ${setting_browser} |
| Viewport | ${setting_viewport} |
| Region | ${setting_region} |
| Test Frequency | ${setting_frequency} |
| Disallow Insecure Certs | ${setting_insecure_certs} |
| Max Ajax Delay | ${setting_max_ajax} |
| Max Wait Delay | ${setting_max_wait} |
| Final Delay | ${setting_final_delay} |
| Global Step Delay | ${setting_step_delay} |

---

## HTTP Headers

${http_headers}

---

## Steps (${steps_count})

${steps_detail}
EOF

    echo "  Created: build/${domain}/_notes.txt"
done

# Phase 5: API Import
echo ""
read -p "Import tests to Ghost Inspector suite? (y/n): " import_confirm

if [[ "$import_confirm" != "y" && "$import_confirm" != "Y" ]]; then
    echo ""
    echo "Files created. Skipping API import."
    exit 0
fi

# Get API Key (hidden input)
echo ""
read -s -p "Enter API Key: " api_key
echo ""

if [[ -z "$api_key" ]]; then
    echo "Error: API Key is required."
    exit 1
fi

# Fetch and display suites
echo ""
echo "Fetching suites from Ghost Inspector..."

suites_response=$(curl -s "https://api.ghostinspector.com/v1/suites/?apiKey=${api_key}")

# Check for valid response
if ! echo "$suites_response" | grep -q '"code":"SUCCESS"'; then
    echo "Error: Failed to fetch suites. Check your API key."
    exit 1
fi

# Parse suites into arrays using jq
suite_ids=()
suite_names=()

while IFS= read -r line; do
    suite_ids+=("$line")
done < <(echo "$suites_response" | jq -r '.data[]._id')

while IFS= read -r line; do
    suite_names+=("$line")
done < <(echo "$suites_response" | jq -r '.data[].name')

if [[ ${#suite_ids[@]} -eq 0 ]]; then
    echo "Error: No suites found in your account."
    exit 1
fi

echo ""
echo "Available suites:"
echo "-----------------"

for i in "${!suite_ids[@]}"; do
    echo "  $((i + 1))) ${suite_names[$i]} (${suite_ids[$i]})"
done

echo ""
read -p "Select suite [1-${#suite_ids[@]}]: " suite_choice

# Validate choice
if [[ -z "$suite_choice" ]] || ! [[ "$suite_choice" =~ ^[0-9]+$ ]] || [[ "$suite_choice" -lt 1 ]] || [[ "$suite_choice" -gt ${#suite_ids[@]} ]]; then
    echo "Error: Invalid selection."
    exit 1
fi

suite_id="${suite_ids[$((suite_choice - 1))]}"
suite_name="${suite_names[$((suite_choice - 1))]}"

echo ""
echo "Selected: ${suite_name} (${suite_id})"
echo ""
read -p "Import ${#created_files[@]} test(s) to this suite? (y/n): " final_confirm

if [[ "$final_confirm" != "y" && "$final_confirm" != "Y" ]]; then
    echo ""
    echo "Import cancelled. Files were still created."
    exit 0
fi

# Import each file
echo ""
echo "Importing tests to Ghost Inspector..."
echo ""

success_count=0
fail_count=0

for i in "${!created_files[@]}"; do
    filename="${created_files[$i]}"
    domain="${created_domains[$i]}"
    filepath="${BUILD_DIR}/${domain}/${filename}"

    echo -n "  Importing ${domain}/${filename}... "

    response=$(curl -s -w "\n%{http_code}" \
        "https://api.ghostinspector.com/v1/suites/${suite_id}/import-test/json?apiKey=${api_key}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d @"${filepath}")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
        echo "OK"
        success_count=$((success_count + 1))
    else
        echo "FAILED (HTTP $http_code)"
        fail_count=$((fail_count + 1))
    fi
done

echo ""
echo "Import complete!"
echo "  Success: $success_count"
echo "  Failed:  $fail_count"
