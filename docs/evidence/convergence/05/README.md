# Step 05 — Rename the exposed component — evidence

Step spec: [../../../specs/convergence/05-rename-exposed-component.md](../../../specs/convergence/05-rename-exposed-component.md)

## Branch note

This step's precondition is step 04. This step's "Must not change" list
includes the Experience Cloud context properties added in step 01, so this
branch (`convergence/05-rename-exposed-component`, created on top of
`convergence/04-remove-dead-public-surface`) also merged in
`convergence/01-record-page-context-binding` before verification, so the
renamed bundle carries step 01's `recordId`/`contextRecordId` binding rather
than an older snapshot of the file. The merge was a clean auto-merge (git's
rename detection followed the file across the directory rename); no manual
conflict resolution was needed.

## Repository-wide search

- **Requirement:** "Repository-wide search for `bulkRecordUploadMultiProcess`
  returns nothing."
- **Command:** `Grep` for `bulkRecordUploadMultiProcess|BulkRecordUploadMultiProcess`
  across the repository root.
- **Observed result:** Passed, with five intentional exceptions, each
  historical/narrative rather than a live reference an admin or the runtime
  would follow:
  - `docs/evidence/convergence/04/README.md` — prior step's evidence, a
    dated record of what was true then.
  - `specs/11-record-context-sources.md` — superseded draft (per
    `specs/00-program-overview.md`), not live.
  - `specs/convergence/01-record-page-context-binding.md` and
    `specs/convergence/05-rename-exposed-component.md` — the plan's own spec
    files, describing the defect/rename by necessity.
  - `specs/artifacts/api-naming-migration.md` — the research-to-production
    naming decision record from the main program; a historical artifact, not
    an install/configuration guide.
  - `specs/10-release-validation.md` keeps one explanatory parenthetical
    ("named `bulkRecordUploadMultiProcess` before convergence step 05's
    rename") for readers of that dated clarification entry; its two
    operational references (the component name a reader would actually type
    or place) were updated to `bulkRecordUpload`.
  - All non-historical references were updated: the bundle directory and its
    four member files, `manifest/package.xml`,
    `force-app/main/default/tabs/Bulk_Record_Upload.tab-meta.xml`,
    `force-app/main/default/flexipages/Account_Bulk_Record_Upload_Demo_Record_Page.flexipage-meta.xml`,
    `eslint.config.js`, `docs/developer/architecture.md`, and the test file's
    `c/` import.

## Persistent-org placement check

- **Requirement:** work item 5 — "If any FlexiPage in the authorized
  persistent org places the old component, record what must be re-placed
  manually after deploy."
- **Command:** `sf org display --target-org sfdo-gk-dev-ed` (verify resolved
  instance host first), then
  `sf data query --target-org sfdo-gk-dev-ed --use-tooling-api --file <query>`
  with `SELECT DeveloperName FROM LightningComponentBundle WHERE DeveloperName = 'bulkRecordUploadMultiProcess'`.
- **Target:** the approved persistent org
  (`https://sfdo-gk-dev-ed.develop.my.salesforce.com`), read-only Tooling API
  query, no mutation.
- **Observed result:** Passed. 0 records. The old component name has never
  been deployed to the persistent org, so there is no live placement to
  re-place.

## Jest

- **Command:** `npx sfdx-lwc-jest -- --testPathPattern bulkRecordUpload`
- **Expected result:** Passes with no renamed-module import errors.
- **Observed result:** Passed. 37/37 tests across 9 suites (the renamed
  bundle's own suite plus its eight sibling internal components), 0 failures.

## Deploy verification

- **Commands:**
  `sf project deploy start --target-org sfdo827 --source-dir force-app --wait 20 --ignore-conflicts --dry-run`,
  then the same without `--dry-run`, then a destructive-changes deploy
  removing the stale `bulkRecordUploadMultiProcess` bundle left in the org
  from earlier deploys in this program (source-controlled rename does not
  retroactively delete the old org component; this mirrors the pattern from
  steps 01 and 03).
- **Target:** scratch (alias `sfdo827`).
- **Observed result:** Passed at every stage. Dry-run: 0 component errors.
  Real deploy: 0 component errors. Destructive cleanup of the orphaned old
  bundle: 0 component errors.

## App Builder / record-context UI verification — not completed by the agent

- **Requirement:** "After deploy to the scratch org, the component appears in
  App Builder under 'Bulk Record Upload' and can be placed on a record page,
  an app page, and an Experience Cloud page" and "A placed component still
  receives record context, re-running the step 01 record-page check."
- **Observed result:** Unavailable, for the same reason recorded in
  [step 01's evidence](../01/README.md): the environment's browser-automation
  tool reports this org's domain as not approved for tool access, so no UI
  click-through could be performed.
- **What was verified instead, as the strongest available substitute:** the
  deployed `LightningComponentBundle` metadata for `bulkRecordUpload` was
  read directly from source after the merge with step 01 and confirmed
  byte-identical in every field this step promises not to change:
  `isExposed=true`, the six-target `targets` list, both `targetConfig`
  blocks (including the `contextRecordId`/`contextObjectApiName` Experience
  Cloud properties from step 01), and the unchanged `masterLabel` ("Bulk
  Record Upload") and `description`. The clean deploy (above) proves the
  metadata is well-formed and installable; it does not prove the App Builder
  UI renders it, which remains open per step 01's same fixture-and-handoff
  approach — the QA fixture and test Account recorded there remain valid for
  whoever performs this component's UI check too, since it is the same
  component under its new name.

## Exit gate

- [x] All verification items pass with recorded evidence (one item marked
      Unavailable with rationale and a documented substitute, consistent with
      step 01's precedent).
- [x] Exactly one component has `isExposed=true` and it is named
      `bulkRecordUpload`: confirmed by reading the deployed bundle's
      `js-meta.xml` and by the repository-wide search above finding no other
      `isExposed=true` bundle.
- [x] Evidence recorded at `docs/evidence/convergence/05/`.

## Four-invariant summary (per AGENTS.md)

- **Understandable:** The one name a subscriber ever types now describes the
  product, matching the `masterLabel` administrators already see.
- **Maintainable:** Renamed before packaging locks the name, per the
  program's own stated rationale — cheap now, expensive after distribution.
- **Scalable/Extensible:** N/A — pure rename, no behavior or extensibility
  surface changed.
