# ADR-0007 — Configuration over code extension

> [!NOTE]
> On this page, decide how a subscriber extends Bulk Record Upload, so the
> registry consolidation in Step 06 and the field-behavior retirement in
> Step 03 execute a recorded decision rather than improvising one.

- **Status:** Approved on 2026-08-19 for implementation.
- **Owners:** Product, architecture, security, and runtime owners.

## Context

Five classes in the package are named `*Registry`. Two of those names describe
genuinely different things:

- A **closed set of code constants** the package owns and a subscriber selects
  from configuration — for example the built-in DML operations and the V2 field
  merge behaviors (`BlankValueAction__c`, `ExistingValueAction__c`, and the
  related fields on `BulkRecordUploadFieldMergePolicy`, kept per the
  preservation charter in `specs/convergence/00-overview.md`).
- An **open extension point** where a subscriber is meant to supply their own
  Apex implementation, registered and validated rather than trusted as free
  text.

Naming both `Registry` sends a mixed signal: it invites a subscriber to expect
a fork-and-plug model everywhere, when in most of the package the answer to
"how do I change this" is a Custom Metadata record, not an Apex class. `Step 06
— One extension seam` collapses the registries that turned out to encode a
closed set, and keeps exactly one that is a genuine, safely-registered
extension point. This ADR records the decision those steps execute.

## Decision

Flexibility is delivered through configuration a subscriber can change in
metadata, not through code surfaces they must fork. Where a code seam
genuinely earns its place, there is exactly one, and it is registered safely.

## Consequences

- **Closed sets are code constants, not interfaces, and are not named
  `Registry`.** Operations (insert/update/upsert/delete) and field merge
  behaviors are enumerated in code and selected by configuration. A class that
  only maps a fixed, code-owned set of values to behavior is not an extension
  point and must not be named to imply one.
- **Exactly one interface is open to subscriber implementations.** It is
  registered through metadata, validated at resolution time as implementing
  the required interface (never through free-text `Type.forName` on
  administrator or CSV input, per the trusted-identifier rule in ADR-0004 and
  the preservation charter item 5), and gated behind a Custom Permission.
- **The DML path stays closed.** Replacing how the package performs
  create/update/upsert/delete would bypass the user-mode enforcement ADR-0004
  and the preservation charter depend on. This is a deliberate refusal, not an
  oversight: no configuration or registry key may substitute a subscriber's own
  DML implementation for the package's user-mode path.
- **The App Builder property surface stays minimal.** Configuration lives in
  Custom Metadata, not component properties, so there is a single answer to
  "where is this configured?" A `targetConfig` property is justified only when
  the platform requires it at that boundary (for example, binding a host
  page's record context — see `specs/convergence/01-record-page-context-binding.md`),
  never as an alternate configuration channel that competes with metadata.

## The predictability rule

Every future setting is judged against one rule:

> A new setting ships only if an administrator can predict the outcome from
> that field alone, without knowing another field's value or which of two
> fields wins.

`ValueHandling__c` is the worked example that fails this rule. Its outcome
depended on which of two overlapping fields was set and which one the
processor consulted first — an administrator reading either field in isolation
could not predict the resulting behavior. That ambiguity, not simple
duplication, is why `specs/convergence/03-retire-legacy-field-behavior.md`
retires it in favor of the single, unambiguous V2 merge-policy fields the
preservation charter keeps.

## Rejected alternatives

- **A plugin architecture open at every lifecycle point.** Rejected: every
  additional open seam is an unreviewable security surface (a new place a
  subscriber's code runs with the package's trust) and a new concept an
  administrator must learn to answer "how do I configure this." Five
  differently-scoped registries already made the package harder to explain
  than it needed to be.
- **Fully closed, with no extension seam at all.** Rejected: it fails the
  project's stated extensibility goal (see the engineering invariants in
  `AGENTS.md`) and forces a subscriber with a legitimate, unanticipated
  processing need to fork the package rather than configure or extend it
  safely.

## Related

- [Step 03 — Retire the legacy field behavior duplicate](../convergence/03-retire-legacy-field-behavior.md)
- [Step 06 — One extension seam](../convergence/06-single-extension-seam.md)
- [Convergence program overview](../convergence/00-overview.md)
- [ADR-0004 — Security and data-boundary model](ADR-0004-security-model.md)
- [ADR-0006 — Runtime architectural principles](ADR-0006-runtime-principles.md)
