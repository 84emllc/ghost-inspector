#!/bin/bash

# Ghost Inspector Test Generator
# Generates test JSON files from URLs and optionally imports them via API

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/template.json"

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
while IFS= read -r line; do
    # Break on empty line
    [[ -z "$line" ]] && break
    urls+=("$line")
done

# Check we have URLs
if [[ ${#urls[@]} -eq 0 ]]; then
    echo "No URLs provided. Exiting."
    exit 0
fi

# Phase 2: Confirmation
echo ""
echo "The following test files will be created:"
echo "-----------------------------------------"

created_files=()
for url in "${urls[@]}"; do
    filename="$(url_to_filename "$url").json"
    created_files+=("$filename")
    echo "  $filename  <--  $url"
done

echo ""
echo "Total: ${#urls[@]} test(s)"
echo ""
read -p "Proceed with file creation? (y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

# Phase 3: Create files
echo ""
echo "Creating test files..."

for i in "${!urls[@]}"; do
    url="${urls[$i]}"
    filename="${created_files[$i]}"
    test_name="$(url_to_testname "$url")"

    # Replace placeholders
    json="${TEMPLATE//TEST_NAME/$test_name}"
    json="${json//START_URL/$url}"

    # Write file
    echo "$json" > "${SCRIPT_DIR}/${filename}"
    echo "  Created: $filename"
done

echo ""
echo "Done! Created ${#urls[@]} test file(s)."

# Phase 4: API Import
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

for filename in "${created_files[@]}"; do
    filepath="${SCRIPT_DIR}/${filename}"

    echo -n "  Importing ${filename}... "

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
