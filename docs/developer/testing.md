# Test and verify changes

> [!NOTE]
> On this page, run the local and Salesforce checks that protect source, documentation, limits, permissions, and package behavior.

```powershell
npm ci
npm run check:all
npm audit --omit=dev
npm run sbom
```

For Salesforce changes, verify the explicit target, deploy the smallest complete scope with a dry run, run focused tests, then all 14 package test classes with coverage. Run Code Analyzer last. Shared-org `RunLocalTests` can include unrelated unmanaged code, so package evidence names every shipped test class.

The project reuses one 30-day scratch org from `config/project-scratch-def.json`, which requests sample data. Deploy the complete manifest, list views, and deterministic project seed assets. Replace the org only when expired, corrupted, incompatible, or demonstrably irrecoverable, and record the reason first.

After deploying Core, run `scripts/apex/seed-demo-data.apex` against the explicit
scratch-org alias. The script safely replaces only synthetic Accounts whose names
begin with `Bulk Upload Demo ` and verifies that exactly three seed records exist.
Deploy `examples/main/default` for the optional three-object demonstration kit,
then use the 12 operation-specific CSV files under `docs/examples/demo/` for
administrator and user walkthroughs. The kit supplies Insert, Update, Upsert,
and Delete processes for Account, Contact, and Opportunity.

## Related

See [CONTRIBUTING.md](../../CONTRIBUTING.md) and [RELEASING.md](../../RELEASING.md).
