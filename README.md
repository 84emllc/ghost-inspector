# Ghost Inspector Test Generator

A bash script for generating Ghost Inspector visual regression test files from a list of URLs.

## Requirements

- bash
- curl
- jq

## Usage

```bash
./generate-tests.sh
```

The script will guide you through:

1. **Template Selection** - Use the default `template.json` or paste a custom template
2. **URL Input** - Paste URLs one per line, press Enter on empty line when done
3. **Confirmation** - Review files to be created
4. **API Import** (optional) - Import tests directly to a Ghost Inspector suite

## Example

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
https://example.com/about/
https://example.com/products/widgets/

The following test files will be created:
-----------------------------------------
  Home.json  <--  https://example.com/
  About.json  <--  https://example.com/about/
  Products_Widgets.json  <--  https://example.com/products/widgets/

Total: 3 test(s)

Proceed with file creation? (y/n): y
```

## File Naming Convention

| URL | Filename | Test Name |
|-----|----------|-----------|
| `/` | `Home.json` | `Home` |
| `/about/` | `About.json` | `About` |
| `/funds/etfs/` | `Funds_Etfs.json` | `Funds / Etfs` |
| `/closed-end-funds/` | `Closed-End-Funds.json` | `Closed End Funds` |

## Template Placeholders

The template uses two placeholders:

- `TEST_NAME` - Replaced with human-readable test name
- `START_URL` - Replaced with the full URL

## License

MIT
