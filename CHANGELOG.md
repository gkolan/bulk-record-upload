# Changelog

All notable changes follow Keep a Changelog categories. The project uses semantic versions.

## [Unreleased]

### Added

- Configuration-driven CSV insert, update, upsert, and delete processing.
- Bounded parsing, staging, Batch Apex orchestration, partial-success results, Files, history, and retention.
- Lightning upload experience, permissions, compact schema projections, tests, and documentation.

No public package version has been promoted.

### Fixed

- Core installation no longer depends on the optional Account demo configuration. Deploy and activate the demo page after its process records using the quick start.
- Git checkouts use LF line endings so Windows local formatting checks match CI.
- Manual Salesforce CI installs its CLI, verifies the authenticated org URL, and validates every project Apex test class.
- The demo generator preserves hand-authored bundle and extension records instead of deleting the entire Custom Metadata directory.
- The npm source archive uses an explicit allowlist and rejects local evidence, dependency copies, oversized output, and planning records.
- Git, npm, Salesforce source, and automated release checks exclude local research, specifications, bug records, internal notes, evidence, reports, agent state, temporary files, and review artifacts.
- Git, npm, Salesforce source, and automated release checks exclude local specifications, bug and research notes, internal documentation, generated reports, review artifacts, temporary files, and agent state.
- Least-privilege security tests now use a non-admin Salesforce profile and prove cross-user upload and File privacy, permission revocation, and identifier-injection rejection.
- The demo reset removes bounded Contact and Opportunity Insert fixture families before restoring the deterministic baseline.

### Changed

- Removed unused configurable processor and custom merge-class surfaces. Persistence and field merging are package-owned; `BulkRecordUploadExtension` is the single subscriber Apex seam.
- Removed the obsolete process configuration version selector. Day-1 processes use one current configuration shape with no legacy branch.
- Added idempotent install and maintenance-stop scripts for daily retention and stale-claim recovery without blocking later Apex deployment.
- Added generated-demo parity and complete per-example outcome, repeat-run, recovery, and cleanup checks to the standard repository gates.
