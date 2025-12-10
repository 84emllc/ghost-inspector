# Ghost Inspector Test Generator

## Overview

This project provides a bash script for generating Ghost Inspector visual regression test JSON files from a list of URLs, with optional API import.

## Key Files

- `generate-tests.sh` - Main script for generating tests and importing to Ghost Inspector
- `template.json` - Default test template with `TEST_NAME` and `START_URL` placeholders

## URL to Filename Convention

| URL Pattern | Filename | Test Name |
|-------------|----------|-----------|
| `/` | `Home.json` | `Home` |
| `/about/` | `About.json` | `About` |
| `/funds/etfs/` | `Funds_Etfs.json` | `Funds / Etfs` |
| `/closed-end-funds/` | `Closed-End-Funds.json` | `Closed End Funds` |

- Filenames: path segments joined with `_`, capitalized, hyphens preserved
- Test names: path segments joined with ` / `, hyphens replaced with spaces

## Script Flow

1. Template selection (use `template.json` or paste custom)
2. Collect URLs from user (one per line, blank line to finish)
3. Display files to be created with confirmation
4. Generate JSON files
5. Optional: Import to Ghost Inspector
   - Prompt for API key
   - Fetch and display available suites
   - User selects suite
   - Confirm before import
   - Execute API calls

## Dependencies

- `bash`
- `curl`
- `jq` (for JSON parsing)
