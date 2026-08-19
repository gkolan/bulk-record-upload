# Step 01 — Record page context binding — evidence

Step spec: [../../../specs/convergence/01-record-page-context-binding.md](../../../specs/convergence/01-record-page-context-binding.md)

## Automated verification

### Jest — recordId / contextRecordId precedence

- **Requirement:** Step 01 verification items 1–4 (recordId carried, contextRecordId
  carried, recordId wins when both set, null context when neither set and no error).
- **Working-tree identity:** branch `convergence/01-record-page-context-binding`,
  commit `bind record page context to bulkRecordUploadMultiProcess` (see `git log`).
- **Timestamp:** 2026-08-19T18:00Z (approximate; see local commit timestamps).
- **Actor/tool:** `sfdx-lwc-jest` (`@salesforce/sfdx-lwc-jest`, project-pinned version).
- **Command:** `npx sfdx-lwc-jest -- --testPathPattern bulkRecordUploadMultiProcess`
- **Target:** local (jsdom).
- **Expected result:** All test cases in
  `bulkRecordUploadMultiProcess/__tests__/bulkRecordUpload.test.js` pass, including
  the four new cases covering `recordId`/`contextRecordId` precedence.
- **Observed result:** Passed. 14/14 tests passed in the suite (10 pre-existing + 4
  new: "sends the platform-injected recordId on a record page", "sends the
  Experience Cloud contextRecordId when recordId is absent", "prefers the platform
  recordId over contextRecordId when both are set", "submits a null context when
  neither recordId nor contextRecordId is set").
- **Artifact:** test source at
  `force-app/main/default/lwc/bulkRecordUploadMultiProcess/__tests__/bulkRecordUpload.test.js`.
- **Reviewer:** Claude (agent), pending human review.
- **Limitations/follow-up:** Covers the client-side precedence contract only, not
  the platform's actual injection of `recordId`/`objectApiName` on a live record
  page (see manual verification below).

### ESLint / Prettier

- **Requirement:** Exit gate — "ESLint, Prettier, and Jest pass."
- **Command:**
  `npx eslint force-app/main/default/lwc/bulkRecordUploadMultiProcess/bulkRecordUploadMultiProcess.js force-app/main/default/lwc/bulkRecordUploadMultiProcess/__tests__/bulkRecordUpload.test.js`
  and
  `npx prettier --check "force-app/main/default/lwc/bulkRecordUploadMultiProcess/**/*.{js,xml}"`
- **Target:** local.
- **Expected result:** No lint errors; Prettier reports no formatting issues.
- **Observed result:** Passed. ESLint produced no output (clean). Prettier
  initially flagged the test file; `prettier --write` was run and a follow-up
  `--check` passed clean.
- **Artifact:** N/A (tool output only).
- **Reviewer:** Claude (agent), pending human review.

## Deploy verification

- **Requirement:** Exit gate — "`targetConfigs` change deploys cleanly."
- **Working-tree identity:** commit `bind record page context to
bulkRecordUploadMultiProcess` on `convergence/01-record-page-context-binding`.
- **Timestamp:** 2026-08-19T18:27Z.
- **Actor/tool:** Salesforce CLI (`sf` 2.146.3), `sf project deploy start`.
- **Command:** `sf project deploy start --target-org <alias> --source-dir force-app --wait 20`
- **Target:** scratch (alias `sfdo827`, verified instance host
  `*.scratch.my.salesforce.com`; the project's single reusable 30-day scratch org
  per `AGENTS.md`).
- **Expected result:** Deploy succeeds with zero component errors, including the
  updated `bulkRecordUploadMultiProcess` bundle and its `js-meta.xml`.
- **Observed result:** Passed on retry. First attempt failed on one unrelated,
  pre-existing item: an empty leftover directory
  `force-app/main/default/lwc/bulkRecordUploadForm/` (untracked, never in git
  history, no file content) that confused manifest generation. Removed the empty
  directory (a stray local artifact, not a deploy target — the project's own
  `manifest/destructiveChanges-obsolete-one-process-component.xml` already
  documents intent to retire this exact component name). Redeployed:
  0 component errors, 233 components deployed, 0 test errors.
- **Artifact:** raw CLI JSON kept out of version control per
  `docs/evidence/README.md` (contains org/session identifiers); this summary is
  the reviewed record.
- **Reviewer:** Claude (agent), pending human review.
- **Limitations/follow-up:** This proves the metadata deploys and installs
  without error. It does not by itself prove the `targetConfig` properties render
  correctly in Experience Builder (see manual verification below).

## Manual verification — not completed by the agent

The following exit-gate items require interacting with the Salesforce UI
(Lightning App Builder / a live record page / Experience Builder) and could not
be completed in this session: the environment's browser-automation tool reported
the org's domain as "not approved for tool access," so no UI-driven check could
be run.

- [ ] A `REQUIRE_PARENT` process on a host record page completes an upload and
      the created records carry the parent in the field named by
      `RecordContextFieldApiName__c`.
- [ ] The same process on an App page is blocked with a stated reason rather than
      failing at submit or silently uploading orphans.
- [ ] The `contextRecordId` / `contextObjectApiName` `targetConfig` properties are
      visible and bindable in Experience Builder.

### Fixture prepared for whoever completes this

A disposable `REQUIRE_PARENT` test process was deployed directly to the scratch
org (`sfdo827`) to make manual verification a five-minute task rather than a
from-scratch setup. It is **not** committed to the repository (org-only, mdapi
push from a local temp folder) so it does not affect the package:

- Bundle developer name: `Contact_RequireParent_QA`
- Process: Contact insert, `RecordContextAction__c = REQUIRE_PARENT`,
  `HostObjectApiName__c = Account`, `RecordContextFieldApiName__c = AccountId`.
- A test Account record exists in the org (`ConvergenceQAAccount`) to use as the
  parent context.

To complete verification: in Lightning App Builder, add the
`bulkRecordUploadMultiProcess` component to the Account record page, set
**Upload Bundle** to `Contact_RequireParent_QA`, save/activate, open the QA
Account record, upload a one-row Contact CSV, and confirm the created Contact's
`AccountId` equals the QA Account's Id. Then repeat with the component on an App
page (no record context) and confirm the process is blocked with a stated
reason. Delete the QA fixture and the QA Account afterward if not otherwise
needed — the destructive-changes/data cleanup is intentionally left to whoever
completes this so they can also verify their own click-through instead of
inheriting a pre-cleaned state.

## Four-invariant summary (per AGENTS.md)

- **Maintainable:** One precedence rule (`recordId ?? contextRecordId`) in one
  getter; every consumer reads the getter, matching the step's stated intent.
- **Scalable/extensible:** No new server-side surface; reuses the existing
  validated `BulkRecordUploadRecordContextService` contract untouched.
- **Understandable:** `targetConfig` property descriptions state the binding
  expression (`{!recordId}`) an admin needs on Experience Cloud pages.
