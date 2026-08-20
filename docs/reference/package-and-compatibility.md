# Package and compatibility

> [!NOTE]
> On this page, understand how this unlocked package installs, upgrades, and versions its public contracts — and what changing versions means for your org.

## What ships

Bulk Record Upload is a no-namespace second-generation unlocked package. Everything under `force-app/` is the actual customer package — the demo kit (`examples/`) and integration test fixtures are separate, optional deployments, not something the package depends on or installs automatically.

## Versioning

The product's version number (for example `1.2.3`) maps directly to a Salesforce package version — while a new version is being built, it's tracked as `1.2.3.NEXT`; once it's promoted (released), that exact package version becomes permanent and unchangeable. Every supported upgrade path is validated starting from the immediately preceding promoted version, so upgrades happen one step at a time, not by skipping around.

Four things each get their own, independently-changing version number: the process configuration format, the processor Apex, the status values, and the results CSV file format. A newer version of one doesn't force a newer version of the others. Within one version of any of these, new optional fields can be added freely — existing code that doesn't recognize a new field just ignores it. Removing a field, renaming it, changing what a value means, or making something newly required is a breaking change and requires a new major version, with migration guidance published alongside it.

## Before you uninstall

Export anything you need to keep — logs, upload history, result files — before uninstalling the package. Uninstalling can remove package-owned records and the links between them; exactly what's removed for a given promoted version is documented as part of that release's own validation.

## Related

- [Product contract](product-contract.md)
- [Unsupported features](unsupported-features.md)
