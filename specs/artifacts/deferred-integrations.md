# Deferred integrations

> [!NOTE]
> On this page, keep one reviewed list of integrations and promised features that are excluded from the current core release.

## Status rules

An item remains deferred until Step 2 approves its product contract, security model, package boundary, metadata, tests, documentation, and release target. Deferred items have no active fields, picklist values, permissions, UI controls, events, examples, setup instructions, or runtime branches in the core package.

“Found in reference” records observed material, not a promise to ship it.

## Inventory

| Item                               | Found in reference                                                                                                                  | Current status | Excluded surfaces                                                                                    | Conditions before reconsideration                                                                                                                                     | Decision link                                                                       |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Slack completion notifications     | Config fields, comments, and documentation describe channel and notification choices; runtime integration is marked incomplete      | Deferred       | Core CMT fields/values, UI, Apex, permissions, examples, and setup docs                              | Approved credential model, Slack API/app contract, callout/async design, redaction, retries, subscriber configuration, tests, and optional package boundary           | [ADR-0002](../decisions/ADR-0002-product-contract.md#unsupported-in-core-version-1) |
| Flow processing handler            | Architecture/documentation describes a future handler path without a completed runtime contract                                     | Deferred       | Handler choices, Flow metadata, Apex dispatch, examples, and setup docs                              | Versioned Flow input/output/fault contract, transaction and async model, permission checks, supported limits, tests, and package boundary                             | [ADR-0002](../decisions/ADR-0002-product-contract.md#unsupported-in-core-version-1) |
| Generic platform-event integration | Upload status trigger and broad event/handler appear as an extension placeholder                                                    | Deferred       | Core event metadata, trigger publication, subscriber code, permissions, and integration docs         | Named subscriber use case, minimal versioned event body, publication semantics, duplicate/replay behavior, access model, limits, tests, and optional package boundary | [ADR-0002](../decisions/ADR-0002-product-contract.md#unsupported-in-core-version-1) |
| Slack envelope event               | `ARCHITECTURE.md` and presentation material name `SlackEnvelope__e`, but no matching metadata exists                                | Deferred       | Event metadata, publication code, permissions, examples, and setup docs                              | Approved Slack integration plus a minimal event contract, retention/replay analysis, failure handling, and subscriber ownership                                       | [ADR-0002](../decisions/ADR-0002-product-contract.md#unsupported-in-core-version-1) |
| External webhook subscriber        | Presentation material lists a webhook as a possible generic-event consumer; no callout implementation or credential metadata exists | Deferred       | Named Credentials, External Credentials, Apex/Flow subscriber, permissions, examples, and setup docs | Named destination use case, credential ownership, allowlist, payload/redaction contract, retry/idempotency design, monitoring, tests, and optional package boundary   | [ADR-0002](../decisions/ADR-0002-product-contract.md#unsupported-in-core-version-1) |
| Configurable status colors         | Presentation material identifies hard-coded LWC status colors as future configuration                                               | Deferred       | Core configuration fields, UI controls, styling hooks, examples, and setup docs                      | Accessible SLDS styling contract, bounded values, administrator use case, visual tests, and upgrade behavior                                                          | [ADR-0002](../decisions/ADR-0002-product-contract.md#unsupported-in-core-version-1) |

## Discovery procedure

During Step 1, search Apex, LWC, metadata, tests, scripts, sample data, and documentation for `TODO`, `FIXME`, “future,” “pending,” “not implemented,” integration/vendor names, callouts, Named Credentials, Platform Events, Flow, webhooks, and notification settings. Add every incomplete promise even when it appears in only one source.

Reconcile conflicts explicitly. A field or UI control does not make an integration supported, and a passing placeholder test does not prove an end-to-end integration.

## Promotion procedure

1. Create and approve a Step 2 product decision.
2. Update the behavior parity matrix and research-to-production map.
3. Define the security, package, metadata, runtime, failure, retry, monitoring, test, documentation, upgrade, and uninstall contracts.
4. Move the item from this table only when the program overview schedules its implementation and verification.

## Related

- [Step 1 — Baseline, provenance, and inventory](../01-baseline-and-ip-gate.md)
- [Step 2 — Product contract and packaging](../02-product-contract-and-packaging.md)
- [Step 5 — Core metadata and permissions](../05-core-metadata-and-permissions.md)
- [Step 9 — CI, documentation, and community readiness](../09-ci-documentation-and-community.md)
