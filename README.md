# Ghost Inspector Test Generator

A bash script for generating Ghost Inspector visual regression test JSON files from a list of URLs, organized by domain.

## Requirements

- bash
- curl
- jq

The script checks for `curl` and `jq` at startup and exits with installation instructions if missing.

## Quick Start

```bash
./generate-tests.sh
```

The script will guide you through:

1. **Template Selection** - Use the default `templates/template.json` or paste a custom template
2. **URL Input** - Paste URLs one per line, press Enter on empty line when done
3. **Validation** - Invalid URLs and duplicates are automatically skipped with warnings
4. **Confirmation** - Review files to be created (existing files show `[OVERWRITE]` warning)
5. **File Generation** - Creates JSON test files in `build/<domain>/` subdirectories
6. **Notes Generation** - Creates `_notes.txt` per domain with run history and settings
7. **API Import** (optional) - Import tests directly to a Ghost Inspector suite

## Example Run

See **[example.txt](example.txt)** for a complete example run showing:
- Valid and invalid URLs
- Duplicate URL handling
- Domain organization output
- _notes.txt generation
- API import flow

## Output Structure

Files are organized by domain in the `build/` directory:

```
build/
├── example.com/
│   ├── _notes.txt
│   ├── Home.json
│   ├── About.json
│   └── Products_Widgets.json
└── other-site.com/
    ├── _notes.txt
    └── Contact.json
```

## Notes File

Each `_notes.txt` contains:

- Last run timestamp
- Template used
- Test files table (filename, test name, URL)
- All template settings (screenshot compare, thresholds, browser, viewport, etc.)
- HTTP headers (if configured)
- Test steps with commands

This helps track when tests were generated and what each file is for.

## Example Run

```
Ghost Inspector Test Generator
===============================

Template options:
  1) Use template.json (default)
  2) Paste custom template

Select option [1]: 1

Using template.json

Paste your URLs (one per line).
Press Enter on an empty line when done:

https://example.com/
https://example.com/
https://invalid
  https://example.com/about/
https://other.com/contact

Warning: Skipped 1 invalid URL(s):
  Line 3: https://invalid

Warning: Skipped 1 duplicate URL(s):
  https://example.com/

The following test files will be created:
-----------------------------------------
  build/example.com/Home.json  <--  https://example.com/
  build/example.com/About.json  <--  https://example.com/about/  [OVERWRITE]
  build/other.com/Contact.json  <--  https://other.com/contact

Warning: 1 file(s) will be overwritten.

Total: 3 test(s)

Proceed with file creation? (y/n): y

Creating test files...
  Created: build/example.com/Home.json
  Created: build/example.com/About.json
  Created: build/other.com/Contact.json

Done! Created 3 test file(s).

Generating notes...
  Created: build/example.com/_notes.txt
  Created: build/other.com/_notes.txt
```

## File Naming Convention

| URL | Filename | Test Name |
|-----|----------|-----------|
| `/` | `Home.json` | `Home` |
| `/about/` | `About.json` | `About` |
| `/funds/etfs/` | `Funds_Etfs.json` | `Funds / Etfs` |
| `/closed-end-funds/` | `Closed-End-Funds.json` | `Closed End Funds` |

- Filenames: path segments joined with `_`, capitalized, hyphens preserved
- Test names: path segments joined with ` / `, hyphens replaced with spaces

## Validation

The script includes comprehensive input validation:

| Check | Behavior |
|-------|----------|
| Invalid URL format | Skips URLs not starting with `http://` or `https://` |
| Duplicate URLs | Skips exact duplicate URLs |
| Duplicate filenames | Skips URLs that produce the same output filename |
| Whitespace in URLs | Automatically trims leading/trailing spaces |
| Invalid JSON template | Exits if custom template is not valid JSON |
| Missing placeholders | Exits if template lacks `TEST_NAME` or `START_URL` |
| File overwrites | Displays `[OVERWRITE]` warning for existing files |

Invalid URLs and duplicates are reported but don't stop the script—valid URLs continue processing.

## Template Placeholders

The template uses two required placeholders:

- `TEST_NAME` - Replaced with human-readable test name derived from URL path
- `START_URL` - Replaced with the full URL

Example: `https://example.com/products/widgets/`
- `TEST_NAME` becomes `Products / Widgets`
- `START_URL` becomes `https://example.com/products/widgets/`

## Exporting Test Settings from Ghost Inspector

To export existing test configurations as JSON for use with this script:

1. Open Ghost Inspector test
2. Click **More** menu (top right)
3. Select **Export test**
4. Download JSON file
5. Use as custom template (option 2 in script) or modify for bulk generation

See [assets/screenshot-export-test.png](assets/screenshot-export-test.png) for visual walkthrough.

## API Key Security

When importing tests to Ghost Inspector, the script prompts for your API key:

```
Enter API Key:
(input is hidden - type your API key and press Enter)
```

**Key features:**
- API key input is **hidden** (characters don't appear on screen)
- Key is **never stored** in script, config files, or shell history
- Key exists only in **memory during the session**
- Key is **securely transmitted** to Ghost Inspector API
- Key is **safely discarded** after import completes

**Security practices:**
- ✓ Use interactive prompts (don't hardcode keys)
- ✓ Never commit API keys to version control
- ✗ Never store keys in plaintext config files
- ✗ Never pass keys as command arguments

For detailed security practices and explanations, see `example.txt` (section: "Security Practices for API Keys").

## License

MIT
