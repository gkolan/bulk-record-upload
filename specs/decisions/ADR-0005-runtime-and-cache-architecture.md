# ADR-0005 — Runtime, staging, and cache architecture

> [!NOTE]
> On this page, define the small runtime components, bounded staging model, projection cache, and measurable extension contracts for Bulk Record Upload.

- **Status:** Approved on 2026-08-12 for implementation.
- **Owners:** Architecture, runtime, scale, security, and test owners.

## Component map

| Component                            | One responsibility                                                    | Projected maximum lines |
| ------------------------------------ | --------------------------------------------------------------------- | ----------------------: |
| `BulkRecordUploadController`         | Route Aura-enabled requests to services and translate safe outcomes   |                     180 |
| `BulkRecordUploadRequestService`     | Validate submission contract and coordinate log, staging, and enqueue |                     350 |
| `BulkRecordUploadConfigRepository`   | Load immutable configuration records                                  |                     250 |
| `BulkRecordUploadAccessPolicy`       | Centralize Custom Permission, CRUD, FLS, and operation decisions      |                     350 |
| `BulkRecordUploadProjectionService`  | Build the canonical compact schema/configuration projection           |                     400 |
| `BulkRecordUploadCsvReader`          | Parse bounded UTF-8 CSV and preserve physical row numbers             |                     400 |
| `BulkRecordUploadRequestValidator`   | Enforce input, header, projection, and concurrency rules              |                     300 |
| `BulkRecordUploadExtensionRegistry`  | Resolve, validate, and order the package's one open extension seam    |                     100 |
| `BulkRecordUploadExtensionV1`        | Narrow extension interface for projected rows and safe row results    |                      50 |
| operation strategies                 | Map/validate one Insert, Update, Upsert, or Delete operation          |                350 each |
| `BulkRecordUploadPersistenceGateway` | Execute user-mode partial DML and correlate results                   |                     350 |
| `BulkRecordUploadJob`                | Process one durable staged chunk and schedule the next                |                     350 |
| `BulkRecordUploadOrchestrator`       | Enqueue, retry-link, idempotency, and terminal coordination           |                     300 |
| `BulkRecordUploadResultWriter`       | Produce safe versioned result CSV chunks and final File               |                     400 |
| `BulkRecordUploadLogService`         | Own upload lifecycle and access-filtered history                      |                     350 |
| `BulkRecordUploadFileService`        | Own authorized input/default/result Files and cleanup                 |                     350 |
| `BulkRecordUploadRetentionJob`       | Apply bounded retention and ownership-safe cleanup                    |                     300 |

No base class owns parsing, mapping, DML, Files, logs, and orchestration together. Strategies and extensions receive immutable projections and narrow gateways.

_Updated 2026-08-19 by convergence step 06: `BulkRecordUploadHandlerRegistry`/`BulkRecordUploadHandlerV1` and `BulkRecordUploadPostActionRegistry`/`BulkRecordUploadPostActionV1` (two of the original five registry-shaped concepts) are replaced by the single `BulkRecordUploadExtensionRegistry`/`BulkRecordUploadExtensionV1` seam. See [ADR-0007](ADR-0007-configuration-over-code-extension.md) and the [ADR-0004 amendment](ADR-0004-security-model.md) for the decision and its security guardrails._

## Compact projection

`BulkRecordUploadProjectionV1` contains the contract version, process key/hash, canonical qualified object name, operation, ordered configured fields, received header mapping, match/upsert key, required/default/result flags, field type/coercion/behavior descriptors, CRUD/FLS decisions, ordered extension class names, and stable hashes. It contains no records or CSV values.

The builder resolves at most 100 configured fields plus minimal system identifiers. An 800-field object fixture must show that serialized DTOs, SOQL, result headers, and cache values contain only the bounded projection. The service may obtain an object field map to resolve named fields when Salesforce Schema requires it, but it never serializes or returns that full map and records describe/projection counts separately.

## Durable staging and job flow

The request transaction validates and parses the file into bounded staged chunks of at most 200 rows and 512 KiB serialized content. Durable package-owned staging records retain encrypted-at-rest chunk payloads, first physical row number, checksum, sequence, and upload link. The request never passes all rows into `Database.Stateful`.

One Queueable processes one chunk, revalidates access/configuration, performs partial user-mode DML, writes bounded result fragments, marks the chunk, and enqueues the next chunk only through guarded orchestration. Terminal coordination joins fragments in order and creates the final results File. Cleanup removes staging promptly after terminal completion and through a recovery schedule for abandoned jobs.

At 5,000 rows and 200 rows per chunk, one upload creates at most 25 chunks. Each job targets under 6 MiB heap, 50% CPU budget, 20 SOQL queries, 4 DML statements, and 1,000 DML rows. Exceeding a soft budget records a metric and safely reduces future chunk size within the 25-row minimum; it never hides a hard platform failure.

## Cache contract

| Attribute            | Contract                                                                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Key                  | `bru:projection:1:{packageVersion}:{configKey}:{configHash}:{object}:{operation}:{fieldHash}:{locale}:{accessFingerprint}`                |
| Value                | Immutable serialized `BulkRecordUploadProjectionV1`; no records, values, usernames, or raw permissions                                    |
| Transaction cache    | Static bounded map, maximum 50 entries, cleared by transaction end                                                                        |
| Org Cache            | Optional, maximum 200 entries and 128 KiB per value, 900-second TTL                                                                       |
| Miss/unavailable     | Rebuild deterministically from CMT and Schema; correctness never depends on cache                                                         |
| Invalidation         | New config hash, package/contract version, field-set hash, operation, locale, or access fingerprint creates a new key; old entries expire |
| Stampede control     | Per-transaction single build; Org Cache put after successful complete build; no partial values                                            |
| Permission isolation | Access fingerprint hashes relevant object/field decisions and permission-set modification state; sensitive DTOs remain user-scoped        |
| Metrics              | hit/miss/build/fallback/oversize/deserialize-failure counters and build time; no sensitive key material in logs                           |
| Eviction             | Treat as miss; cache-off, eviction, corrupt-value, and unavailable-partition tests must return identical functional results               |

Client memoization stores safe immutable display models keyed by process/hash/locale and never becomes authorization. Record data is never cached.

## Extension contract

A new registered handler or behavior adds an implementation, registry entry, focused tests, and documentation. Controller, CSV reader, projection contract, persistence gateway, and unrelated strategies remain unchanged. Handlers cannot issue unreviewed DML outside the gateway or request fields outside the projection.

## Related

- [Security model](ADR-0004-security-model.md)
- [Product contract](ADR-0002-product-contract.md)
