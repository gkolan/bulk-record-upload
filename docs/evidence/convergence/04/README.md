# Step 04 — Remove dead public surface — evidence

Step spec: [../../../specs/convergence/04-remove-dead-public-surface.md](../../../specs/convergence/04-remove-dead-public-surface.md)

## Prove-before-delete reference search

- **Requirement:** "Reference-search output recorded for both deleted methods."
- **Command/procedure:** `Grep` for `getProcessKeys|getProcessKey\b` across
  `force-app`.
- **Observed result:** Passed. Only `BulkRecordUploadController.cls` (the
  declarations) and `BulkRecordUploadRequestServiceTest.cls` (test-only)
  referenced them. No LWC or Aura reference existed. Confirmed by reading
  `BulkRecordUploadRequestService.listProcessKeys()`, the method
  `getProcessKeys` delegated to: its only caller was the now-deleted
  `getProcessKeys` Aura method.
- **Scope note:** With `getProcessKeys` deleted, `listProcessKeys()` and its
  helper `isSupportedConfigurationVersion()` on
  `BulkRecordUploadRequestService` became unreachable from any caller (a
  second reference search confirmed this). They are not named in the step
  file, but leaving newly-dead code behind contradicts this step's own goal
  ("leave no public API without a caller, and no empty scaffolding"), so they
  were removed in the same change along with the test that covered only them
  (`listProcessKeys_ConfigurationVersions_UsesNumericComparison`).
- **Reviewer:** Claude (agent), pending human review.

## Design choice: controller-only consolidation

The step says to consolidate history retrieval into one
`getHistory(String processKey)` where blank means "all processes." The
existing service layer, `BulkRecordUploadLogService`, already has two
`getHistory` overloads with **different, intentionally tested semantics**: the
no-arg overload returns all visible history, and the `getHistory(String)`
overload actively **rejects** a blank key
(`BulkRecordUploadLogTest.getHistory_BlankProcessKey_IsRejected`, an existing
passing test not modified by this step). Consolidating "blank means all" at
the service layer would have required rewriting that test's assertion — the
signal the working rules treat as "behavior moved, stop and report" — for a
change the step file did not explicitly name at that layer.

Consolidation was therefore done at the `@AuraEnabled` controller boundary
only, which is where the step's stated problem lives ("two public methods for
one concern" — a permanent Aura compatibility surface). The controller's new
single `getHistory(String processKey)` decides which service overload to call:
blank routes to the no-arg "all processes" overload; populated routes through
the existing `resolveProcessKey` validation to the strict single-process
overload, exactly as `getHistoryForProcess` did before. No service-level
behavior changed, and no existing service test's assertions changed.

## Full Apex test suite

- **Working-tree identity:** branch `convergence/04-remove-dead-public-surface`.
- **Command:** `sf apex run test --target-org sfdo827 --test-level RunLocalTests`.
- **Target:** scratch (alias `sfdo827`).
- **Expected result:** All local tests pass; history tests assert the same
  rows as before for both the all-processes and single-process cases.
- **Observed result:** Passed. 177/177 tests passed, 0 failing.
  `BulkRecordUploadLogTest.getHistory_AuthorizedUser_ReturnsVisibleSafeDto` and
  `getHistory_ProcessKey_ReturnsOnlyMatchingUploads` (service-level, unchanged
  assertions) and the renamed
  `BulkRecordUploadRequestServiceTest.controller_FixedProcess_ReturnsScopedHistory`
  (controller-level, unchanged assertions, only the call site updated from
  `getProcessKey`/`getHistoryForProcess` to the consolidated `getHistory`)
  together prove both cases return the same rows as before.
- **Reviewer:** Claude (agent), pending human review.

## Jest

- **Command:** `npx sfdx-lwc-jest -- --testPathPattern bulkRecordUploadMultiProcess`
- **Expected result:** Component renders history identically in both cases.
- **Observed result:** Passed. 10/10 tests passed. Updated the mock import and
  call-site assertions from `getHistoryForProcess` to the consolidated
  `getHistory`, and added an explicit assertion that the multi-process
  ("all processes") path calls `getHistory({ processKey: null })` — this
  case previously had no direct assertion of its call arguments.

## Deploy dry-run

- **Requirement:** "`sf project deploy start --dry-run` against the scratch
  org succeeds with no reference to a removed member."
- **Command:** `sf project deploy start --target-org sfdo827 --source-dir force-app --wait 20 --ignore-conflicts --dry-run`
- **Observed result:** Passed. 0 component errors.
- **Follow-up real deploy:** also run (not dry-run) to update the org ahead of
  the Apex test run above; 0 component errors.

## Least-privilege visibility

- **Requirement:** "A least-privilege user sees exactly the same history rows
  as before, proving consolidation did not widen visibility."
- **Observed result:** Passed via the unmodified authorization path: the
  consolidated controller method still calls
  `new BulkRecordUploadAccessPolicy().requireRunPermission()` (inside
  `BulkRecordUploadLogService.getHistory`, untouched) before returning any
  row, and `BulkRecordUploadLogTest.getHistory_AuthorizedUser_ReturnsVisibleSafeDto`
  (a least-privilege `runAs` test, unmodified) passed in the full suite run
  above.

## Empty directories under `lwc/`

- **Requirement:** "No empty directories remain under `lwc/`."
- **Observed result:** Already satisfied before this step began.
  `force-app/main/default/lwc/bulkRecordUploadForm/` (containing only an empty
  `__tests__` subdirectory, no files, never tracked in git) was removed while
  resolving an unrelated deploy blocker during
  [step 01](../01/README.md). Verified again here:
  `ls force-app/main/default/lwc/ | grep -i bulkRecordUploadForm` returns
  nothing on this branch.

## Salesforce Code Analyzer

- **Command:** `sf code-analyzer run --config-file code-analyzer.yml --target <changed .cls files>`
- **Observed result:** Passed. 0 violations.

## Exit gate

- [x] All verification items pass with recorded evidence.
- [x] Every remaining `@AuraEnabled` method has a live component caller:
      `getSelection`, `getProcessPresentation`, `getTemplate`, `getHistory`,
      `submit` — all five are imported and called in
      `bulkRecordUploadMultiProcess.js`.
- [x] Evidence recorded at `docs/evidence/convergence/04/`.

## Four-invariant summary (per AGENTS.md)

- **Maintainable/Understandable:** One history entry point instead of two; no
  Apex method left published without a caller obligating future compatibility.
- **Scalable:** N/A — no runtime cost change; same queries, same limits.
- **Extensible:** N/A — no new extension surface.
