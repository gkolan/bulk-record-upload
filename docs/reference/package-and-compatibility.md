# Package and compatibility

> [!NOTE]
> On this page, understand the current source distribution and the planned package versioning, upgrade, and uninstall contracts.

## What ships

The current project installs from source; no promoted package version is available. The planned distribution is a no-namespace second-generation unlocked package. Production metadata lives under `force-app/`; demo configuration in `examples/main/default` is a separate optional deployment. Deploy the supplied Account demo page from `examples/pages/main/default` after that configuration exists; the optional bundle assigns it only to the Bulk Record Upload app. Follow [Install from source](../get-started/install.md) for the current installation path.

## Versioning

The product's version number (for example `1.2.3`) maps directly to a Salesforce package version—while a new version is being built, it's tracked as `1.2.3.NEXT`; once it's promoted (released), that exact package version becomes permanent and unchangeable. This Day-1 line has no supported predecessor and therefore no upgrade path. A future release must declare and validate its own supported path from the immediately preceding promoted version.

The status values and results CSV schema are explicit public contracts. Process configuration uses one current metadata shape; it has no administrator-selectable compatibility version. Persistence and field merging are package-owned. After the first promoted release, removing or renaming a field, changing what a value means, or making something newly required is a breaking change and requires a new major version with migration guidance.

## Before you uninstall

Export anything you need to keep — logs, upload history, result files — before uninstalling the package. Uninstalling can remove package-owned records and the links between them; exactly what's removed for a given promoted version is documented as part of that release's own validation.

## Related

- [Product contract](product-contract.md)
- [Unsupported features](unsupported-features.md)
