# Step 10 — Release validation evidence

## Candidate identity and status

The candidate is an uncommitted working-tree snapshot. The repository has no release commit or tag, so artifact signing and exact-commit attestation cannot occur. Step 10 remains open.

## Completed gates

- Release-isolation replacement scratch org `sfdo827` is now the sole active project scratch org; superseded `sfdo826` was retired. Core deployment `0AfAw00000PDr4wKAD` succeeded with 186 components and zero errors.
- The deterministic demo seed created three synthetic Accounts, and optional demo configuration deployment `0AfAw00000PDslmKAD` added the `Account_Insert_Demo` process with Name and Description columns. Reusable seed and CSV assets live under `scripts/apex/` and `docs/examples/`.
- The demo kit was expanded to 12 active processes: Insert, Update, Upsert, and Delete for Account, Contact, and Opportunity. Deployment `0AfAw00000PDwW1KAL` installed 67 demo components with zero errors; permission deployment `0AfAw00000PDwqzKAD` added the isolated target-access role. The seed creates three records per object, 12 matching CSVs are published, and the production projection service successfully resolved all 12 processes with their expected field counts.
- Coverage campaign run `707Aw00001QuaQy` passed 80 of 80 tests and increased tested-package coverage from 89% to 92%. The focused edge suite passed 7 of 7 and reports 99% for its exercised classes. The requested package-wide greater-than-99% target is not yet met and remains an explicit release blocker; no coverage value is rounded up or blended with org-wide coverage.
- Final coverage-campaign Code Analyzer output reports zero violations in `code-analyzer-results-20260812-coverage-campaign.json`.

- Reused scratch org `sfdo826` was verified active, Developer Edition, API 67.0, and expiring 2026-09-09. No replacement org was created.
- Full Core source, including list views, was previously deployed to that scratch org. The Step 8 addition deployed successfully under job `0AfG100000L6YB0KAN`.
- All 14 package test classes passed: 69/69 tests, run `707G1000018UTZE`. Tests cover insert/update/upsert/delete, partial failure, idempotency, row correlation, Files/results, history, retention, permissions, extension registries, cache, and 5,000-row staging.
- Local candidate checks passed: ESLint, Prettier, 8 Jest suites/27 tests, 212-file package/metadata/Apex checks, 53-file documentation check, release-boundary scan, 800-descriptor benchmark, zero production dependency vulnerabilities, and CycloneDX SBOM creation.
- Final checked-in Code Analyzer release profile found zero violations after all tests.
- Every Apex and Apex test class is below 500 lines; the largest is 348 lines and reusable records remain in `BulkRecordUploadTestDataFactory`.
- The approved persistent org was resolved to `https://sfdo-gk-dev-ed.develop.my.salesforce.com` before every operation. Validation-only job `0AfgK00000QBoVZSA1` compiled all 185 components with zero component errors and no metadata commit.
- The near-800-field limits and measurements are published in `docs/evidence/08-large-org-benchmarks/README.md`.
- The final npm dry-run archive contains 268 files (354,337 unpacked bytes) and excludes research, local standards, specifications, implementation evidence, generated reports, auth state, coverage, local agent/editor files, and starter scripts. The shipped Salesforce boundary remains `force-app/`.

### Configured-process component clarification

The existing multi-process `bulkRecordUpload` upload center was preserved. A separate `bulkRecordUploadConfigured` App Builder component now binds one administrator-selected process API name to the shared upload workflow. The server validates the fixed key through the compact projection service and scopes history to that process; the key never grants permission or bypasses CRUD, FLS, sharing, operation, preview, delete, handler-registry, or active-configuration checks.

Local verification passed with 9 Jest suites/29 tests and 216 Core source files. The final focused Code Analyzer scan reported zero violations. Scratch validation job `0AfG100000L6bLmKAJ` compiled six components and passed all 73 package tests with no coverage warnings. Quick deployment job `0AfG100000L6cHpKAJ` promoted that exact validated payload to the verified reusable scratch org; no persistent org was changed.

The first approved-org test validation used obsolete comma-separated test syntax and ran zero tests. The corrected run compiled all components and ran 69 tests; 66 passed, while three tests could not query fields introduced in the same check-only transaction. Those exact tests pass after dependencies exist in the scratch org. Persistent validation therefore remains metadata-only, while scratch evidence owns runtime execution.

## Runtime-principles verification — 2026-08-12

- **Requirement:** ADR-0006 hard limits, stable values, user-mode business-data boundary, and visible failure contracts.
- **Working-tree identity:** Uncommitted working-tree snapshot.
- **Timestamp:** 2026-08-12T23:08:03-05:00.
- **Actor/tool:** Local Node, Jest, Prettier, Salesforce Code Analyzer CLI, and Salesforce CLI.
- **Command or procedure:** `npm run check:apex`; `npm run check:docs`; `npm run check:all`; `sf code-analyzer --help`; `sf org display --target-org sfdo827 --json`.
- **Target:** Local for completed checks; scratch alias `sfdo827` requested but not accepted as verified because the CLI failed before returning org details.
- **Expected result:** Runtime/metadata status parity, code-owned ceilings, no system-mode target-record query owner, documentation parity, passing unit tests, clean analyzer, verified scratch target, compiled Apex, and passing focused Apex tests.
- **Observed result:** Local Apex architecture and 54-file documentation gates passed; formatting passed; 9 Jest suites and 33 tests passed. The aggregate local gate stopped on the existing deferred `Account_Record_Page.flexipage-meta.xml` Core-surface finding. Code Analyzer and scratch verification were unavailable because the installed Salesforce CLI terminated during startup with Node `uv_os_get_passwd` `ENOMEM`; no org-affecting command ran.
- **Artifact:** `BulkRecordUploadRuntimeContract`, `scripts/check-apex.mjs`, ADR-0006, and this reviewed summary. No raw CLI response is retained.
- **Reviewer:** Maintainer review pending.
- **Limitations/follow-up:** Restore Salesforce CLI startup, verify `sfdo827` and its instance URL, run a focused Code Analyzer scan, validate deployment, and execute `BulkRecordUploadContractsTest` before release. Resolve or formally defer the existing Account record-page boundary finding separately.

## Open release blockers

1. **Dev Hub and package lifecycle:** The only authorized persistent org is not Dev Hub-enabled. `sf package list` fails because `Package2` is unavailable. The in-app browser has no authenticated session for that org, and no access token was placed in a browser URL. No 2GP package, package version, install, upgrade, recovery, or uninstall evidence exists.
2. **Release identity:** No commit exists for this working tree. A maintainer must review and create the exact release commit before clean-clone, signing, tagging, and provenance attestation.
3. **Interactive review:** The project owner deferred keyboard, screen-reader, contrast/zoom, mobile, Experience Cloud, and screenshot accessibility review to Step 10. The authenticated scratch page could not be claimed by browser automation, so the checklist remains open.
4. **Dependency legal review:** Two transitive Jest tools contain Salesforce non-OSS public-code terms. They are not redistributed as installed code, but the maintainer/legal review recorded in Step 9 remains required before public release.
5. **Maintainer sign-off:** The four-quality evidence exists across Steps 1–9, but a maintainer has not signed the release candidate.

Because this is the first release line, upgrade from the oldest supported promoted version is not applicable yet. Fresh package installation and uninstall/reinstall are still mandatory once Dev Hub is enabled; rollback evidence must use a separately created corrective version after an immutable initial package version exists.

## Release notes classification

- **Supported candidate:** version 1 insert, update, upsert, delete, bounded UTF-8 CSV processing, compact projections, Lightning Experience UI, Files/results, history, retention, and registered handler/behavior extensions.
- **Experimental:** none.
- **Deprecated:** none.
- **Planned or unsupported:** only the items listed in `docs/reference/unsupported-features.md`; no target release is promised.

## Four-quality review awaiting signature

- **Easy to maintain:** thin ownership layers, explicit manifests, one check command, and focused evidence.
- **Easy to scale:** 5,000-row/100-field hard limits and near-800-field source-schema projection proof.
- **Easy to extend:** versioned contracts and trusted handler/behavior/operation registries with tests.
- **Easy to understand:** public role-based documentation, stable contracts, and explicit release blockers.
