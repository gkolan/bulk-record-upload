# Step 6 — Apex implementation evidence

Working-tree identity: uncommitted implementation snapshot; baseline commit remains maintainer-gated by Step 1.

## Local architecture and packaging gate

- **Requirement:** Explicit manifest coverage, package-boundary isolation, Apex sharing declarations, the 500-line ceiling, and common test-factory enforcement.
- **Timestamp:** 2026-08-12T03:27:00-05:00.
- **Actor/tool:** npm scripts and repository-owned architecture checks.
- **Command:** `npm run check:source`.
- **Target:** local.
- **Expected result:** all package, metadata, and Apex architecture checks pass.
- **Observed result:** Passed for 166 Core source files. The largest Apex file was 348 physical lines; no file reached the 450-line warning threshold. Record-accessing classes, including Queueable and Schedulable entry points, declared sharing explicitly. Reusable test-record DML remained in `BulkRecordUploadTestDataFactory`.
- **Artifact:** `scripts/check-package-boundary.mjs`, `scripts/check-metadata.mjs`, and `scripts/check-apex.mjs`.
- **Reviewer:** implementation owner; maintainer review pending.

## Scratch deployment and Apex suite

- **Requirement:** Complete Core source deploys and focused Apex tests pass with per-class coverage.
- **Timestamp:** 2026-08-12T03:27:54-05:00.
- **Actor/tool:** Salesforce CLI against the reused authorized scratch org.
- **Command:** `sf project deploy start --source-dir force-app/main/default --target-org <authorized-scratch-alias> --test-level RunSpecifiedTests` with all 13 `BulkRecordUpload*Test` classes named explicitly.
- **Target:** scratch; active 30-day project scratch org, verified immediately before deployment.
- **Expected result:** every component and test succeeds without coverage warnings.
- **Observed result:** Passed. 111 of 111 components deployed; 62 of 62 tests passed; zero test failures and zero coverage warnings.
- **Artifact:** ignored Salesforce deployment response; sanitized counts recorded here.
- **Reviewer:** implementation owner; maintainer review pending.
- **Limitations:** `RunLocalTests` is not usable as project evidence in this shared scratch org because unrelated unmanaged packages contain tests whose metadata dependencies are absent. The project suite is therefore explicit and manifest-scoped.

## Security and runtime behavior covered

Focused tests cover compact configuration projection and cache eviction, restricted permissions, malicious registry keys, bounded/malformed CSV, configured headers, typed coercion, registered handlers and field behaviors, one-query record resolution, all four partial user-mode DML operations, row correlation, bounded staging and checksums, idempotency and concurrency, monotonic lifecycle transitions, Queueable chaining, safe result CSV and Files, terminal cleanup, and retention behavior when a File has an unrelated link.

The result contract begins with `bru_row_number`, `bru_status`, `bru_record_id`, `bru_error_code`, and `bru_error_message`; configured result fields follow in projection order. Formula-triggering cells are neutralized.

## Code Analyzer gate

- **Requirement:** Run Salesforce Code Analyzer and eliminate release-blocking findings.
- **Timestamp:** 2026-08-12T03:29:48-05:00.
- **Actor/tool:** Salesforce Code Analyzer Recommended rules with the installed `dx-code-analyzer-run` workflow.
- **Command:** `sf code-analyzer run --rule-selector Recommended --target force-app/main/default --output-file <timestamped-json> --include-fixes`, followed by the skill-owned `parse-results.js`.
- **Target:** local Core source.
- **Expected result:** zero Critical and High findings.
- **Observed result:** Passed for release-blocking severities: 0 Critical and 0 High. The initial three High findings were manually remediated and the verification scan reported 309 reviewed Moderate/Low style and design findings, primarily ApexDoc coverage, test naming/runAs conventions, and intentional immutable-contract parameter lists.
- **Artifact:** ignored `code-analyzer-results-20260812-032936.json` and matching log.
- **Follow-up:** All 11 missing-brace source locations identified by the neutral audit were corrected. The reported complexity values remain within the reviewed project budget of 15 and are advisory under `development-standards/code-analysis-standard.md`; each affected method has one responsibility and focused tests. Intentional convention findings remain visible in the neutral audit and require the checked-in release profile in Step 9 rather than silent inline suppression.

The post-correction Apex-only neutral audit completed through a process-local CLI shell-detection workaround. It reported 296 advisory design/convention findings: 0 Critical, 0 High, 104 Moderate, and 192 Low. Missing-brace, high-cost-in-loop, and Queueable recovery findings were either corrected or narrowly documented; the remaining families match the reviewed neutral-audit exclusions in `development-standards/code-analysis-standard.md`.

The blocking Step 3 release threshold—Recommended plus all severity 1–2 Security rules with zero unresolved findings—passed with 0 Critical and 0 High findings. The neutral report remains under ignored `code-analyzer/step6-apex-neutral.json` and is not represented as a zero-finding scan.

## Four-quality review

- **Easy to maintain:** controllers route only; parsing, configuration, mapping, DML, Files, logs, staging, jobs, and retention have separate owners and focused tests.
- **Easy to scale:** 2 MB/5,000-row/100-column limits, at most 200 rows per DML chunk, at most 25 durable chunks, compact projections, bounded caches, and one-query match resolution are enforced.
- **Easy to extend:** explicit registries prove one custom handler and four independent field behaviors without dynamic class execution or changes to parser/persistence contracts.
- **Easy to understand:** versioned DTOs, stable status/error/result contracts, ApexDoc on public boundaries, safe evidence, and explicit manifest membership make runtime ownership traceable.

## Current gate status

The production implementation and scratch suite are complete. The final full-source deployment succeeded in the verified reusable scratch org: 121 components, 64 project Apex tests, zero component/test failures, and zero coverage warnings (job `0AfG100000L6StbKAF`). Local formatting, LWC, package-boundary, metadata, and Apex architecture checks pass. Step 6 is closed.
