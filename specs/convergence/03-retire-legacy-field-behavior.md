# Step 03 — Retire the legacy field behavior duplicate

## Goal

Leave exactly one way to configure what happens to a field's value.

## Why

There are two, and the older one is a silent trap.

`ValueHandling__c` is labelled **"Legacy Value Handling"** with values
`REPLACE` / `APPEND` / `PREPEND` / `CLEAR_WHEN_BLANK`. The V2 replacement is five
fields — `BlankValueAction__c`, `ExistingValueAction__c`, `TextSeparator__c`,
`DuplicateTextAction__c`, `OverflowAction__c` — driving
`BulkRecordUploadFieldMergePolicy`. Both are visible to administrators.

`BulkRecordUploadFieldConfigV1.cls:35-46` uses the legacy field only as a
_default when the V2 field is blank_, which is correct precedence. But both V2
picklists declare a default value in their metadata, so they are prefilled on
every new configuration record and are effectively never blank. An administrator
who sets `ValueHandling__c = APPEND`, sees no other relevant field, and expects
append **gets REPLACE, silently.** Configuration that appears to do something and
does nothing is worse than configuration that does not exist.

The legacy execution path is also dead. `BulkRecordUploadRecordMapper.cls:4`
declares a `behaviors` registry field that `mapRows` never calls, and the
`behavior` value is carried into the projection
(`BulkRecordUploadProjectionService.cls:268`) where nothing consumes it.
`BulkRecordUploadFieldBehavior` (102 lines),
`BulkRecordUploadFieldBehaviorRegistry`, and `BulkRecordUploadFieldBehaviorV1`
are reachable only from tests.

This is the worked example behind the predictability rule in ADR-0007.

## Preconditions

Step 02 complete, so the deletion cites a recorded decision.

## Must not change

- **The V2 merge policy is the keeper.** `BulkRecordUploadFieldMergePolicy` and
  its five configuration fields are the surviving mechanism and their behavior is
  untouched.
- Existing configuration that relies on the legacy field for its _effective_
  value must keep producing the same result until the field itself is removed.
  The translation shim stays until the removal decision in work item 5.

## Work

1. **Prove the deletions first.** For each of `BulkRecordUploadFieldBehavior`,
   `BulkRecordUploadFieldBehaviorRegistry`, and `BulkRecordUploadFieldBehaviorV1`,
   record a repository-wide reference search showing no non-test production
   caller. If any exists, stop and report.
2. Delete those three classes and their `-meta.xml` files, and remove the unused
   `behaviors` field from `BulkRecordUploadRecordMapper`.
3. Remove the `behavior` property from `BulkRecordUploadFieldProjectionV1`, its
   constructor parameter, and the argument passed at
   `BulkRecordUploadProjectionService.cls:268`. Demote
   `BulkRecordUploadFieldConfigV1.behavior` from a public property to a local
   variable used only by the translation.
4. **The one intentional behavior change in this step.** At configuration load,
   if `ValueHandling__c` is populated _and_ the V2 field it would translate to is
   also populated _and_ they disagree, throw a configuration error naming both
   fields. This converts today's silent trap into a loud, admin-actionable
   failure. It can only fire on configuration that is already silently wrong.
5. **Decide the legacy field's fate against distribution history.** If no package
   version has ever been released, delete `ValueHandling__c` and its translation
   outright. If any version has shipped, keep the translation, mark the field
   deprecated in its description, and remove it from permission-set field
   visibility and any layout so no new administrator can set it — then schedule
   deletion for the next major version. Record which branch was taken and why.
6. Update `docs/reference/configuration-fields.md` and
   `docs/reference/field-behaviors.md` so exactly one mechanism is documented.
7. Update tests: delete those that exercised the removed classes; keep and, where
   needed, extend the merge-policy tests. Add coverage for the new conflict
   error. Reusable fixtures come from `BulkRecordUploadTestDataFactory`.

## Verification

- [ ] Reference-search output for all three deleted classes is recorded and shows
      no non-test production caller.
- [ ] Full Apex test suite passes. Apart from tests deleted in work item 7, no
      existing test's **assertions** were modified — only references to deleted
      symbols. An assertion change means behavior moved; stop and report.
- [ ] A field configured only through V2 fields produces identical merge results
      before and after, proven on a fixture exercising every
      `ExistingValueAction__c` and `BlankValueAction__c` combination.
- [ ] Conflicting legacy and V2 configuration fails at load with a message naming
      both fields.
- [ ] Non-conflicting configuration loads unchanged.
- [ ] Salesforce Code Analyzer passes with no new violations.
- [ ] Documentation describes one mechanism; no page still explains two.
- [ ] Deploys cleanly to the scratch org.

## Exit gate

- [ ] All verification items pass with recorded evidence.
- [ ] Net Apex line count decreased by roughly 150 lines.
- [ ] The chosen branch of work item 5 is recorded with its rationale.
- [ ] Evidence recorded at `docs/evidence/convergence/03/`.

## Rollback

Deletions are recoverable from git. The conflict error in work item 4 is the only
runtime-visible change and can be reverted independently of the deletions.
