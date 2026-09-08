# Project status

> [!NOTE]
> On this page, check the project's development status and the work needed before a production release.

## Active development

Bulk Record Upload is available from source for development and evaluation. Features and
configuration can change, and updates can break existing setups. There is no promoted Salesforce
package or one-click package installer. Use the [quick start](get-started/quick-start.md) in a
dedicated development org with synthetic data.

## Before a production release

The Day-1 source candidate has passed repeated validation and deployment in its dedicated scratch
org. The current connected run passed all 232 local Apex tests with 89.41% org-wide coverage. The
same tree passed 55 LWC tests, the 345-file Core source/manifest checks, generated-demo parity for
79 files, the 800-field projection benchmark, release/sensitive-data boundary checks, and the
recommended Salesforce Code Analyzer rules with zero violations. Least-privilege, cross-user File
privacy, identifier injection, formula safety, retry/recovery, retention, and repeat-safe schedule
repair are included in that automated evidence. These results establish the automated source build
baseline; they do not replace the hands-on and package-lifecycle checks below.

These checks remain required; this page does not certify that they have passed:

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
