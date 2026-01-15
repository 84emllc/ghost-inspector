# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-15

### Added
- Dependency checks for `jq` and `curl` with installation instructions
- Comprehensive URL validation (format, duplicates, whitespace trimming)
- Duplicate filename detection to prevent output collisions
- File overwrite warnings with `[OVERWRITE]` indicator
- Custom template JSON validation
- Template placeholder verification (`TEST_NAME`, `START_URL`)
- Domain-based output organization in `build/<domain>/` subdirectories
- Automatic `_notes.txt` generation per domain with:
  - Last run timestamp
  - Template used
  - Test files table
  - All template settings (screenshot compare, thresholds, browser, viewport, etc.)
  - HTTP headers configuration
  - Test steps with commands
- `templates/` directory for organized template storage
- Updated README with validation examples and new features
- Updated documentation with output structure and validation details

### Changed
- Reorganized output: tests now organized by domain in `build/` subdirectories
- Moved `template.json` to `templates/template.json`
- Enhanced user feedback with validation warnings instead of silent failures
- Improved confirmation display with overwrite indicators
- Updated script flow to include validation and notes generation phases

### Fixed
- Script now properly handles URLs with leading/trailing whitespace
- Duplicate URLs are now detected and skipped
- Filename collisions from different URLs are now prevented

## [0.3.0] - 2026-01-10

### Added
- Initial documentation in README.md
- Configuration reference guide

## [0.2.0] - 2025-12-10

### Added
- Suite selection feature to choose Ghost Inspector suite from available options
- Custom template support (paste JSON directly)
- Human-readable test names derived from URL paths
- API key hidden input with `-s` flag

## [0.1.0] - 2025-12-10

### Added
- Initial project structure
- Basic URL to filename conversion
- Template placeholder replacement (`TEST_NAME`, `START_URL`)
- JSON file generation from template
- Optional Ghost Inspector API import

[1.0.0]: https://github.com/example/ghost-inspector/releases/tag/v1.0.0
[0.3.0]: https://github.com/example/ghost-inspector/releases/tag/v0.3.0
[0.2.0]: https://github.com/example/ghost-inspector/releases/tag/v0.2.0
[0.1.0]: https://github.com/example/ghost-inspector/releases/tag/v0.1.0
