# Step 8 — Testing and large-org benchmark evidence

Working-tree identity: uncommitted implementation snapshot; baseline commit remains maintainer-gated by Step 1.

## Environment and boundaries

- Local benchmark: Windows x64, Node.js 24.13.1, 250 iterations per projection size.
- Salesforce integration: verified reusable Developer Edition scratch org, API 67.0, active through 2026-09-09.
- Real Schema cross-check: `Contact` and its configured `LastName`/`Email` fields were resolved through `Schema.getGlobalDescribe`, `DescribeSObjectResult.fields.getMap`, and `DescribeFieldResult`. Tests prove exact API names, order, field types, and current-user create/update decisions.
- Synthetic substitute: 800 immutable project-owned descriptors with scalar, date, decimal, Boolean, and reference types; calculated, encrypted, createable, and updateable differences. This proves the projection algorithm and payload bound only. It does not prove that 800 custom fields can be deployed to Developer Edition or that Salesforce has executed an end-to-end upload against such an object.

## Published budgets and results

| Measurement                      |                                                        Budget |                                                                             Observed | Result |
| -------------------------------- | ------------------------------------------------------------: | -----------------------------------------------------------------------------------: | ------ |
| Sparse projection                |                                          128 KiB / 50 ms mean |                                                       5 fields, 844 bytes, 0.0018 ms | Pass   |
| Typical projection               |                                          128 KiB / 50 ms mean |                                                    50 fields, 8,565 bytes, 0.0076 ms | Pass   |
| Supported maximum projection     |                                          128 KiB / 50 ms mean |                                                  100 fields, 17,163 bytes, 0.0077 ms | Pass   |
| Unsupported 200-field projection |                                                   Must reject |                                    `RangeError` locally and domain exception in Apex | Pass   |
| Maximum input staging            |                                        5,000 rows / 25 chunks | 25 ordered chunks, one DML statement, 25 DML rows, zero queries; 488 ms test runtime | Pass   |
| Client preview                   | 10 rendered rows / 20 source columns, under 10 KiB, under 2 s |                          Previously measured at Step 7 with 5,000 rows × 100 columns | Pass   |

Rerun the synthetic measurements with `npm run benchmark:large-schema`. Rerun the Salesforce proof with the `BulkRecordUploadScaleTest` class after verifying the explicit scratch-org alias.

## Cache and concurrency evidence

The production implementation uses only a bounded transaction-static cache (50 serialized compact projections). Optional Platform Cache was deliberately not enabled, so warm Platform Cache, partition outage, and cross-transaction eviction are not applicable runtime paths. Correctness does not depend on an org cache partition.

Tests prove cold and warm transaction results serialize identically, corrupt entries recover as misses, the oldest entry is evicted at 50 entries, contract-version keys invalidate stale values, and permission fingerprints cannot read another entry. Idempotent submission tests prove a repeated key returns the original upload and enqueues only one job. Unique package-owned idempotency storage is the concurrent first-request arbiter; ordered row numbers and chunk sequence preserve result correlation.

## Verification record

- Focused dry run: 2 Apex components, 5/5 scale tests passed; job `0AfG100000L6a1WKAR`.
- Focused deploy: 2 Apex components, 5/5 scale tests passed; job `0AfG100000L6YB0KAN`.
- Package regression: all 14 `BulkRecordUpload*Test` classes, 69/69 tests passed; run `707G1000018UTZE`.
- LWC regression: 8/8 suites and 27/27 tests passed. Jest executed the suites but its coverage reporter instrumented no files and printed 0%; this is a tooling limitation, not claimed coverage evidence.
- Source gates: package boundary, metadata manifest, Apex architecture, ESLint, Prettier, and `git diff --check` passed for 212 Core files.
- Size gate: largest Apex file is 348 lines; `BulkRecordUploadScaleTest` is 160 lines; the common factory remains below 500 lines.
- Neutral Code Analyzer audit: 0 Critical, 0 High, 110 Moderate, and 199 Low findings. The advisory families match the reviewed convention/design exclusions already recorded in the Step 6 evidence; the Step 9 release profile must make those exclusions executable. The new factory methods were corrected with complete ApexDoc after the neutral audit.

An attempted org-wide `RunLocalTests` deployment (job `0AfG100000L6Z2FKAV`) ran 111 tests and failed on eight unrelated `MetadataDependency*` tests because their unmanaged custom fields are absent. It reported no component errors. This shared-org defect is not represented as a product pass; package-scoped tests are the product evidence.

Package install, upgrade, recovery, and uninstall rehearsals remain assigned to the isolated release workflow in Step 10. They are not safe to infer from a source deployment and are not claimed here.

## Four-quality review

- **Easy to maintain:** one rerunnable benchmark script and one focused scale test own the budgets; no production branch exists solely for the harness.
- **Easy to scale:** source descriptors can approach 800 while the shipped projection and client payload remain capped at 100 configured fields; maximum staging remains 25 chunks.
- **Easy to extend:** new descriptor attributes, field types, and permission patterns can be added to the synthetic fixture without changing runtime contracts.
- **Easy to understand:** real-org behavior, synthetic algorithm proof, optional-cache omissions, unrelated-org failures, and package-lifecycle deferrals are separated explicitly.
