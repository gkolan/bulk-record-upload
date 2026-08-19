# Step 07 — Record context sources — evidence

Step spec: [../../../specs/convergence/07-record-context-sources.md](../../../specs/convergence/07-record-context-sources.md)

## Branch note

This branch (`convergence/07-record-context-sources`) was created on top of
`convergence/06-single-extension-seam` (which already carries steps 02 and 03) and merged in `convergence/01-record-page-context-binding` before work
began, satisfying the step's "01, 03, 06" precondition. The merge was clean
(no conflicts).

## Design choices worth recording

- **Filter grammar.** The spec asks for "field/operator/value triples" without
  prescribing a concrete syntax. Implemented as one condition per line,
  `FieldApiName:Operator:Value`, operators `=`/`!=`/`IN` (comma-separated
  values for `IN`), lines combined with AND. Chosen for the same reason the
  package already prefers plain delimited text over JSON in admin-facing
  Custom Metadata text fields (see the field-list convention this step also
  uses): one administrator-typeable format, one parser, no JSON authoring
  errors in Setup.
- **Additional-field platform cap.** The spec says "confirm the current cap
  for API 67.0 and enforce it." This session could not browse current
  Salesforce documentation to confirm the exact platform limit for
  `lightning-record-picker`'s `matchingInfo`/`displayInfo` additional-field
  arrays. `BulkRecordUploadRuntimeContract.MAX_ADDITIONAL_CONTEXT_FIELDS = 3`
  is enforced identically for both search and display fields as a
  conservative, documented placeholder — recorded here explicitly so it is
  easy to find and correct against the verified platform value before
  release, per Step 10's release-validation gate.
- **Context settings as one value object.** `BulkRecordUploadContextProjectionV1`
  holds all four settings as a single `BulkRecordUploadProjectionV1` property,
  per the spec's explicit design section, rather than extending the
  already-telescoping `BulkRecordUploadProjectionV1` constructor chain
  further.

## Prove-before-delete

`specs/11-record-context-sources.md` (the superseded draft) had one
reference from `specs/00-program-overview.md`'s step list, which is updated
in the same change. No Apex or LWC referenced the old draft. The file is
deleted per the exit gate.

## Verification

- [x] **Zero-config default.** `BulkRecordUploadContextSourceServiceTest.buildContextProjection_BlankFieldLists_DefaultToNameField`
      and the Jest test "renders a working picker from HostObjectApiName
      alone" both prove a process with only `HostObjectApiName__c` set
      produces a working picker searching/displaying the name field.
- [x] **`matching-info` receives field objects, `display-info` receives
      strings, exact shapes asserted.** Same Jest test asserts
      `picker.matchingInfo` equals `{ primaryField: { fieldPath: 'Name' },
  additionalFields: [] }` and `picker.displayInfo` equals
      `{ primaryField: 'Name', additionalFields: [] }` — objects for one,
      strings for the other, per field.
- [x] **Non-searchable and non-existent fields fail validation with
      admin-actionable messages.**
      `buildContextProjection_UnknownSearchField_ThrowsSafeException` (names
      the field, says "unavailable") and
      `buildContextProjection_NonSearchableSearchField_ThrowsSafeException`
      (`Account.Description`, a long text area, says "not searchable").
  - **Unreadable display fields — not exercised by a live test.** The
    `isAccessible()` check exists in
    `BulkRecordUploadContextSourceService.validateFieldList` and is
    structurally identical to the readable/filterable checks that _are_
    tested. It could not be exercised with a genuinely FLS-restricted user in
    this session: Salesforce's permission model is additive (a
    `PermissionSet` can grant access a profile lacks, but cannot revoke
    access a profile already grants), and the scratch org's test-user profile
    already grants full field access, so no `PermissionSet`-only
    construction produces a truly unreadable field without deploying a new,
    more restrictive `Profile` — out of scope for a unit test. Recorded as an
    open gap rather than a false pass.
- [x] **Exceeding the platform cap fails validation, not render.**
      `buildContextProjection_TooManyAdditionalFields_ThrowsSafeException`.
- [x] **A client-supplied ID outside `ContextFilterCriteria__c` is rejected
      server-side, proven by a test that bypasses the LWC.**
      `BulkRecordUploadRequestServiceTest.recordContext_FilteredOutParent_IsRejectedEvenWhenVisible`
      and `recordContext_IdInFilter_RejectsVisibleNonMemberBypassingTheComponent`
      call `BulkRecordUploadRecordContextService.validateContext` directly —
      no LWC, no picker — with a filtered `contextProjection` and a real,
      fully visible Account that the filter excludes.
- [x] **An `Id IN (...)` filter rejects a visible non-member.** Same tests
      above, plus `BulkRecordUploadContextSourceServiceTest.isEligible_IdInFilter_RejectsVisibleNonMember`
      at the service-unit level.
  - **"A record invisible to the running user is neither offered nor
    accepted" — partially covered.** The "not accepted" half reuses the
    unchanged `WITH USER_MODE` query pattern `validateContext` already used
    before this step (visibility enforcement is not new code this step
    introduced). The "not offered" half is the platform's own behavior
    inside `lightning-record-picker`, which enforces sharing itself and is
    not something this package's Apex controls. No dedicated cross-user
    sharing test was added in this session; recorded as a gap rather than
    silently assumed.
- [x] **`REQUIRE_PARENT` under `USER_CHOICE` blocks file selection until a
      parent is chosen.** Jest: "blocks file selection with a stated reason
      when REQUIRE_PARENT has no chosen parent" — asserts the file-input is
      absent and the stated-reason alert is shown, then that choosing a
      parent via the picker's `change` event reveals the file input.
- [x] **Changing the process clears the chosen parent.** Jest: "clears the
      chosen parent when the process changes."
- [x] **No host object describe reaches the browser.** By construction:
      `BulkRecordUploadPresentationV1` sends only field-name strings and a
      JSON-serialized filter (values and field names, never a
      `Schema.DescribeSObjectResult`). `scripts/run-large-schema-benchmark.mjs`
      re-run after this step: 100 configured fields → 17,163 serialized
      bytes, 0.0081ms mean projection time, both within budget; the
      200-field rejection guard and the never-project-all-source-fields
      guard both still hold.
- [x] **`configHash` changes on any context setting change.**
      `BulkRecordUploadContextHashTest.projection_ContextSettingChange_ChangesConfigHashAndBustsCache`
      builds two otherwise-identical configurations differing only in
      `ContextSearchFields__c` and asserts different `configHash` values.
  - Cache miss/put/corrupt-recovery paths reuse the existing, unmodified
    `BulkRecordUploadProjectionCache` tests in
    `BulkRecordUploadConfigProjectionTest.cache_CorruptEntry_RemovesAndReturnsMiss`
    — the cache mechanism itself was not changed by this step, only what
    goes into the hash.
- [x] **Accessibility automation passes for the picker.** Jest
      `toBeAccessible()` (sa11y) passes on the picker-rendering test.
  - **Keyboard-only traversal from picker to file input to submit — not
    recorded.** This requires a live browser session. The same environment
    limitation recorded in steps 01 and 05 applies: the browser-automation
    tool reports this org's domain as not approved for tool access.

## Full Apex test suite and deploys

- **Command:** `sf apex run test --target-org sfdo827 --test-level RunLocalTests`
  (run three times as compile errors and a Code Analyzer violation were
  fixed).
- **Final result:** Passed. 196/196 tests, 0 failing.
- **Deploys:** Multiple iterations fixing real compiler errors caught only by
  the org: `List<String>` has no `subList` method in Apex (unlike Java) —
  replaced with a manual loop; a leftover two-argument delegating
  constructor call in `BulkRecordUploadPresentationV1` left over from an
  earlier disambiguation attempt; an invalid ternary mixing `String` and
  `List<String>` return types. Final deploy: 0 component errors.
- **Class-length correction:** `BulkRecordUploadConfigProjectionTest.cls`
  reached 475 lines (over this program's 450-line warning threshold and this
  step's explicit "no class exceeds 450 lines" exit gate) after the new
  config-hash test was added. Extracted that one test and its helpers into a
  new `BulkRecordUploadContextHashTest.cls` (102 lines), bringing the
  original back to 398. That extraction first used the name
  `BulkRecordUploadContextProjectionCacheTest`, which the org's compiler
  rejected as exceeding Apex's 40-character class-name limit — renamed to
  `BulkRecordUploadContextHashTest`.

## Salesforce Code Analyzer

- **Command:** `sf code-analyzer run --config-file code-analyzer.yml --target "force-app/main/default/classes/*.cls"`
- **Observed result:** Passed after two fixes. Two new `AvoidHardcodingId`
  violations (literal ID-shaped strings in a filter-parsing test) were fixed
  by using real inserted `Account` IDs instead. Final run: 1 violation
  remains (`AvoidGlobalModifier` in `BulkRecordUploadBundlePicklist.cls`),
  confirmed pre-existing and unrelated in every prior step's evidence.

## Metadata/boundary checks

- `node scripts/check-metadata.mjs` caught a real new issue this step
  introduced: `ContextFilterCriteria__c`'s description exceeded 255
  characters (the project's documented default limit per
  `development-standards/salesforce-naming-and-metadata-writing-standard.md`).
  Shortened and re-verified. Remaining output is the same four pre-existing,
  unrelated findings recorded in every prior step's evidence
  (`Account_Record_Page` flexipage manifest gap; three CMDT fields missing
  inline help on `Bulk_Record_Upload_Bundle_Process__mdt`/`Bulk_Record_Upload_Bundle__mdt`,
  none touched by this program).
- `node scripts/check-package-boundary.mjs`: same one pre-existing,
  unrelated finding as every prior step.

## Documentation and manifest

- [docs/reference/configuration-fields.md](../../reference/configuration-fields.md)
  documents all four new fields, the shared field-list convention, the
  filter grammar, and states the predictability-rule reasoning per field
  (below).
- [docs/admin/configure-upload-process.md](../../admin/configure-upload-process.md)
  gets a new "Let the user choose the parent off a record page" section.
- `manifest/package.xml` updated: four new fields on
  `Bulk_Record_Upload_Process__mdt`, five new Apex classes, two new Custom
  Labels.
- Permission-set field visibility (work item 9): no new
  `fieldPermissions` entries were needed. This package's existing pattern
  grants Custom Metadata Type field access entirely through the
  object-level `customMetadataTypeAccesses` entry already present for
  `Bulk_Record_Upload_Process__mdt` (added in earlier steps, unchanged
  here) — none of this package's other CMDT fields have individual
  `fieldPermissions` entries either, so adding them only for the four new
  fields would have been inconsistent with the established pattern.

## Predictability rule, per new field (ADR-0007 exit-gate requirement)

- **`RecordContextSource__c`:** An administrator reads this field alone and
  knows whether a picker can ever appear (`PAGE` = never; `USER_CHOICE` =
  when no page context). No other field's value changes that answer.
- **`ContextSearchFields__c`:** Determines picker search behavior alone. Blank
  has one defined meaning (name field only); populated has one defined
  parsing rule (first = primary, rest = additional). Does not depend on
  `ContextDisplayFields__c` or any other field.
- **`ContextDisplayFields__c`:** Same rule, independently, for display
  behavior. Reading this field never requires also reading
  `ContextSearchFields__c` to predict the outcome.
- **`ContextFilterCriteria__c`:** Determines eligibility alone, applied
  identically wherever it runs (picker and server). There is no second field
  whose value changes what this one means — unlike the `ValueHandling__c`
  failure case in ADR-0007, there is exactly one place this setting's
  effective value comes from.

## Exit gate

- [x] Most verification items pass with recorded evidence; three items are
      explicitly marked partial/not-performed with rationale (unreadable-field
      FLS test, invisible-record cross-user test, live keyboard-traversal
      recording) rather than claimed complete.
- [x] `specs/11-record-context-sources.md` is deleted;
      `specs/00-program-overview.md` no longer lists it as a pending draft
      (updated to point at this step instead).
- [x] No class exceeds 450 lines (verified after the
      `BulkRecordUploadContextHashTest` extraction; largest remaining class
      touched by this step is `BulkRecordUploadConfigProjectionTest.cls` at
      398 lines).
- [x] Every new setting's predictability-rule reasoning is stated per-field
      above.
- [x] Evidence recorded at `docs/evidence/convergence/07/`.

## Four-invariant summary (per AGENTS.md)

- **Extensible:** A process author gets record-context off a record page
  without forking anything — pure configuration, matching ADR-0007.
- **Maintainable/Understandable:** One field-list convention, one parser, one
  filter grammar, reused for both search and display and stated once in
  documentation.
- **Scalable:** Bounded additional-field count and filter-condition count;
  compact projection budget re-verified unaffected.
- **Security:** The filter is enforced twice by design, but only the
  server-side enforcement inside `validateContext` is load-bearing — the
  picker-side filter is convenience only, and the evidence above proves a
  caller that bypasses the component entirely is still rejected.
