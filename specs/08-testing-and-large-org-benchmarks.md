# Step 8 — Test system and mature-org benchmarks

## Goal

Prove correctness and bounded resource use under realistic subscriber complexity.

## Test layers

- Pure parser/coercion/behavior unit tests.
- Apex service, security, cache, async, Files, logging, and operation tests using the common factory.
- LWC Jest interaction/accessibility/error tests.
- Manifest deploy and permission assignment integration tests.
- End-to-end uploads for insert/update/upsert/delete, partial failure, retry, and results download.
- Package install/upgrade/uninstall tests.

## Large-org matrix

Generate or install fixtures for objects with near 800 fields while respecting org limits: varied field types, formulas, encrypted fields, lookups, compound fields, inaccessible fields, validation rules, flows/triggers, sharing, duplicate rules, restricted picklists, multi-currency, translated labels, and high record volume. Test sparse configs (5 fields), typical (50), large (200), and near-supported maximum.

A Developer Edition or scratch-org edition may not permit a real object with roughly 800 custom fields. Step 2 must state the supported edition/field limits, and this step must separate platform integration proof from scale-algorithm proof. Use the largest legal real-object fixture available for end-to-end tests, then use a documented synthetic schema-projection substitute for near-800-field cache, filtering, serialization, and client-payload tests. The substitute must implement the same project-owned projection boundary, include realistic describe attributes and access differences, and be cross-checked against real Schema behavior. Never claim that a synthetic test proves Metadata API deployment limits or real-org end-to-end behavior.

Benchmark cold cache, warm transaction cache, warm Platform Cache, forced eviction, stale-version invalidation, unavailable cache partition, concurrent first requests, and multiple permission fingerprints. Capture server CPU/heap/SOQL/DML/describe behavior, serialized DTO/cache bytes, client payload/render time, job latency, throughput, and error/result file size.

## Verification and exit gate

- [x] Published budgets have measured pass/fail evidence and environment details.
- [x] 800-field objects do not cause all-field queries or payloads.
- [x] Evidence states which measurements use a real Salesforce object and which use the synthetic projection substitute, including the real edition limit and cross-check method.
- [x] Cache-off results equal cache-on results; no permission leakage occurs.
- [x] Maximum supported input completes within governor and product limits.
- [x] Repeated/concurrent requests are idempotent and row results remain ordered/correlated.
- [x] Every defect fixed has a regression test; mutation/negative testing covers critical validators.
- [x] Test files and factory comply with 500-line rule.
- [x] Results explain maintenance cost, scaling headroom, extension coverage, and how a contributor reruns them.

Evidence: `docs/evidence/08-large-org-benchmarks/` — complete. Optional Platform Cache is not enabled, so its partition-specific matrix is documented as not applicable. Isolated package lifecycle rehearsals remain a Step 10 release gate.
