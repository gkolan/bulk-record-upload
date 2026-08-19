# Reference project assessment

> [!NOTE]
> On this page, understand which ideas came from the excluded local reference and why that material is not part of the shipped product.

## Scope and status

The active `force-app` is a project-owned implementation. The ignored `research/bulkRecordUpload` directory is a substantial reference implementation (248 files) and is not published. It contains a configuration-driven CSV uploader built with LWC, Apex Batch, Custom Metadata, Salesforce Files, an upload-log object, sharing records, and platform-event extension points.

This assessment is architectural input for the staged specifications. It does not certify the reference code as secure, deployable, licensed, or production ready.

## What the reference project does

An administrator defines an upload process and its field rules in Custom Metadata. An LWC loads that configuration, produces a template, validates a CSV, previews an operation, and submits content to an Apex controller. Apex stores the input as a Salesforce File, creates an audit log, dynamically resolves a batch handler, and runs chunked insert/update/upsert/delete work. The batch applies field behaviors, records partial failures, produces a results CSV, updates status, and can publish a completion event.

The core extension model has three seams: configuration records for ordinary processes, a standard dynamic-SObject batch for no-code use, and a handler interface/abstract base for specialized Apex implementations.

## Strengths worth preserving

- Configuration-driven processes and per-field behavior reduce one-off upload code.
- Standard and custom handlers give administrators a simple path and developers an escape hatch.
- Batch Apex, partial-success DML, row correlation, input/results files, and an audit object form a useful operational model.
- CSV parsing already considers quoting, embedded commas, escaped quotes, line endings, blank rows, and row numbers.
- Internal and Experience Cloud wrappers share form/status concepts and a utility module.
- Metadata fixtures and extensive Apex tests show serious attention to edge cases.
- Status tracking, pagination, archives, sharing groups, preview permissions, defaults, and result-column control make the concept useful in mature orgs.

## Weaknesses and release blockers

### Architecture and maintainability

- `BulkRecordUploadBatchBase.cls` is 2,347 lines and `BulkRecordUploadController.cls` is 776 lines. Several test classes also exceed 500 lines. These violate the project rule and concentrate unrelated responsibilities.
- The 1,690-line `bulkRecordUploadGuide.html` template should not be migrated as a Lightning component. Its instructional content belongs in focused Markdown pages under `docs/`; the application should retain only brief contextual help and links to the relevant page. This reduces component size, avoids shipping documentation as runtime metadata, and makes the guidance searchable, reviewable, and usable before installation.
- The abstract base owns orchestration, DML, behaviors, schema validation, result CSV generation, content storage, and log updates. Inheritance is doing too much; cohesive services and narrow interfaces are needed.
- Comments describe pending Slack/Flow integrations while metadata exposes related options. Shipping inactive promises would confuse users.

### Scale and caching

- Dynamic schema access appears in the controller, standard batch, and batch base. Instance caching helps within one execution, but Batch transactions do not share static state and a stateful object can become expensive to serialize.
- A mature object with ~800 fields makes global describe, full field maps, field label payloads, and `Return_All_Fields` dangerous defaults. The runtime should build a compact projection containing only configured/uploaded/match/result fields.
- Passing parsed rows into a stateful batch can approach heap and serialization limits. Large files need bounded ingestion and durable chunk storage or a clearly enforced size/row ceiling.
- Platform Cache cannot be correctness-critical and may be unavailable or evicted. It should accelerate versioned projections, with transaction cache and deterministic rebuild as the source of truth.

### Security and trust boundaries

- Dynamic SOQL, `Type.forName`, dynamic fields, cross-object operations, Files, manual shares, and Experience Cloud access create a broad attack surface.
- The reference uses some `stripInaccessible`, but open-source readiness requires systematic object/field permission checks for read and every DML operation, explicit sharing, sanitized errors, and negative tests under restricted users.
- Administrator-editable handler names require a trusted allowlist/registry and interface verification. Configuration alone must not grant arbitrary code execution.
- CSV formula injection must be neutralized when generating downloadable CSV files. File type, encoding, byte size, row count, column count, and cell size need server-side limits.
- Upload contents and DML errors may contain sensitive data; logs, events, and notifications need redaction rules.

### Portability and product completeness

- The active source tree is empty; reference metadata must be deliberately migrated, renamed where needed, and validated as a complete manifest.
- Packaging strategy, namespace behavior, upgrade semantics, licenses, contribution/security policies, CI, release notes, and dependency attribution are missing from the active project.
- Test-only and example Custom Metadata are mixed with runtime content. Package boundaries should separate core, examples, and integration fixtures.
- Custom Metadata list-view deployment behavior must be tested against the chosen packaging/deployment path rather than assumed.
- Documentation is extensive but tied to the reference layout and contains stale or conflicting operational guidance.

## Target architecture

Use a thin LWC/Apex boundary and cohesive services: access/configuration service; compact schema-projection service; streaming/bounded CSV parser; upload validator; handler registry; operation strategies; persistence gateway; job orchestrator; result writer; log service; and optional notification subscribers. Prefer composition over a monolithic abstract base.

Cache keys should include namespace/package version, configuration DeveloperName, target object qualified API name, permission/access fingerprint where output differs by user, and a configuration version/hash. Cache only a compact immutable projection. Use transaction-static caching first, optional Org Cache second, and LWC cache for safe configuration DTOs. Never cache record data or authorization decisions beyond their valid scope.

### Documentation architecture

Replace the reference guide component with a reader-focused Markdown documentation tree. Use `docs/README.md` as the landing page and organize public pages by the task a reader is doing rather than by the old component sections:

- `docs/get-started/` for prerequisites, installation, permissions, first configuration, and first verified upload.
- `docs/admin/` for upload-process configuration, field behaviors, access, limits, operations, and troubleshooting.
- `docs/user/` for preparing CSV files, previewing an upload, monitoring progress, interpreting results, and recovering from failures.
- `docs/developer/` for architecture, Apex extension contracts, custom handlers, caching, security, testing, and contribution workflows.
- `docs/reference/` for exact metadata fields, statuses, CSV rules, limits, result columns, and compatibility contracts.

Each topic must have one primary page. Pages begin with the required “On this page,” note, put the shortest successful path first, use exact Salesforce labels and API names, and end with useful navigation. Screenshots are supporting material rather than the source of truth. The LWC may link to stable published documentation URLs, but installation and ordinary upload processing must not depend on internet access.

## Four-quality impact

The four required qualities materially change the specifications:

- **Easy to maintain:** forces responsibility splits, 500-line gates, shared fixtures, generated inventories, and release automation.
- **Easy to scale:** adds compact projections, bounded CSV/file limits, cache instrumentation, large-schema benchmarks, and async/heap limits.
- **Easy to extend:** replaces broad inheritance and raw handler names with stable contracts, registries, strategies, versioned DTOs, and optional event subscribers.
- **Easy to understand:** adds terminology, architecture decisions, end-to-end examples, explicit package boundaries, small files, and step-by-step verification evidence.

These are not cosmetic additions; they update every implementation step and are explicit exit criteria in the specification set.
