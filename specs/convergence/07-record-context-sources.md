# Step 07 — Record context sources

Supersedes the earlier draft at `specs/11-record-context-sources.md`, which is
deleted as part of this program. One spec per subject.

## Goal

Let an upload process obtain its parent record when no record page supplies one,
so the same configured process runs unchanged on an app page, home page, tab, or
Experience Cloud page.

There is exactly one parent-selection control — `lightning-record-picker` —
configured from custom metadata. An administrator who understands "which object,
which fields do users search on, which fields do they see, which records are
eligible" has understood the whole feature.

## Why last

This step adds configuration. It runs after the program has removed a duplicated
configuration mechanism (step 03) and recorded the predictability rule (step 02),
so the new settings are added to a package that has just finished proving it
knows how to avoid a second `ValueHandling__c`.

## Preconditions

Steps 01, 03, and 06 complete. Step 01 supplies working page context, which this
step builds on rather than duplicates.

## Must not change

- The server-authoritative context contract. `validateContext` still checks type
  and user-mode visibility, and `applyContext` still stamps the parent after CSV
  mapping so a CSV column can never set it.
- `RecordContextAction__c` semantics — `NONE`, `DEFAULT_PARENT`,
  `REQUIRE_PARENT` — are unchanged. This step adds an orthogonal axis, not a
  replacement.
- The compact projection budget. No host object describe reaches the browser.

## Design

### One control

`lightning-record-picker` is the only chooser. An earlier draft rendered a
combobox for curated ID lists and a picker otherwise; the second shape bought
nothing and doubled the template branches, the accessibility surface, and the
test matrix. Curated lists are expressed as a filter on the one picker instead.

Choosing the platform component over a hand-built autocomplete also removes work
the package would otherwise own forever: it enforces sharing, queries through the
platform rather than through package Apex — so candidate search costs no SOQL and
no governor headroom regardless of host object size — and carries keyboard and
screen-reader behavior that would otherwise need certifying every release.

### Four metadata fields, one convention

| Field                            | Maps to                          | Purpose                        |
| -------------------------------- | -------------------------------- | ------------------------------ |
| `HostObjectApiName__c` (exists)  | `object-api-name`                | Which object users pick from   |
| `ContextSearchFields__c` (new)   | `matching-info`                  | What the user's typing matches |
| `ContextDisplayFields__c` (new)  | `display-info`                   | What the user sees in results  |
| `ContextFilterCriteria__c` (new) | `filter` plus server enforcement | Which records are eligible     |

Both field lists use one convention: **a comma-separated list of field API names
where the first entry is the primary field and the rest are additional fields.**
One convention, one parser, one validation routine, one sentence of docs.

Both may be blank, defaulting to the host object's name field. An administrator
who sets only `HostObjectApiName__c` gets a working picker. The other fields
improve the default rather than enabling it.

Search fields must be searchable and display fields readable, both resolved
through `Schema` describe against the host object at configuration load and
rejected with an admin-actionable message otherwise. The platform caps additional
matching and display fields — confirm the current cap for API 67.0 and enforce it
in the same validation rather than letting the picker fail at render.

One detail worth pinning because it is silent when wrong: `matching-info` takes
field _objects_ (`{ fieldPath: 'Name' }`) while `display-info` takes plain
_strings_ (`'Name'`). The shared parser produces a field-name list; the two
adapters that shape it live next to each other and are covered by tests asserting
the exact shapes.

### `RecordContextSource__c`

New picklist, required when `RecordContextAction__c != 'NONE'`, default `PAGE`:

| Value         | Behavior                                                           |
| ------------- | ------------------------------------------------------------------ |
| `PAGE`        | The parent comes only from the host record page. Current behavior. |
| `USER_CHOICE` | When no page context is present, the picker is shown.              |

Page context always wins. Under `USER_CHOICE`, a component on a valid host record
page uses the page record and renders no picker, so one process definition serves
both placements.

### Filter criteria, and where enforcement lives

`ContextFilterCriteria__c` holds a structured, validated filter, not a free-text
SOQL fragment: field/operator/value triples, each field resolved through describe
against `HostObjectApiName__c` and rejected unless filterable and readable, with
values bound as parameters.

It is applied twice, deliberately. **In the picker**, so ineligible records never
appear — convenience. **In Apex**, re-applied inside `validateContext`, so a
caller bypassing the LWC is still rejected — the guarantee. Neither is sufficient
alone and the spec never treats the first as the second.

The grammar includes `Id IN (...)`, which makes a curated allowlist a special case
of the filter rather than a separate feature.

### No new App Builder property

An earlier draft proposed `@api contextRecordIds` for per-page narrowing. It is
**dropped**. Everything it served is expressible in `ContextFilterCriteria__c`,
where the server can enforce it. Keeping it would give the package two
configuration homes with different trust levels that administrators must learn to
tell apart — the same confusion `ValueHandling__c` causes today, in a new place.

The App Builder surface stays at `bundleDeveloperName` plus platform context
properties, and Step 7's "no App Builder override" contract stands unamended.

### Carrying context through the projection

`BulkRecordUploadProjection
` already has two telescoping constructors, the
second taking thirteen positional arguments. Threading four more settings through
that chain makes the most-touched configuration type in the package harder to
read with every future setting.

Context configuration is therefore a single
`BulkRecordUploadContextProjection
` value object held as one property. A later
picker setting becomes a field on a small focused type, not another overload.
`configHash` continues to version the cached projection and the new settings
participate in it.

## Work

1. Add `RecordContextSource__c`, `ContextSearchFields__c`,
   `ContextDisplayFields__c`, and `ContextFilterCriteria__c`.
2. Add `BulkRecordUploadContextProjection
`, attach it to the projection as one
   property, and include the new settings in `configHash`.
3. Add `BulkRecordUploadContextSourceService` for field-list parsing,
   describe-based validation, and filter parsing.
4. Extend `validateContext` with server-side filter enforcement.
5. Render the picker with a staging lock — disabled once a file is staged, so the
   parent cannot change under a preview validated against a different parent —
   and a `REQUIRE_PARENT` empty state that blocks file selection with a stated
   reason rather than failing at submit.
6. Clear the chosen parent when the selected process changes.
7. Extend `BulkRecordUploadTestDataFactory` with context fixtures.
8. Document the four settings, the shared convention, and the blank defaults.
9. Add manifest entries and permission-set field visibility.

## Verification

- [ ] A process with only `HostObjectApiName__c` set renders a working picker
      searching and displaying the name field, proving the zero-config default.
- [ ] `matching-info` receives field objects and `display-info` receives strings,
      asserted on exact shapes.
- [ ] Non-searchable search fields, unreadable display fields, and non-existent
      fields each fail configuration validation with admin-actionable messages.
- [ ] Exceeding the platform cap on additional fields fails validation rather
      than at render.
- [ ] A client-supplied ID outside `ContextFilterCriteria__c` is rejected
      server-side, proven by a test that bypasses the LWC.
- [ ] An `Id IN (...)` filter rejects a visible non-member.
- [ ] A record invisible to the running user is neither offered nor accepted.
- [ ] `REQUIRE_PARENT` under `USER_CHOICE` blocks file selection until a parent is
      chosen.
- [ ] Changing the process clears the chosen parent.
- [ ] No host object describe reaches the browser; the large-schema budget passes.
- [ ] `configHash` changes on any context setting change; cache miss,
      invalidation, and size-bound paths are tested.
- [ ] Accessibility automation passes for the picker; keyboard-only traversal from
      picker to file input to submit is recorded.

## Exit gate

- [ ] All verification items pass with recorded evidence.
- [ ] `specs/11-record-context-sources.md` is deleted and the program overview no
      longer lists it.
- [ ] No class exceeds 450 lines.
- [ ] Every new setting satisfies ADR-0007's predictability rule, stated
      per-field in the evidence.
- [ ] Evidence recorded at `docs/evidence/convergence/07/`.

## Open question for the project owner

**Cross-object parents.** The design assumes one host object per process.
Attaching one CSV to either an Account or an Opportunity needs a second host
object per process and is deliberately out of scope.
