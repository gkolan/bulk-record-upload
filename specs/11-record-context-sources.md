> **Superseded.** This draft is replaced by
> [`specs/convergence/07-record-context-sources.md`](convergence/07-record-context-sources.md),
> which is authoritative. Kept only until step 07 deletes it. Do not implement from this file.

# Step 11 — Record context sources

## Goal

Let an upload process obtain its parent record from somewhere other than the
Lightning record page, so the same configured process runs unchanged on an app
page, home page, tab, or Experience Cloud page.

There is exactly one parent-selection control — `lightning-record-picker` —
configured by custom metadata. An administrator who understands "which object,
which fields do users search on, which fields do they see" has understood the
entire feature.

## Current state

`Bulk_Record_Upload_Process__mdt` already carries `HostObjectApiName__c`,
`RecordContextFieldApiName__c`, and `RecordContextAction__c`
(`NONE` / `DEFAULT_PARENT` / `REQUIRE_PARENT`).
`BulkRecordUploadRecordContextService` validates the submitted ID for type and
user-mode visibility, then stamps it onto every mapped row after CSV mapping, so
a CSV column can never override it. That contract is correct and unchanged.

Two gaps make it unusable off a record page, and one makes it unreliable **on**
a record page:

1. `bulkRecordUploadMultiProcess` exposes `@api contextRecordId`, but the
   platform injects `recordId` on a Lightning record page. Nothing declares or
   binds `contextRecordId`, so it is `undefined` in every deployed context.
   A `REQUIRE_PARENT` process therefore fails today even on the record page it
   was designed for. This is a defect, not a new feature, and it is fixed first.
2. There is no configured way for a user to _choose_ a parent when no record
   page supplies one.
3. There is no way for an administrator to narrow which parents are offered.

## Design

### One control, one mental model

`lightning-record-picker` is the only chooser. It is not one option among
several — an earlier draft rendered a combobox for curated ID lists and a picker
otherwise, and that second shape bought nothing while doubling the template
branches, the accessibility surface, and the test matrix. Curated lists are
expressed as a _filter on the one picker_ instead, so there is one control to
learn, document, style, and certify.

Choosing the platform component over a hand-built autocomplete also removes work
this package would otherwise own forever: the picker enforces sharing, queries
through the platform rather than through package Apex, and carries keyboard and
screen-reader behavior that would otherwise need building and re-certifying at
every release.

### Configuring the picker from custom metadata

Four fields on `Bulk_Record_Upload_Process__mdt` describe the picker. Three are
new; `HostObjectApiName__c` already exists and keeps its meaning.

| Field                      | Maps to                       | Purpose                                         |
| -------------------------- | ----------------------------- | ----------------------------------------------- |
| `HostObjectApiName__c`     | `object-api-name`             | Which object users pick from.                   |
| `ContextSearchFields__c`   | `matching-info`               | Which fields the user's typing matches against. |
| `ContextDisplayFields__c`  | `display-info`                | Which fields the user sees in results.          |
| `ContextFilterCriteria__c` | `filter` + server enforcement | Which records are eligible.                     |

Both field-list settings use one convention: **a comma-separated list of field
API names, where the first entry is the primary field and the rest are
additional fields.** One convention, one parser, one validation routine, one
sentence of documentation.

Both may be left blank. When blank, each defaults to the host object's name
field. An administrator who sets only `HostObjectApiName__c` gets a working
picker that searches and displays the record name — the zero-configuration path
is the common case, and the other fields exist to improve it, not to enable it.

`ContextSearchFields__c` fields must be searchable; `ContextDisplayFields__c`
fields must be readable. Both are resolved through `Schema` describe against the
host object at configuration load and rejected with an admin-actionable message
otherwise. The platform caps the number of additional matching and display
fields — confirm the current cap for API 67.0 and enforce it in the same
validation rather than letting the picker fail at render time.

One implementation detail is worth pinning in the spec because it is easy to get
wrong and silent when wrong: `matching-info` takes field _objects_
(`{ fieldPath: 'Name' }`) while `display-info` takes plain _strings_
(`'Name'`). The shared parser produces a field-name list; the two adapters that
shape it for the picker live next to each other and are covered by tests that
assert the exact object shapes.

### Filter criteria, and where enforcement lives

`ContextFilterCriteria__c` (Long Text) holds a structured, validated filter, not
a free-text SOQL fragment: field/operator/value triples, each field resolved
through describe against `HostObjectApiName__c` and rejected unless filterable
and readable, with values bound as parameters. This follows the existing
invariant that dynamic identifiers resolve through describe and trusted
allowlists, never through administrator text used directly.

It is applied in two places, deliberately:

- **In the picker**, translated to the component's `filter` object, so ineligible
  records never appear.
- **In Apex**, re-applied inside `validateContext`, so a caller that bypasses the
  LWC entirely is still rejected.

The client application is convenience. The server application is the guarantee.
Neither is sufficient alone and the spec never treats the first as the second.

The grammar includes `Id IN (...)`, which is what makes a curated allowlist a
special case of the filter rather than a separate feature.

### `RecordContextSource__c`

New picklist, required when `RecordContextAction__c != 'NONE'`, default `PAGE`:

| Value         | Behavior                                                           |
| ------------- | ------------------------------------------------------------------ |
| `PAGE`        | The parent comes only from the host record page. Current behavior. |
| `USER_CHOICE` | When no page context is present, the picker is shown.              |

Page context always wins. Under `USER_CHOICE`, a component hosted on a valid host
record page uses the page record and renders no picker, so one process
definition serves both placements instead of requiring two near-duplicates.

This answers the original request's options 2 and 3 as one mechanism:
"admin sets the object and the user picks" is `USER_CHOICE` with no filter, and
"admin curates the candidates" is `USER_CHOICE` with one.

### What stays `@api`

The `@api` surface stays deliberately small, and the rule from the previous
revision still decides it: a value belongs in metadata when a fabricated request
changing it would break a guarantee, and in `@api` when two legitimate
placements would want different values.

| Setting                                                       | Home                                                                                                                             |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `recordId`, `objectApiName`                                   | `@api` — platform-injected page context                                                                                          |
| `contextRecordId`, `contextObjectApiName`                     | `@api` — Experience Cloud `{!recordId}` bindings, which the community target does not receive unless declared in `targetConfigs` |
| `bundleDeveloperName`                                         | `@api`, already exists — narrows which processes a page offers                                                                   |
| `contextRecordIds`                                            | `@api`, optional — narrows the picker on one page                                                                                |
| Object, search fields, display fields, filter, action, source | metadata                                                                                                                         |

`contextRecordIds` remains a comma-separated App Builder string, capped at 50,
but it no longer selects a different control. It contributes one `Id IN (...)`
criterion to the picker's filter. It is **presentation scope, never access
control**: the server cannot verify that a submitted ID came from a FlexiPage,
so removing the property must widen what is offered and change nothing about
what is permitted. An administrator who needs the narrowing enforced puts the
same constraint in `ContextFilterCriteria__c`, where the server can see it.

### Carrying context through the projection

`BulkRecordUploadProjectionV1` already has two telescoping constructors, the
second taking thirteen positional arguments. Threading four more context
settings through that chain would make the most-touched configuration type in
the package harder to read with every future setting.

Context configuration is therefore introduced as a single
`BulkRecordUploadContextProjectionV1` value object — object name, search fields,
display fields, parsed filter, action, source — held as one property. Adding a
picker setting later means adding a field to a small focused type, not another
constructor overload. `configHash` continues to version the cached projection,
and the new settings participate in it so a configuration change invalidates the
cache.

### Meeting the four invariants

- **Understandable.** One control. One field-list convention used twice. A
  working default when everything optional is blank.
- **Maintainable.** One parser and one describe-validation routine for both field
  lists. Platform component ownership of search, sharing, and accessibility.
  Context settings isolated in one value object instead of a constructor chain.
- **Scalable.** The picker queries through the platform, so candidate search
  costs the package no SOQL, no Apex, and no governor headroom regardless of host
  object size. Only configured fields are ever described, honoring the
  800-field constraint.
- **Extensible.** New picker capabilities attach to one value object and one
  metadata group. The filter grammar is the single place record eligibility is
  expressed, so `Id IN (...)`, ownership rules, and status rules all arrive
  through the same reviewed path.

### Client contract

- Add `@api recordId` and `@api objectApiName`, resolving effective context as
  `recordId ?? contextRecordId`. `contextRecordId` and `contextObjectApiName`
  remain public for the Step 7 contract and Experience Cloud bindings.
- The picker renders between the process selector and the file input, and is
  disabled once a file is staged, so the parent cannot change under a preview
  validated against a different parent.
- `REQUIRE_PARENT` blocks file selection until a parent is chosen, with the
  reason in the empty state rather than only on submit.
- Changing the selected process re-reads that process's context configuration and
  clears any previously chosen parent.
- The LWC receives only the compact context projection. No host object describe
  crosses to the browser.

## Work

1. Fix the record-page defect: bind `recordId`/`objectApiName`, declare the
   Experience Cloud context properties, cover both placements in Jest.
2. Add `RecordContextSource__c`, `ContextSearchFields__c`,
   `ContextDisplayFields__c`, and `ContextFilterCriteria__c` to
   `Bulk_Record_Upload_Process__mdt`.
3. Add `BulkRecordUploadContextProjectionV1` and attach it to
   `BulkRecordUploadProjectionV1` as one property; include the new settings in
   `configHash`.
4. Add `BulkRecordUploadContextSourceService` for field-list parsing,
   describe-based validation, and filter parsing.
5. Extend `validateContext` with server-side filter enforcement.
6. Render `lightning-record-picker` with the staging lock and the
   `REQUIRE_PARENT` empty state; adapt the projection to `matching-info`,
   `display-info`, and `filter`.
7. Extend `BulkRecordUploadTestDataFactory` with context configuration fixtures;
   no test class creates them inline.
8. Document the four settings, the shared field-list convention, the blank
   defaults, and — prominently — that `contextRecordIds` is presentation scope
   while `ContextFilterCriteria__c` is enforcement.
9. Add manifest entries and permission-set field visibility for the new fields.

## Verification and exit gate

- [ ] Applicable Salesforce metadata, Apex, and LWC skills were followed and recorded.
- [ ] A `REQUIRE_PARENT` process succeeds on a record page and is blocked, with a stated reason, on an app page with source `PAGE`.
- [ ] A process with only `HostObjectApiName__c` set renders a working picker that searches and displays the name field, proving the zero-configuration default.
- [ ] `matching-info` receives field objects and `display-info` receives strings, asserted on exact shapes.
- [ ] Search fields that are not searchable, display fields that are not readable, and non-existent fields all fail configuration validation with admin-actionable messages.
- [ ] Exceeding the platform cap on additional matching or display fields fails validation rather than failing at render.
- [ ] A client-supplied ID outside `ContextFilterCriteria__c` is rejected server-side, proven by a test that bypasses the LWC.
- [ ] An `Id IN (...)` filter rejects a visible non-member, proving the enforced-allowlist path.
- [ ] A client-supplied ID absent from `contextRecordIds` but visible and passing the filter is **accepted**, proving the property is scope and not access control.
- [ ] A record invisible to the running user is neither offered by the picker nor accepted if submitted.
- [ ] No host object describe or unbounded field set reaches the browser; the Step 8 large-schema budget still passes.
- [ ] `configHash` changes on any context setting change; cache miss, invalidation, and size-bound paths are tested.
- [ ] Accessibility automation passes for the picker state; keyboard-only traversal from picker to file input to submit is recorded.
- [ ] Every Apex file remains under 450 lines.

Evidence: `docs/evidence/11-record-context/README.md`

## Open questions for the project owner

1. **Step 7 contract.** Step 7 item 9 states the exposed LWC has "only the
   standard Lightning record-context public properties" and "accepts no App
   Builder process or instruction override." `contextRecordIds` is neither a
   process nor an instruction override, but it is a new App Builder property, so
   item 9 needs amending rather than reinterpreting. If the appetite for App
   Builder surface is zero, drop `contextRecordIds` entirely — every deployment
   it serves can be expressed in `ContextFilterCriteria__c`, at the cost of a
   deploy to change one page's narrowing.
2. **Cross-object parents.** One host object per process. Attaching one CSV to
   either an Account or an Opportunity needs a second host object per process and
   is deliberately out of scope.
3. **Step placement.** The record-page defect in item 1 of _Current state_ breaks
   `REQUIRE_PARENT` on record pages today and is arguably a Step 10 release
   blocker on its own. It may need splitting out and fixing there, independent
   of the rest of this step.
