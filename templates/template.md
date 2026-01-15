# Template Configuration Guide

This document explains all settings in `templates/template.json` and how to customize them for different testing scenarios.

## Overview

The template is the blueprint for all generated tests. Each setting controls test behavior, environment, and execution. Values set to `null` use Ghost Inspector defaults.

## Settings Reference

### Test Identity

**`name`** (string)
- Current: `TEST_NAME` (placeholder)
- Replaced with human-readable test name derived from URL path
- Example: `https://example.com/products/` → `Products`

**`startUrl`** (string)
- Current: `START_URL` (placeholder)
- Replaced with full URL for each test
- Must be valid HTTP/HTTPS URL

### Visual Testing

**`screenshotCompareEnabled`** (boolean)
- Current: `true`
- Enable/disable visual regression comparison
- Set to `false` to disable screenshot comparisons
- Set to `true` (default) to capture and compare screenshots

**`screenshotCompareThreshold`** (float)
- Current: `0.1`
- Range: 0.0 to 1.0 (0% to 100% difference tolerance)
- `0.1` = 10% allowed pixel difference
- Lower values = stricter comparison
- `0.0` = exact pixel match required
- Increase for dynamic content, animations, or ads

**`disableVisuals`** (null/boolean)
- Current: `null` (uses default)
- Set to `true` to skip visual capture entirely
- Set to `false` or leave `null` to enable visuals
- Useful for performance-only tests

### Test Execution

**`testFrequency`** (integer)
- Current: `0`
- `0` = manual execution only
- `1-59` = minutes between automatic runs
- `60` = hourly
- `1440` = daily
- `10080` = weekly
- Repeats automatically on Ghost Inspector platform

**`testFrequencyAdvanced`** (array)
- Current: `[]` (empty)
- Advanced scheduling (e.g., specific times/days)
- Leave empty unless specific scheduling needed

**`failOnJavaScriptError`** (null/boolean)
- Current: `null` (uses default)
- Set to `true` to fail test if JS errors occur
- Set to `false` to ignore JS errors
- Set to `null` for platform default behavior

**`maxWaitDelay`** (null/integer)
- Current: `null` (uses default)
- Maximum milliseconds to wait for elements to appear
- Example: `5000` = 5 second max wait
- Helpful for slow-loading pages

**`maxAjaxDelay`** (null/integer)
- Current: `null` (uses default)
- Maximum milliseconds to wait for AJAX requests
- Example: `3000` = 3 second max AJAX wait
- Important for dynamic content loaded via API

**`finalDelay`** (null/integer)
- Current: `null` (uses default)
- Delay (ms) before test completes
- Example: `2000` = 2 second delay before comparing
- Allows for animations/transitions to complete

**`globalStepDelay`** (null/integer)
- Current: `null` (uses default)
- Delay (ms) between each test step
- Example: `1000` = 1 second between steps
- Useful for multi-step tests

### Environment Configuration

**`browser`** (null/string)
- Current: `null` (defaults to Chrome)
- Options: `null`, `"chrome"`, `"firefox"`, `"safari"`
- Specify browser for test execution
- Platform must support specified browser

**`viewportSize`** (null/string)
- Current: `null` (platform default)
- Format: `"WIDTHxHEIGHT"` (e.g., `"1920x1080"`)
- Example: `"768x1024"` for mobile
- Test responsive design at specific resolutions

**`region`** (null/string)
- Current: `null` (uses default region)
- Geographic region for test execution
- Options depend on Ghost Inspector platform
- Example: `"us-east"`, `"eu-west"`

**`language`** (null/string)
- Current: `null` (uses default)
- Browser language code (e.g., `"en"`, `"fr"`, `"es"`)
- Affects Accept-Language headers

**`disallowInsecureCertificates`** (null/boolean)
- Current: `null` (uses default)
- Set to `true` to reject invalid SSL certificates
- Set to `false` to allow self-signed certs
- Useful for development/staging environments

### Test Steps

**`steps`** (array)
- Current: 1 step with JavaScript evaluation
- Each step performs a test action
- Steps execute sequentially in order

**Step Object Properties:**
- `command` (string): Action type (`eval`, `click`, `type`, etc.)
- `value` (string): Command details (JavaScript, text, etc.)
- `target` (string): Element selector for action
- `sequence` (integer): Step order (0-based)
- `optional` (boolean): Skip if step fails (`true`/`false`)
- `private` (boolean): Hide from reports (`true`/`false`)
- `condition` (null/string): Conditional execution
- `variableName` (null/string): Store result in variable

**Default Step:**
```json
{
  "command": "eval",
  "value": "document.addEventListener('DOMContentLoaded', function() {window.scrollBy({top: 50});});",
  "sequence": 0,
  "optional": false,
  "private": false,
  "target": "",
  "condition": null,
  "variableName": ""
}
```
This scrolls the page 50px on load to trigger lazy-loaded content.

### Notifications & Headers

**`notifications`** (null/array)
- Current: `null`
- Email/webhook notifications on test failure
- Configure in Ghost Inspector UI

**`httpHeaders`** (array)
- Current: `[]` (empty)
- Custom HTTP headers to send with requests
- Example: `[{"name": "Authorization", "value": "Bearer token123"}]`
- Useful for API testing, authentication

**Example:**
```json
"httpHeaders": [
  {"name": "Authorization", "value": "Bearer token123"},
  {"name": "X-Custom-Header", "value": "custom-value"}
]
```

### Data & Parameterization

**`dataSource`** (null/object)
- Current: `null`
- Data source for parameterized testing
- Run same test with different data sets
- Configure in Ghost Inspector UI

**`maxConcurrentDataRows`** (null/integer)
- Current: `null`
- Limit concurrent execution of data rows
- Example: `5` = run max 5 data sets simultaneously

### Other Settings

**`importOnly`** (boolean)
- Current: `false`
- Set to `true` to import without running
- Useful for review before execution

**`publicStatusEnabled`** (boolean)
- Current: `false`
- Set to `true` to enable public status page
- Shows test results without authentication

**`autoRetry`** (null/boolean)
- Current: `null` (uses platform default)
- Set to `true` to retry failed tests
- Set to `false` to skip retries

**`filters`** (array)
- Current: `[]` (empty)
- Result filters for processing
- Advanced feature, usually empty

**`links`** (array)
- Current: `[]` (empty)
- Related links for documentation
- Displayed in Ghost Inspector UI

## Common Configurations

### Strict Visual Testing
```json
{
  "screenshotCompareEnabled": true,
  "screenshotCompareThreshold": 0.01,
  "failOnJavaScriptError": true,
  "maxWaitDelay": 5000
}
```

### Performance Testing
```json
{
  "screenshotCompareEnabled": false,
  "disableVisuals": true,
  "testFrequency": 1440,
  "maxAjaxDelay": 10000
}
```

### Development/Staging
```json
{
  "disallowInsecureCertificates": false,
  "screenshotCompareThreshold": 0.2,
  "finalDelay": 1000
}
```

### Mobile Testing
```json
{
  "viewportSize": "375x667",
  "screenshotCompareThreshold": 0.15,
  "maxWaitDelay": 8000
}
```

### Multi-Step Test with Headers
```json
{
  "httpHeaders": [
    {"name": "Authorization", "value": "Bearer YOUR_TOKEN"}
  ],
  "steps": [
    {
      "command": "eval",
      "value": "console.log('Test started');",
      "sequence": 0
    },
    {
      "command": "click",
      "target": "button.submit",
      "sequence": 1
    }
  ],
  "globalStepDelay": 500
}
```

## Customizing the Template

### Method 1: Edit Template File
```bash
# Edit templates/template.json directly
nano templates/template.json
```

### Method 2: Paste Custom Template
```bash
# Run script and select option 2 (Paste custom template)
./generate-tests.sh
# Then paste your custom JSON
```

### Method 3: Create Domain-Specific Templates
```bash
# Create templates for different purposes
cp templates/template.json templates/template-strict.json
cp templates/template.json templates/template-mobile.json
# Edit each with appropriate settings
# Use via custom template option (script option 2)
```

## Validation

Template must contain:
- `TEST_NAME` placeholder (replaced with test name)
- `START_URL` placeholder (replaced with URL)
- Valid JSON format

Validation errors will cause script to exit with descriptive message.

## References

- [Ghost Inspector API Documentation](https://api.ghostinspector.com/docs)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
