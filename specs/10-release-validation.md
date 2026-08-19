# Step 10 — Release validation

## Goal

Produce reproducible evidence that the public release is installable, secure, supportable, and complete.

## Late product-contract clarification

On 2026-08-13, the owner clarified the selection contract further: `bulkRecordUpload` (named `bulkRecordUploadMultiProcess` before convergence step 05's rename) is the only exposed upload component. An administrator selects one active upload bundle in App Builder; `contextRecordId` and `contextObjectApiName` remain the only runtime context properties. Apex returns only active processes assigned to that bundle; one choice is selected automatically and hides the selector, while multiple choices display the selector. The component has no process or instruction override.

The App Builder bundle picker uses the FlexiPage object context. It lists only active bundles containing an active process compatible with that record-page object. Exactly one compatible bundle is selected by default; zero or multiple compatible bundles remain unselected. An unselected component renders a visible administrator configuration message and no upload controls.

## Runtime architectural principles — 2026-08-12

ADR-0006 applies the owner's seven principles in Bulk Record Upload terms. The
release contract centralizes hard ceilings, stable statuses, and package-defined
reason codes in `BulkRecordUploadRuntimeContract`; the Apex architecture gate checks
restricted status-picklist parity and rejects system-mode target-record query paths.
Narrow package-owned upload, chunk, and File orchestration remains system mode under
ADR-0004, while target business-record reads and writes remain user mode.

## Procedure

1. Confirm the single reusable scratch org is valid. Create a replacement only under `AGENTS.md` criteria and record the reason; use 30 days and Salesforce sample data.
2. From a clean clone/install, deploy or install the complete candidate including list views, assign least-privilege permissions, load deterministic seed data, and run all automated tests.
3. Run Code Analyzer and every CI gate against the exact release commit/artifact.
4. Exercise administrator setup and end-user flows for all supported operations, file/result lifecycle, partial/fatal failure, archive/retention, permission changes, and extension example.
5. Validate package upgrade from the oldest supported version and document rollback/recovery. Verify uninstall/data-retention behavior in an isolated supported path.
6. Validate against the approved persistent org only after scratch gates pass, using explicit target and verified instance URL. Prefer validation-only commands until release approval.
7. Inspect the final source/package/archive/SBOM and sign/tag only the verified commit.

## Scratch-org replacement record — 2026-08-12

Release-specific clean-install isolation requires replacing `sfdo826` with the
new 30-day scratch org `sfdo827`. The replacement is permitted by the repository's
release-isolation exception and supports a clean deployment, deterministic demo-data
seed, permission verification, and class-level coverage campaign after the public API
rename. `sfdo826` must be retired before `sfdo827` becomes the sole reusable project
scratch org. No persistent org is in scope for this replacement.

## Approved configuration contract version 2 — 2026-08-12

The owner approved replacing ambiguous append/prepend configuration with separate
administrator decisions: Existing Value Action, Blank CSV Action, Text Separator,
Duplicate Text Action, and Overflow Action. Append and Prepend are valid only for
text-like fields, use an explicit separator, handle duplicates deliberately, and
reject overflow instead of silently truncating. Version 2 also separates standard
DML, registered custom Apex processing, and registered post-processing actions.
Arbitrary administrator-entered class names remain prohibited.

Files remain Salesforce Files linked to the private `Bulk_Record_Upload__c` record.
Core creates no public links and hardcodes no Public Group. Subscribers may share
upload records through their own Public Groups and sharing rules; child chunks stay
controlled by parent and File access never bypasses record access.

## Record-page parent context — 2026-08-12

The one-process component treats Lightning record context as a first-class parent
use case. Each process explicitly selects no context, optional parent context, or
required parent context and declares both the allowed record-page object and target
relationship field. Apex validates Schema type, relationship compatibility, FLS,
record visibility, and the submitted ID before storing it. The asynchronous job
applies the verified relationship after CSV mapping and merging, so CSV content
cannot override the administrator-controlled parent.

## Review remediation — 2026-08-12

Version 1 and 2 processes are both listed. Staging now supports the documented
5,000-row ceiling at every allowed batch size, subject to the independent safe
serialized-chunk limit. The server rejects NUL characters. Completed chunks store
row outcome counts so finalization does not reparse generated CSV. Fatal jobs store
a bounded safe error code and message, and idempotent failure recovery no longer
depends on a forward-only transition from a particular intermediate state.
Production orchestration uses one Batch Apex job with a scope of one durable chunk,
so the 200-chunk maximum does not depend on the Developer/Trial Edition Queueable
chain-depth limit of five. Fatal failure counts roll up already completed chunks.

The final working-tree review also required UTF-8 BOM parity between the browser
preview and Apex parser, strict matching CSV quote grammars, transaction-scoped
describe hoisting in existing-value merging, bounded result fragments, and an
explicit durable failure outcome when business-record DML commits before result
reporting fails. Negative numeric result values retain their CSV round-trip value
while nonnumeric formula-like values remain guarded.

The release-isolation demo must also deploy and activate an Account record page
inside the Bulk Record Upload app. That page hosts `bulkRecordUpload` with
the upload component so the current Account supplies the validated `AccountId`
context. The complete demo setup assigns the Core user,
preview, delete, administrator, and target-object permission sets and reseeds
the deterministic Account, Contact, and Opportunity fixtures.

The multi-process selector must compare numeric Custom Metadata configuration
versions directly. `Set<Decimal>.contains()` did not match the runtime value
returned for `ConfigurationVersion__c`, which hid valid version 2 processes even
though their individual projections passed authorization and schema validation.

The open-source LWC must preserve the established user experience: compact card
header, Template action, Upload File/View Status toggle, centered file drop zone,
inline validation and confirmation, and a structured status view. This is a
clean-room implementation of the behavior and composition; project-owned labels,
SLDS styling, projection-based authorization, and bounded data handling remain the
source and security boundaries. Scratch deployment `0AfAw00000PEGuYKAX` passed
163/163 local Apex tests with no coverage warnings on 2026-08-12.

## Final gate

- [ ] Every prior step is closed with evidence and no deferred release blocker.
- [ ] Exact release commit passes clean-clone local, scratch, package, security, and documentation gates.
- [ ] Approved-org validation targets `https://sfdo-gk-dev-ed.develop.my.salesforce.com` and no other persistent org.
- [ ] Install, upgrade, rollback/recovery, and uninstall evidence is retained.
- [x] Published performance limits include the near-800-field benchmark.
- [x] All Apex/test classes are below 500 lines and common factory policy passes.
- [ ] Maintainer signs off on easy to maintain, scale, extend, and understand with linked evidence.
- [ ] Release notes distinguish supported, experimental, deprecated, and planned behavior.

Coverage note: the 2026-08-12 clean-org campaign increased tested-package Apex
coverage from 89% to 92% with 80/80 passing tests. Greater than 99% package-wide
coverage remains open; focused-test coverage is not substituted for the package
measurement.

Evidence: `docs/evidence/10-release-validation/` — partial. Scratch, local, analyzer, archive, benchmark, and approved-org metadata validation evidence is complete. Release remains blocked by disabled Dev Hub/package lifecycle, missing release commit, deferred interactive accessibility/screenshots, dependency legal review, and maintainer sign-off.
