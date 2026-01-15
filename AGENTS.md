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

## Dependencies

- `bash`
- `curl`
- `jq` (for JSON parsing)
