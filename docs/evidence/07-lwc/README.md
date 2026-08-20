# Step 7 — Lightning user experience evidence

Working-tree identity: uncommitted implementation snapshot; baseline commit remains maintainer-gated by Step 1.

## Implemented component boundary

The exposed `bulkRecordUpload` orchestrator composes focused process selector, local file input, confirmation, bounded preview, progress, history/result download, and shared pure utility bundles. It is exposed to Lightning App/Home pages and Experience Builder pages. No documentation-only component or runtime documentation fetch is present.

Lightning Base Components provide combobox, file input, buttons, progress, datatables, spinners, card, icon, and toast behavior. Local file selection is intentional: Apex must validate the complete request before a Salesforce File is created.

## Automated frontend gate

- **Timestamp:** 2026-08-12T03:45:00-05:00.
- **Actor/tool:** ESLint 9, Salesforce LWC Jest, Salesforce SLDS Linter 1.2.1, Prettier, and repository architecture scripts.
- **Commands:** `npm run lint`; `npm run test:unit -- -- --runInBand`; `npx @salesforce-ux/slds-linter@latest lint force-app/main/default/lwc`; `npm run check:source`.
- **Target:** local Core source.
- **Expected result:** no lint/SLDS violations, all Jest suites pass, and every LWC bundle has explicit manifest ownership.
- **Observed result:** Passed. ESLint reported zero findings; 8 Jest suites and 27 tests passed, including Salesforce Sa11y automation and the maximum-preview budget; SLDS Linter reported zero violations; source checks passed for 210 Core files.
- **Artifact:** LWC `__tests__` folders and repository scripts. Generated caches/logs remain ignored.
- **Reviewer:** implementation owner; maintainer review pending.

Automated cases cover initialization, permission/network failure, offline/recovery announcements, bounded quoted-CSV preview, duplicate/malformed headers, 64-character secure idempotency keys, error normalization, process-selection event contracts, successful and rejected Apex submission, double-submit prevention, timer/listener cleanup, all status/progress variants, terminal reset, validation summaries, history refresh/errors, expired results, and result-download event isolation.

## Scratch deployment gate

- **Timestamp:** 2026-08-12T03:48:18-05:00.
- **Actor/tool:** Salesforce CLI against the reused authorized scratch org.
- **Command:** full Core source deployment with all 13 project Apex test classes explicitly named.
- **Target:** verified active project scratch org.
- **Expected result:** LWC/Apex/metadata compile and all project tests pass without coverage warnings.
- **Observed result:** Passed. The final Step 7 deployment contained 123 source components; 64 project Apex tests passed with zero failures or coverage warnings (job `0AfG100000L6QmwKAF`).
- **Artifact:** ignored deployment response; sanitized summary recorded here.

## Performance and resilience contract

Browser preview is capped at 10 data rows and 20 configured columns; the complete file remains subject to Apex's 2 MB, 5,000-row, 100-column, and 32,000-character-cell validation. No full object description is sent to the browser. Submission is disabled while busy or offline, a secure idempotency key survives safe retries, Core v1 polling uses one cleared bounded timer because the approved product contract intentionally exposes no event contract, and disconnected components remove network listeners and timers.

The application now includes a dedicated `Bulk_Record_Upload` Lightning component tab in the application navigation and least-privilege user/admin permission sets. History polling calls a non-cacheable read boundary so terminal progress cannot remain stale behind an Apex client cache. All user-facing component text and validation/recovery messages resolve through explicit `BulkRecordUpload_*` Custom Labels; stable machine statuses remain untranslated.

The maximum-preview Jest case parses the product maximum of 5,000 rows and 100 columns, exposes only 10 rows and 20 source columns plus the row-number column, keeps the serialized view model below 10 KB, and completes inside the published 2-second local budget.

## Manual verification status

The repeatable procedure and evidence fields are defined in [the manual accessibility and runtime checklist](manual-accessibility-checklist.md).

- Keyboard-only, screen-reader, high-contrast, 200% zoom/reflow, and internal/Experience Cloud runtime scenarios: **Not run**. The in-app browser connection recovered, but the scratch-org page reached the Salesforce login screen because that browser has no authenticated session. A proposed credential-preserving localhost handoff was rejected by the safety reviewer, Chrome was unavailable, and no password or front-door token was exposed. This is recorded as missing evidence, not a pass.
- External documentation outage: structurally passed because no runtime documentation request or documentation-only LWC exists; interactive confirmation remains part of the manual scenario.

On 2026-08-12, the project owner explicitly directed the program to move past the remaining manual accessibility/runtime scenarios and revisit them at the end. This exception authorizes Steps 8–9 but does not convert missing evidence into a pass. Step 10 retains the deferred checklist as a release gate.
