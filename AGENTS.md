# Ghost Inspector Test Generator

**Version:** 1.0.0 | **Semver:** ✓ | **Changelog:** CHANGELOG.md

## Overview

This project provides a bash script for generating Ghost Inspector visual regression test JSON files from a list of URLs, with optional API import.

## Key Files

- `generate-tests.sh` - Main script for generating tests and importing to Ghost Inspector (v1.0.0)
- `templates/template.json` - Default test template with `TEST_NAME` and `START_URL` placeholders
- `templates/template.md` - Comprehensive guide to all template settings and customization
- `example.txt` - Complete example run demonstrating all features and workflows
- `build/` - Output directory for generated test files (organized by domain)
- `VERSION` - Current semantic version
- `CHANGELOG.md` - Changelog following Keep a Changelog format

## Example Walkthrough

**File:** `example.txt`

Comprehensive walkthrough demonstrating:

- **Complete Script Flow**: Shows entire interactive session from start to finish
- **Input Validation**: Examples of invalid URL rejection, duplicate URL detection, whitespace trimming
- **Domain Organization**: Output structure with multiple domains in single run
- **Warnings & Feedback**: All warning messages (invalid URLs, duplicates, overwrites)
- **File Generation**: Creation of JSON tests and _notes.txt per domain
- **Notes File Contents**: Sample markdown output showing all configuration details
- **API Import**: Dynamic suite fetching, selection, and import status
- **Success Summary**: Final statistics on created and imported tests

Use this example to understand:
- How validation handles problematic inputs
- How domain organization groups tests
- What _notes.txt contains and why it's useful
- How API import workflow functions
- Expected output and error messages

See `example.txt` in root directory or linked in README.md.

## Exporting Test Settings from Ghost Inspector

**File:** `assets/screenshot-export-test.png`

Visual guide showing how to export existing Ghost Inspector test configurations as JSON for bulk generation.

**What the Screenshot Shows:**

The Ghost Inspector UI for a test (example: "About" page test) with the **More** menu expanded, highlighting:

1. **Test Navigation** - Breadcrumb showing: Dashboard > Suite > Domain > Test
2. **Test Management Tabs** - Quick access to Suite schedule, Settings, Edit steps
3. **More Menu Options** - Dropdown menu showing:
   - Run test w/custom settings
   - Run test w/spreadsheet data
   - **Export test** (highlighted) - Downloads test JSON configuration
   - Duplicate test

**Why This Matters:**

- **Reuse Existing Tests** - Export a well-configured test from Ghost Inspector, then use it as a template for bulk generation
- **Custom Templates** - Export JSON, modify it, then provide as custom template (option 2) during script run
- **Test Standardization** - Export a reference test, use across multiple domains/URLs
- **Consistency** - Ensure all bulk-generated tests use identical settings (screenshot thresholds, browser, viewport, etc.)

**How to Use:**

1. Create a reference test in Ghost Inspector with desired settings
2. Click **More** > **Export test**
3. Download JSON file
4. Use in script as:
   - Direct custom template (paste JSON when prompted)
   - Edit JSON to customize and save as custom template file
   - Extract specific settings to modify default template.json

**Integration Workflow:**

```
Ghost Inspector Test (configured)
         ↓ (export)
    JSON File
         ↓ (use as)
   Custom Template
         ↓ (script option 2)
Bulk Generate Tests
```

See `assets/screenshot-export-test.png` for visual reference.

## URL to Filename Convention

| URL Pattern | Filename | Test Name |
|-------------|----------|-----------|
| `/` | `Home.json` | `Home` |
| `/about/` | `About.json` | `About` |
| `/funds/etfs/` | `Funds_Etfs.json` | `Funds / Etfs` |
| `/closed-end-funds/` | `Closed-End-Funds.json` | `Closed End Funds` |

- Filenames: path segments joined with `_`, capitalized, hyphens preserved
- Test names: path segments joined with ` / `, hyphens replaced with spaces

## Output Structure

Test files are organized by domain in the `build/` directory. Each domain folder includes a `_notes.txt` markdown file with run history and settings:

```
build/
├── example.com/
│   ├── _notes.txt
│   ├── Home.json
│   └── About.json
└── other-site.com/
    ├── _notes.txt
    └── Contact.json
```

### Notes File Contents

Each `_notes.txt` includes:
- Last run timestamp
- Template used
- Tests table (file, name, URL)
- All template settings (screenshot compare, thresholds, browser, viewport, etc.)
- HTTP headers (if any)
- Steps with commands

## Script Flow

1. Template selection (use `template.json` or paste custom)
2. Collect URLs from user (one per line, blank line to finish)
3. Display files to be created with confirmation
4. Generate JSON files
5. Generate `_notes.txt` for each domain
6. Optional: Import to Ghost Inspector
   - Prompt for API key
   - Fetch and display available suites
   - User selects suite
   - Confirm before import
   - Execute API calls

## Validation

The script includes comprehensive input validation:

| Check | Behavior |
|-------|----------|
| Missing dependencies | Exits with install instructions if `jq` or `curl` not found |
| Invalid URL format | Skips URLs not starting with `http://` or `https://` |
| Duplicate URLs | Skips exact duplicate URLs |
| Duplicate filenames | Skips URLs that would produce the same output file |
| Invalid JSON template | Exits if custom template is not valid JSON |
| Missing placeholders | Exits if template lacks `TEST_NAME` or `START_URL` |
| Whitespace in URLs | Automatically trims leading/trailing whitespace |
| File overwrites | Shows `[OVERWRITE]` warning for existing files |

## API Key Security

**Implementation:** `read -s -p "Enter API Key: " api_key`

The script uses bash's `-s` flag (silent mode) for secure API key input.

**How It Works:**

1. **Interactive Prompt** - User enters API key when needed
   - Not required until import flow initiated (optional feature)
   - User controls timing and flow

2. **Hidden Input** - Characters not echoed to terminal
   - Typed characters don't appear on screen
   - Prevents shoulder-surfing/visual exposure
   - Terminal shows only prompt, no feedback

3. **Memory-Only Storage** - Key never persists on disk
   - Variable exists only in shell memory during session
   - Not written to files, logs, or backups
   - Not saved to shell history (history only shows command, not input)

4. **Secure Transmission** - Direct API call via curl
   - Key sent directly in API request to Ghost Inspector
   - HTTPS encryption protects in-transit
   - No intermediate storage or caching

5. **Session Cleanup** - Key discarded after use
   - Variable destroyed when script ends
   - No lingering traces on system
   - Easy to revoke key if compromised

**Why This Approach:**

✓ **Prevents Accidental Exposure** - Not stored where it could be leaked
✓ **Revocation-Friendly** - Can immediately invalidate key if needed
✓ **Version Control Safe** - Can safely commit script to GitHub
✓ **User Control** - User decides when to provide key
✓ **No Configuration Hell** - No config files to manage/protect

**What NOT to Do:**

✗ **Hardcoding** - Never embed key in script
   ```bash
   api_key="sk_live_abc123"  # WRONG
   ```
   Risks: Visible in version control, readable by all users

✗ **Config Files** - Never store in `.env` or config files
   ```
   API_KEY=sk_live_abc123  # WRONG
   ```
   Risks: File-level permissions hard to manage, committed accidentally

✗ **Command Arguments** - Never pass as CLI flag
   ```bash
   ./script.sh --api-key=secret123  # WRONG
   ```
   Risks: Visible in `ps aux`, shell history, process monitoring

✗ **Environment Variables (Global)** - Global env vars accessible to all processes
   ```bash
   export GHOST_INSPECTOR_KEY="..."  # RISKY
   ```
   Risks: Any process can read environment, persists in shell config

**Best Practices:**

1. **Rotate Keys Regularly** - Periodically regenerate API keys
2. **Revoke Immediately** - If key is compromised, revoke immediately
3. **Use CI/CD Secrets** - For automation, use platform-specific secret management
   - GitHub Secrets for GitHub Actions
   - GitLab CI/CD Variables for GitLab CI
   - AWS Secrets Manager for AWS Lambda
4. **Terminal Hygiene** - Clear terminal after script runs (`clear` command)
5. **Share Without Secrets** - When sharing scripts, remove any credentials
6. **Document Expectations** - Document that script will prompt for sensitive input

**For CI/CD Integration:**

Do NOT hardcode keys. Instead:

GitHub Actions example:
```yaml
- name: Generate tests
  run: ./generate-tests.sh
  env:
    GHOST_INSPECTOR_API_KEY: ${{ secrets.GHOST_INSPECTOR_API_KEY }}
```

Then modify script to read from environment variable if needed (currently requires interactive input by design).

See `example.txt` for comprehensive security guide and comparison of secure vs. insecure approaches.

## Dependencies

- `bash`
- `curl`
- `jq` (for JSON parsing)
