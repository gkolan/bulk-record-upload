# Step 4 — Architecture and cache design

## Goal

Replace monoliths with small, measurable components that remain nimble on objects with roughly 800 fields.

## Components

Define narrow contracts for configuration repository, access policy, schema projection, CSV reader/validator, upload request service, handler registry, operation strategies, record mapper, persistence gateway, job orchestrator, result writer, upload log, and event/notification publishers. Controllers route only. Avoid a base class that owns unrelated behavior.

## Compact projection

For one process, construct an immutable projection containing only configured active fields, received CSV fields, match/upsert key, required fields, fields needed by a selected behavior, and minimal result identifiers. Never return or query all ~800 fields by default. `Return_All_Fields` means all configured safe fields, not every field on the object.

Normalize API names once, retain canonical qualified names, precompute type/coercion/permission/behavior data, and reject duplicates. Bound projection size and fail with an administrator-actionable error when exceeded.

## Cache hierarchy

1. Request/LWC memoization for immutable client models; do not cache authorization-sensitive data under a shared key.
2. Transaction-static Apex maps to prevent repeated CMT and describe resolution.
3. Optional Org Platform Cache for serialized compact projections only. Treat it as an optimization; always rebuild on miss/eviction/unavailable partition.
4. No record-data cache and no unbounded cache of arbitrary object describes.

Key by namespace/package contract version, config DeveloperName, config hash/version, qualified object API name, operation, field-set hash, locale when labels are included, and access fingerprint when output is user-specific. Specify TTL, maximum entry bytes/count, invalidation on config/package change, stampede control, metrics, and graceful fallback.

## Async and file design

Do not serialize an entire large CSV through `Database.Stateful`. Specify bounded chunks and durable staging with cleanup, idempotency keys, retry semantics, and row-order correlation. Measure heap/CPU/query/DML per chunk and adapt documented batch-size guidance without hiding platform limits.

## Verification and exit gate

This step authorizes implementation architecture. Synthetic schema, cache-off/eviction, load, and extension tests require the classes designed here and run in Steps 6 and 8. This gate approves their measurable fixtures and pass conditions without reporting planned results as passed.

- [x] Architecture and sequence diagrams cover happy, partial-failure, fatal, retry, and cancellation paths.
- [x] Every Apex class is projected under 450 lines and has one responsibility.
- [x] Cache contract documents key, value, TTL, bounds, invalidation, miss, eviction, permission isolation, and metrics.
- [x] A synthetic 800-field schema test is specified to prove only configured fields are described/serialized/queried; executable proof is assigned to Step 8.
- [x] Cache-off and forced-eviction equivalence tests are specified; executable proof is assigned to Steps 6 and 8.
- [x] The load model defines bounded heap and durable row correlation at maximum supported input; executable proof is assigned to Step 8.
- [x] An extension test is specified to add one behavior/handler without changing controller, parser, or unrelated strategies; executable proof is assigned to Steps 6 and 8.
- [x] A newcomer can trace the request using canonical docs and class names.

Evidence: `docs/evidence/04-architecture-and-cache/` — architecture design gate complete; executable scale, cache, and extension proofs remain mandatory in Steps 6 and 8.
