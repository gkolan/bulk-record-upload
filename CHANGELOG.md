# Changelog

All notable changes follow Keep a Changelog categories. The project uses semantic versions.

## [Unreleased]

### Added

- Configuration-driven CSV insert, update, upsert, and delete processing.
- Bounded parsing, staging, Queueable orchestration, partial-success results, Files, history, and retention.
- Lightning upload experience, permissions, compact schema projections, tests, and documentation.

No public package version has been promoted.

### Fixed

- Core installation no longer depends on the optional Account demo configuration. Deploy and activate the demo page after its process records using the quick start.
- Git checkouts use LF line endings so Windows local formatting checks match CI.
- Manual Salesforce CI installs its CLI, verifies the authenticated org URL, and validates every project Apex test class.
