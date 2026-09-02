# Project status

> [!NOTE]
> On this page, check the project's development status and the work needed before a production release.

## Active development

Bulk Record Upload is available from source for development and evaluation. Features and
configuration can change, and updates can break existing setups. There is no promoted Salesforce
package or one-click package installer. Use the [quick start](get-started/quick-start.md) in a
dedicated development org with synthetic data.

## Before a production release

These checks remain required; this page does not certify that they have passed:

- Run local checks, Salesforce Code Analyzer, deployment validation, and the complete project
  Apex test suite against the exact release candidate.
- Have someone follow the installation and first-upload instructions in a fresh supported org.
- Complete hands-on keyboard, screen-reader, zoom, and supported-page accessibility review.
- Create and validate the package installation and removal paths, with upgrade and recovery
  verification where applicable. Source deployment alone does not establish package readiness.
- Complete dependency/license review and maintainer sign-off.

See the [testing guide](developer/testing.md) and [release process](../RELEASING.md) for verification.
Local planning files and historical review reports are not required to install or contribute to
the public repository. Release verification should be attached to the relevant pull request or
release, with sensitive output removed.

## Scope and proposals

The [README](../README.md) explains current functionality and limits. [Unsupported features](reference/unsupported-features.md)
and the [roadmap](roadmap.md) distinguish current behavior from proposed additions.
