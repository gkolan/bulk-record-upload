# Release process

> [!NOTE]
> On this page, validate, package, rehearse, and promote an immutable Bulk Record Upload release with retained evidence.

1. Review the candidate's supported behavior and open items in [Project status](docs/project-status.md), then update `CHANGELOG.md`.
2. Run `npm ci`, `npm run check:all`, `npm audit --omit=dev`, and `npm run sbom`.
3. Verify the authorized org immediately before every Salesforce command.
4. Validate and deploy `manifest/package.xml`; run all package Apex tests and Code Analyzer last.
5. Create a four-part unlocked package version from `MAJOR.MINOR.PATCH.NEXT`.
6. In an isolated supported scratch org, rehearse fresh install, upgrade from the prior promoted version, recovery, and uninstall/data retention.
7. Inspect the package artifact for ignored inputs, generated output, secrets, test-only fixtures, and deferred integration claims.
8. Retain sanitized verification artifacts with the candidate pull request or release. Promote only after the listed checks and maintainer review are complete, then tag the matching semantic version and publish release notes and the SBOM.

Promoted Salesforce package versions are immutable. Recovery uses a separately created corrective version; destructive metadata changes require a migration and deprecation path.

## Related

See [Package and compatibility](docs/reference/package-and-compatibility.md) and [Contributor testing](docs/developer/testing.md).
