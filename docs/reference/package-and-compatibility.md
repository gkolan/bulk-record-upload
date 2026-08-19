# Package and compatibility

> [!NOTE]
> On this page, understand how the unlocked package installs, upgrades, separates examples, and versions public contracts.

Bulk Record Upload ships as a no-namespace second-generation unlocked package. `force-app/` is the customer package. Examples and integration fixtures require separate explicit deployment and are not customer dependencies.

Product semantic versions map to Salesforce package versions: `1.2.3` uses `1.2.3.NEXT` while a candidate is created. Promoted versions are immutable. Each supported upgrade validates from the preceding promoted ancestor.

Configuration DTOs, handlers, statuses, and result CSVs each version independently. Version 1 consumers ignore unknown optional fields. Removing, renaming, changing a field's meaning, or adding a required value needs a major contract version and migration guidance.

Before uninstalling, export required logs and files. Uninstall may remove package-owned records or links; release validation documents the observed behavior for the promoted version.

## Related

- [Product contract](product-contract.md)
- [Unsupported features](unsupported-features.md)
