# Step 6 — Apex implementation

## Goal

Implement secure, bulkified services from the approved architecture.

## Rules

Use `platform-apex-generate` and required companion test skill for every class change. Every record-accessing class declares a sharing keyword; this includes every asynchronous and batch entry point. Default to `with sharing`. `inherited sharing` or `without sharing` requires the Step 3 class-by-class decision, a narrow responsibility, documented caller behavior, explicit CRUD/FLS handling, required Custom Permission for elevation, and positive/negative tests. Use compact projections, keep SOQL/DML outside loops, use partial-success DML, clean sensitive details from errors, and remain under 500 physical lines. Split at 450 lines.

All reusable data is created by `BulkRecordUploadTestDataFactory`. Keep the factory under 500 lines by exposing focused builders backed by small fixture-provider classes if needed; there is still one public factory entry point.

## Work slices

1. Value objects/contracts and domain exceptions.
2. Configuration repository, access policy, and projection cache.
3. Bounded parser and structural validator.
4. Handler registry and operation strategies.
5. Mapping/coercion/field behaviors as independent strategies.
6. Persistence gateway and row-result correlation.
7. Staging, queue/batch orchestration, finalization, cleanup, and idempotency.
8. Results CSV/file writer, upload log service, and minimal events.
9. Thin Aura-enabled controller with versioned DTOs.

Each slice receives its own focused tests before the next begins.

## Verification and exit gate

- [x] No production or test Apex file exceeds 500 lines; no method exceeds the project complexity budget.
- [x] Factory-usage check rejects reusable test-data DML outside `BulkRecordUploadTestDataFactory`.
- [x] CRUD/FLS/sharing, injection, bulk, concurrency, retry, partial failure, and cache eviction tests pass.
- [x] An automated architecture check rejects a record-accessing Apex class without an explicit sharing declaration, including Batch and Queueable classes.
- [x] Apex tests pass in the one scratch org with required per-class and aggregate coverage.
- [x] Code Analyzer, formatting, architecture, and documentation checks are clean.
- [x] Governor-limit assertions show bounded queries, DML, CPU, heap, async jobs, and describes.
- [x] One custom handler and one field behavior prove extension without core modification.
- [x] Public methods/classes have useful ApexDoc and trace to one documented responsibility.

Evidence: `docs/evidence/06-apex/README.md`
