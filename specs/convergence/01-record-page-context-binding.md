# Step 01 — Record page context binding

**Release blocker. Independent of every other step. Do this first.**

## Goal

Make the exposed component actually receive the record it is placed on, so
processes configured with `RecordContextAction__c = REQUIRE_PARENT` work.

## Why

`bulkRecordUploadMultiProcess` declares `@api contextRecordId`
(`bulkRecordUploadMultiProcess.js:23`) and sends it to Apex
(`bulkRecordUploadMultiProcess.js:236`). But Lightning injects **`recordId`** on a
record page, not `contextRecordId`, and nothing declares or binds
`contextRecordId` in `targetConfigs`. There is no Aura wrapper — `aura/` is
empty. The property is therefore `undefined` in every deployed placement.

The server side is correct and complete:
`BulkRecordUploadRecordContextService.validateContext` validates type and
user-mode visibility, and `applyContext` stamps the parent after CSV mapping.
Only the wire from the page to the component is missing. A `REQUIRE_PARENT`
process fails today on the record page it was designed for.

This is a defect in shipped behavior, not a new feature. It does not depend on
the thesis in step 02 and must not wait for the rest of the program.

## Preconditions

None.

## Must not change

- The server-side validation and stamping contract in
  `BulkRecordUploadRecordContextService`. This step adds no Apex behavior.
- `contextRecordId` and `contextObjectApiName` remain public. They are named in
  the Step 7 product contract and are the Experience Cloud binding surface.
  This step _adds_ the platform properties; it removes nothing.

## Work

1. Add `@api recordId` and `@api objectApiName` to
   `bulkRecordUploadMultiProcess`.
2. Resolve effective context once, in a single getter, as
   `recordId ?? contextRecordId` (and the same for object API name). Every
   consumer reads the getter, not the raw properties, so there is one precedence
   rule in one place.
3. Declare `contextRecordId` and `contextObjectApiName` as
   `lightningCommunity__Default` `targetConfig` properties so Experience Cloud
   pages can bind `{!recordId}`. Without the declaration the community target
   receives nothing.
4. Send the resolved value in the submit request exactly as today.

## Verification

Independently checkable without the rest of the program:

- [ ] Jest: with only `recordId` set, the submit request carries it.
- [ ] Jest: with only `contextRecordId` set, the submit request carries it.
- [ ] Jest: with both set, `recordId` wins, asserted on the documented precedence.
- [ ] Jest: with neither set, the request carries null and no error is thrown for
      a `DEFAULT_PARENT` or `NONE` process.
- [ ] Manual, in the scratch org: a `REQUIRE_PARENT` process on a host record
      page completes an upload and the created records carry the parent in
      `RecordContextFieldApiName__c`. Screenshot or query output recorded.
- [ ] Manual: the same process on an App page is blocked with a stated reason
      rather than failing at submit or silently uploading orphans.
- [ ] `targetConfigs` change deploys cleanly and the properties are visible in
      Experience Builder.

## Exit gate

- [ ] All verification items above pass with recorded evidence.
- [ ] No Apex changed.
- [ ] ESLint, Prettier, and Jest pass.
- [ ] Evidence recorded at `docs/evidence/convergence/01/`.

## Rollback

Single-component change with no Apex or metadata-model impact. Revert the
component and its `js-meta.xml`.
