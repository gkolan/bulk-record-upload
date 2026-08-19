# Convergence program

## Why this program exists

The package has already converged on a good shape: **custom metadata defines a
process; one exposed component renders whatever the running user is authorized
for; Apex projects configuration into a compact cached DTO and runs it in
bounded chunks.** That shape is sound and is not being redesigned.

What this program fixes is the places where something older or half-finished
still contradicts that shape — a duplicated field-behavior configuration, public
API nobody calls, a component named after a distinction that no longer exists,
and five extension registries of which only some are real extension points.

The thesis every step serves:

> **Configuration over code extension.** Flexibility arrives through metadata a
> subscriber can configure, not through code surfaces they must fork. Where a
> code seam genuinely earns its place, there is exactly one, and it is safe.

## Preservation charter — what must not be lost

V1 got a great deal right. Steps in this program are **subtractive and
clarifying**, never a rewrite. The following are load-bearing and must survive
every step unchanged unless a step explicitly and narrowly says otherwise:

1. **One exposed LWC over internal components.** Exactly one component has
   `isExposed=true`; the other ten are internal and composed. This is correct.
2. **Config-to-projection layering.** `*ConfigV1` reads metadata, `*ProjectionV1`
   is the compact cached form, `configHash` versions the cache. This is genuine
   layering, not duplication. Keep all three ideas.
3. **User-mode enforcement.** `with sharing`, `AccessLevel.USER_MODE`, and
   user-mode CRUD/FLS at business-data boundaries. `WITH SYSTEM_MODE` appears
   only where deliberately chosen for internal chunk bookkeeping.
4. **Server-authoritative record context.** The parent is validated server-side
   and stamped after CSV mapping, so a CSV column can never set it.
5. **Trusted-allowlist identifier resolution.** Object, field, and handler
   identifiers resolve through `Schema` describe and reviewed allowlists.
   Administrator free text is never instantiated as a class. Step 06 changes
   _how_ one seam is registered; it does not weaken this rule.
6. **Bounded chunked processing.** One durable chunk per transaction,
   partial-success DML, row-to-result correlation preserved.
7. **The job as the single readable lifecycle.** `BulkRecordUploadJob` is the one
   place the end-to-end execution order is visible. Keep it that way.
8. **`BulkRecordUploadTestDataFactory` as the single reusable test data source.**
9. **The 500-line hard ceiling and 450-line warning threshold.**
10. **Compact projections for large objects.** Never describe, serialize, or
    return every field. The 800-field constraint governs.
11. **No CSV contents, secrets, or sensitive field values in logs.**
12. **The V2 field merge policy** — `BlankValueAction__c`,
    `ExistingValueAction__c`, `TextSeparator__c`, `DuplicateTextAction__c`,
    `OverflowAction__c` and `BulkRecordUploadFieldMergePolicy`. Step 03 removes
    the _older duplicate_ of this concept. The V2 policy itself is the keeper.
13. **Retention job, chunk durability, and result writer.**
14. **Localization-safe text through the labels component.**

If a step appears to require breaking one of these, stop and report rather than
proceeding. The charter outranks the step.

## Steps

| #   | Step                                                                             | Depends on | Behavior change?             |
| --- | -------------------------------------------------------------------------------- | ---------- | ---------------------------- |
| 01  | [Record page context binding](01-record-page-context-binding.md)                 | none       | Yes — fixes a broken feature |
| 02  | [Decision record: configuration over extension](02-decision-record.md)           | none       | No — documentation           |
| 03  | [Retire the legacy field behavior duplicate](03-retire-legacy-field-behavior.md) | 02         | No                           |
| 04  | [Remove dead public surface](04-remove-dead-public-surface.md)                   | none       | Public API only              |
| 05  | [Rename the exposed component](05-rename-exposed-component.md)                   | 04         | Public API only              |
| 06  | [One extension seam](06-single-extension-seam.md)                                | 02, 03     | Public API only              |
| 07  | [Record context sources](07-record-context-sources.md)                           | 01, 03, 06 | Yes — new feature            |

Step 01 is a release blocker and is independent of everything else. Start there
regardless of how the rest is scheduled.

Steps 04, 05, and 06 change public API surface. They are cheap now and expensive
after distribution. Do them before packaging locks the names.

## Working rules

These apply to every step and are not repeated in the step files.

1. **One step per branch.** Do not begin step N+1 until step N's exit gate is
   satisfied with recorded evidence.
2. **Prove before deleting.** Every deletion is preceded by a reference check
   whose output is recorded in the step evidence. If any non-test production
   reference exists, stop and report instead of deleting. One "dead" registry in
   this package turned out to be live in the job; assume nothing.
3. **Steps 04 to 06 change no runtime behavior**, and step 03 changes it in
   exactly one declared place. Existing tests must pass unchanged except where
   they referenced a deleted symbol. A test that needs its _assertions_ rewritten
   is a signal you changed behavior — stop and report unless that step names the
   change.
4. **Follow `AGENTS.md`.** Load the applicable Salesforce skill before any
   org-affecting action, read the relevant `development-standards/` files, use an
   explicit `--target-org`, and keep to the single authorized persistent org and
   at most one reusable scratch org.
5. **Never deploy `research/` or `development-standards/` content.**
6. **Record evidence** under `docs/evidence/convergence/<step>/` following
   `docs/evidence/README.md`. Record the command, target org, result, and
   artifact path. Never claim a deploy or test passed without captured output.
7. **Every step must address all four invariants** — maintainable, scalable,
   extensible, understandable — in its evidence, per `AGENTS.md`.

## Definition of done

There is one way to configure field behavior, one exposed component with a name
that matches the product, one extension seam that a subscriber can actually use
without forking, no public API without a caller, and record context that works
on and off a record page. Every preservation-charter item still holds.
