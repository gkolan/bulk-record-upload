# Step 5 — Core metadata and permissions

## Goal

Create portable metadata with clear descriptions, help text, ownership, and least privilege.

## Work

1. Implement configuration metadata, upload log, stable status/value sets, Files relationship strategy, permission sets, custom permissions, app/tab/page surfaces, and required list views.
2. Use project-owned names and terminology; preserve API names only when approved as public contracts.
3. Add descriptions and useful inline help within current Metadata API limits.
4. Separate core metadata from examples and test data. Use `artifacts/deferred-integrations.md` as the single source for unfinished integrations. Do not create fields, picklist values, Custom Metadata, permissions, tabs, UI controls, events, or examples for a deferred item unless Step 2 first changes its status to supported and updates the product contract.
5. Generate explicit manifests and automated completeness checks.
6. Define field history/audit, sharing, external-user, and retention behavior without granting broad Modify All Data.
7. Build a metadata-reference graph. Every API name referenced by Apex, LWC, Flow, Custom Metadata records, layouts, FlexiPages, permission sets, profiles, manifests, scripts, and documentation must resolve to source in the correct core/example/test/integration boundary or to an explicitly documented Salesforce standard component.
8. Require source completeness for Custom Permissions, Custom Labels, Flows, events, objects/fields, record types, value sets, applications/tabs, Apex classes, and permission grants. A text field containing an API name, such as a preview Custom Permission, does not excuse the referenced component from source ownership or an explicit subscriber-supplied contract.

## Verification and exit gate

- [x] Applicable metadata context/generation skills were followed and recorded.
- [x] Complete metadata deploy validates in the one scratch org, including list views.
- [x] Permission sets deploy and least-privilege assignment tests pass.
- [x] Metadata descriptions/help/names pass automated length and terminology checks.
- [x] Example and test-only records are absent from core manifest.
- [x] A metadata-to-deferred-integrations comparison proves no deferred feature has entered the core manifest.
- [x] The metadata-reference graph has no unresolved project-owned dependency and no accidental dependency on metadata that exists only in the development org.
- [x] Every subscriber-supplied reference has validation, failure guidance, an allowed-value boundary, and a portability test.
- [x] Fresh install and destructive-change preview are reviewed.
- [x] Metadata remains maintainable, additive at scale, separable by package, and understandable in Setup.

Evidence: [`docs/evidence/05-metadata-and-permissions/`](../docs/evidence/05-metadata-and-permissions/README.md) — _complete_
