# Step 3 — Security and data boundaries

## Goal

Design least-privilege enforcement before any runtime implementation.

## Work

1. Threat-model browser, Apex controller, configuration, handler registry, Files, batch jobs, logs, shares, events, generated CSV, and optional integrations.
2. Define object CRUD and field FLS behavior for read, insert, update, upsert, delete, defaults, match keys, returned fields, and error output. Use user-mode operations where supported and explicit checks otherwise.
3. Define record-sharing behavior for internal and external users. Elevated logic requires a custom permission, isolated class, explicit justification, and tests.
4. Allowlist configured objects, fields, operations, and handlers. Reject inaccessible, calculated, autonumber, compound-child, deprecated, or unsupported field types as appropriate.
5. Sanitize dynamic SOQL identifiers through Schema resolution and bind all values. Never concatenate CSV values.
6. Validate extension classes against a registry and required interface; do not execute arbitrary `Type.forName` results.
7. Enforce server-side file signature/extension, UTF-8 policy, byte/row/column/cell limits, CSV formula-injection neutralization, and safe error messages.
8. Define data classification, log redaction, file visibility, retention/deletion, event payload minimization, and notification policy.
9. Define and record the sharing context of every Apex class. Every record-accessing class, including Batch, Queueable, Schedulable, Finalizer, trigger handler, selector, service, and Aura-enabled controller, declares `with sharing`, `inherited sharing`, or `without sharing`. Default to `with sharing`; document why another context is required, what caller context it inherits or bypasses, which Custom Permission authorizes elevated work, and where CRUD/FLS enforcement remains explicit.
10. Treat each asynchronous entry point as a new trust-boundary review. Do not assume the initiating LWC/controller sharing context carries into Batch or Queueable execution.

## Adversarial tests

Restricted CRUD/FLS; inaccessible match key; guest/external user; malicious object/field/handler names; SOQL fragments; spreadsheet formulas beginning `=`, `+`, `-`, or `@`; oversized/malformed/empty/BOM CSV; duplicate headers; Unicode confusables; embedded CR/LF/NUL; zip-bomb-like content; concurrency; deleted config; revoked permissions during a batch; sensitive DML error messages; and manual-share failure.

## Verification and exit gate

This step is a design authorization gate. The implementation lock prevents executable runtime security tests before this gate closes. Approve the threat model, permission/sharing matrices, test cases, and security rule set here; run and pass the executable negative tests and production-source Code Analyzer security scan in Steps 6 and 8 before release. Planned cases are never reported as passed evidence.

- [x] Threat model has owner and mitigations for every trust boundary.
- [x] Permission matrix maps every operation and output field.
- [x] Negative-test specifications cover unauthorized inference of configuration, records, files, logs, and internal errors; executable results are assigned to Steps 6 and 8.
- [x] The production Code Analyzer security rule set and release threshold are approved; executable results are assigned to Steps 6 and 8.
- [x] Security review confirms cache keys/results cannot cross permission boundaries.
- [x] A class-by-class sharing matrix covers every synchronous and asynchronous record-access path, with tests for default and any approved elevated context.
- [x] The four qualities are satisfied through centralized policy, bounded scale, narrow security extension points, and documented decisions.

Evidence: `docs/evidence/03-security/` — security design gate complete; executable negative tests and production-source scans remain mandatory in Steps 6 and 8.
