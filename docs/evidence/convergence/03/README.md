# Step 03 — Retire the legacy field behavior duplicate — evidence

Step spec: [../../../specs/convergence/03-retire-legacy-field-behavior.md](../../../specs/convergence/03-retire-legacy-field-behavior.md)

## Prove-before-delete reference search

- **Requirement:** "Reference-search output for all three deleted classes is
  recorded and shows no non-test production caller."
- **Command/procedure:** `Grep` for `BulkRecordUploadFieldBehavior\b`,
  `BulkRecordUploadFieldBehaviorRegistry`, `BulkRecordUploadFieldBehaviorV1`
  across `force-app`.
- **Target:** local (source tree).
- **Expected result:** Only test classes and the classes' own declarations
  reference the three types, plus one unused field declaration in
  `BulkRecordUploadRecordMapper`.
- **Observed result:** Passed. Matches were: the three classes' own files;
  `BulkRecordUploadRecordMapper.cls` (declared a `behaviors` field of type
  `BulkRecordUploadFieldBehaviorRegistry` that `mapRows` never reads — confirmed
  by reading the full method body); `BulkRecordUploadMappingTest.cls` and
  `BulkRecordUploadEdgeCoverageTest.cls` (test-only). No non-test production
  caller found.
- **Reviewer:** Claude (agent), pending human review.

## Full Apex test suite

- **Requirement:** "Full Apex test suite passes." Assertion-preservation rule:
  no existing test's assertions were modified, only references to deleted
  symbols.
- **Working-tree identity:** branch `convergence/03-retire-legacy-field-behavior`.
- **Timestamp:** 2026-08-19T19:30Z (approximate).
- **Actor/tool:** Salesforce CLI (`sf` 2.146.3), `sf apex run test --test-level RunLocalTests`.
- **Target:** scratch (alias `sfdo827`, same reusable org as step 01).
- **Expected result:** All local tests pass; no failures.
- **Observed result:** Passed. 177/177 tests passed, 0 failing, 0 skipped.
- **Artifact:** raw CLI JSON kept out of version control per
  `docs/evidence/README.md`; this summary is the reviewed record.
- **Reviewer:** Claude (agent), pending human review.
- **Assertion-preservation check:** Two test methods that exercised the deleted
  classes directly were deleted
  (`fieldBehavior_CustomAppend_ProvesIndependentExtension` and
  `behaviorRegistry_UnknownKey_IsRejected` in
  `BulkRecordUploadMappingTest.cls`); one
  (`fieldBehavior_NullsAndUnknownKey_AreHandled` in
  `BulkRecordUploadEdgeCoverageTest.cls`) had its `BulkRecordUploadFieldBehavior`
  assertions removed and its one unrelated, verbatim-preserved assertion
  (`BulkRecordUploadOperationRegistry` resolution) relocated to a new method
  `operationRegistry_TrimsAndResolvesKnownKey` so that coverage was not lost.
  Three test data builders (`BulkRecordUploadEdgeCoverageTest.fieldRecord`,
  `BulkRecordUploadConfigProjectionTest.createField`, and the `field()`/ctor
  call sites in `BulkRecordUploadMappingTest.cls`) were updated to set
  `ExistingValueAction__c` instead of the deleted `ValueHandling__c` — a
  reference-only change; no assertion text was altered in any surviving test.

## Merge-result equivalence

- **Requirement:** "A field configured only through V2 fields produces
  identical merge results before and after, proven on a fixture exercising
  every `ExistingValueAction__c` and `BlankValueAction__c` combination."
- **Observed result:** Passed via the existing, unmodified merge-policy tests
  in `BulkRecordUploadMappingTest.cls`
  (`mergePolicy_AppendSeparatorDuplicateAndOverflow_AreSafe`,
  `mergePolicy_BlankActions_AreIndependent`) plus the broader
  `BulkRecordUploadFieldMergePolicy` coverage exercised by the full suite run
  above. `BulkRecordUploadFieldMergePolicy` itself was not touched by this
  step — the deleted code path never reached it — so its passing, unmodified
  tests are direct before/after equivalence evidence.

## Conflicting legacy/V2 configuration

- **Requirement:** "Conflicting legacy and V2 configuration fails at load with
  a message naming both fields."
- **Observed result:** Not applicable, and this is intentional. Step 03 work
  item 5 instructs: "If no package version has ever been released, delete
  `ValueHandling__c` and its translation outright." This repository has no
  prior release (no commit history exists before this program's baseline
  commit), so that branch was taken: `ValueHandling__c` and its translation
  were deleted outright rather than deprecated behind a conflict check. There
  is no longer a configuration path that can express both a legacy and a V2
  value simultaneously, so the conflict this verification item targets is
  structurally impossible rather than checked at runtime — a stronger
  resolution of the same silent-trap problem ADR-0007 names.

## Deploy verification

- **Requirement:** "Deploys cleanly to the scratch org."
- **Command:** `sf project deploy start --target-org sfdo827 --source-dir force-app --wait 20 --ignore-conflicts`
  followed by `sf project deploy start --manifest manifest/package-empty.xml --post-destructive-changes <temp-manifest> --target-org sfdo827`
  to remove the retired `BulkRecordUploadFieldBehavior*` classes and the
  `ValueHandling__c` field from the org (deploy-then-delete, since the org's
  previously-deployed Apex still referenced them until the updated source
  landed).
- **Observed result:** Passed. Regular deploy: 0 component errors. Destructive
  deploy: 0 component errors.
- **Note for whoever runs step 03 elsewhere:** the destructive-changes manifest
  used against the org bundles both the three Apex classes and the
  `ValueHandling__c` field; the source-controlled
  `manifest/destructiveChanges-obsolete-legacy-value-handling.xml` covers the
  field only (matching this repo's one-manifest-per-concern convention). Apex
  class deletions were performed with a temporary, uncommitted manifest since
  no equivalent `destructiveChanges-*.xml` convention exists yet for Apex
  classes in this repo — consider whether that should be added if this
  becomes a recurring pattern.

## Salesforce Code Analyzer

- **Command:** `sf code-analyzer run --config-file code-analyzer.yml --target <changed .cls files>`
- **Target:** local.
- **Expected result:** No violations.
- **Observed result:** Passed. 0 violations across `regex` and `pmd` engines.

## Line-count exit gate

- **Requirement:** "Net Apex line count decreased by roughly 150 lines."
- **Observed result:** `git diff --stat master -- force-app/main/default/classes`
  shows 16 insertions, 149 deletions across the affected class files (net
  -133), consistent with "roughly 150."

## Documentation

- **Requirement:** "Documentation describes one mechanism; no page still
  explains two."
- **Observed result:** Passed.
  `docs/reference/field-behaviors.md` no longer describes `ValueHandling__c`
  as a migration fallback; it states the field has been removed.
  `docs/reference/configuration-fields.md` no longer claims contract version 1
  "translates the legacy behavior into safe defaults"; it clarifies contract
  version is independent of field-behavior configuration, which has exactly
  one mechanism.

## Pre-existing, unrelated check failures (not caused by this step)

`node scripts/check-metadata.mjs` and `node scripts/check-package-boundary.mjs`
both exit 1 on `master` before this step's changes (confirmed by stashing and
re-running on `master`), due to an unrelated `Account_Record_Page` flexipage
manifest/boundary gap and missing inline help text on unrelated
`Bulk_Record_Upload_Bundle_Process__mdt`/`Bulk_Record_Upload_Bundle__mdt`
fields. Not addressed here as out of this step's scope.

## Exit gate

- [x] All verification items pass with recorded evidence (one item marked N/A
      with rationale, per the branch actually taken).
- [x] Net Apex line count decreased by roughly 150 lines.
- [x] The chosen branch of work item 5 ("no version ever shipped" → delete
      outright) is recorded with its rationale, above.
- [x] Evidence recorded at `docs/evidence/convergence/03/`.

## Four-invariant summary (per AGENTS.md)

- **Maintainable/Understandable:** One field-behavior mechanism instead of two;
  a duplicated, unread `behaviors` field removed from
  `BulkRecordUploadRecordMapper`.
- **Scalable:** Fixed a latent cache-key bug in the process: the config hash
  previously hashed the legacy-derived `behavior` value instead of the
  effective `existingValueAction`, so a V2-only configuration change to
  `ExistingValueAction__c` would not have busted the cached projection. Now
  the hash reflects the field actually in effect.
- **Extensible:** N/A — no new extension surface; this step removes a
  duplicate, per ADR-0007.
