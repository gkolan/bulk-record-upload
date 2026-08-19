# Step 04 — Remove dead public surface

## Goal

Leave no public API without a caller, and no empty scaffolding for a reader to
trip over.

## Why

In a distributed package an `@AuraEnabled` method is a permanent supported
surface and a permission surface. `BulkRecordUploadController.getProcessKeys` and
`getProcessKey` are referenced by tests and by no LWC. They carry a
compatibility obligation forever and buy nothing.

`getHistory` and `getHistoryForProcess` are two public methods for one concern.
Consolidating them is cheap now and a breaking change after distribution.

`force-app/main/default/lwc/bulkRecordUploadForm/` contains only an empty
`__tests__` directory. A newcomer looking for "the form component" finds an empty
shell.

## Preconditions

None. Independent of steps 01 to 03.

## Must not change

- The methods the component actually uses keep their behavior. `getSelection`,
  `getProcessPresentation`, `getTemplate`, and `submit` are untouched.
- Cacheability annotations on retained methods stay as they are.
- History authorization and row visibility are preserved exactly. This step
  reshapes the method signature, not who can see which rows.

## Work

1. Record a reference search proving `getProcessKeys` and `getProcessKey` have no
   non-test caller in Apex, LWC, or Aura. If any exists, stop and report.
2. Delete both methods and the tests that existed solely to cover them.
3. Consolidate history retrieval into a single `getHistory(String processKey)`
   where a blank value means "all processes the user may see." Update the
   component's two call sites and the Apex tests.
4. Delete the empty `bulkRecordUploadForm/` directory.
5. Check `manifest/package.xml` and the permission sets for references to removed
   members and update them.

## Verification

- [ ] Reference-search output recorded for both deleted methods.
- [ ] Apex test suite passes; history tests assert the same rows as before for
      both the all-processes and single-process cases.
- [ ] Jest passes; the component renders history identically in both cases.
- [ ] `sf project deploy start --dry-run` against the scratch org succeeds with no
      reference to a removed member.
- [ ] A least-privilege user sees exactly the same history rows as before,
      proving consolidation did not widen visibility.
- [ ] No empty directories remain under `lwc/`.

## Exit gate

- [ ] All verification items pass with recorded evidence.
- [ ] Every remaining `@AuraEnabled` method has a live component caller.
- [ ] Evidence recorded at `docs/evidence/convergence/04/`.

## Rollback

Recoverable from git. Work item 3 is the only one touching a live call path and
can be reverted independently.
