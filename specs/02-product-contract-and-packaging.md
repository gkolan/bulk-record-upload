# Step 2 — Product contract and packaging

## Goal

Define the supported product before implementation so subscribers receive stable, portable behavior.

## Decision deadline

Approve `decisions/ADR-0001-packaging-strategy.md` before defining public API names, creating deployable metadata, or beginning Step 3. The ADR must decide 2GP managed versus unlocked packaging, namespace ownership, ancestor/version policy, dependency boundaries, installation and upgrade model, and how examples are distributed. If the decision cannot be approved, Step 2 stops; later steps do not assume an unpackaged fallback.

## Work

1. Decide 2GP managed versus unlocked packaging, namespace strategy, semantic versioning, ancestor/upgrade policy, and supported Salesforce releases/editions.
2. Define core, examples, test fixtures, and optional integration package boundaries. Example/test metadata must not pollute core.
3. Define supported operations, CSV encoding/dialect, maximum bytes/rows/columns/cell length, concurrency, status lifecycle, cancellation/retry/idempotency, retention, and result format.
4. Version the configuration DTO, handler contract, event contract, and results CSV schema independently.
5. Define compatibility rules for adding/removing fields, behaviors, statuses, metadata, and Apex interfaces.
6. Specify installation, permission assignment, configuration, upgrade, rollback, uninstall, and data-retention expectations.
7. Explicitly label deferred integrations as unsupported and remove inactive controls from core until implemented.
8. Treat long-form guidance as repository documentation rather than deployable Lightning metadata. Do not migrate `bulkRecordUploadGuide`; define stable documentation URLs and keep only concise, task-specific help in the application.
9. Complete the target-decision columns in `artifacts/behavior-parity-matrix.md`. Each intentional difference requires rationale, compatibility and migration impact, security impact, documentation changes, and acceptance tests.
10. Approve the dispositions in `artifacts/research-to-production-map.md` against the selected package boundaries. A proposed production owner must be a responsibility, not merely the old class name.
11. Approve `artifacts/deferred-integrations.md` as the single list of unsupported or future integrations. Steps 5 and 9 reference this file rather than maintaining separate lists.
12. Approve a public naming and collision policy before choosing API names. Use a project/namespace prefix for unpackaged or unlocked global names; avoid generic names such as `GlobalPlatformEventHandler`; check Apex, LWC, object, field, event, permission, label, tab, application, and Custom Metadata names against standard Salesforce names, package dependencies, and likely subscriber metadata. Record unavoidable public-name compatibility commitments.
13. Approve the API-version policy. Record the current development version (`67.0` at planning time), the minimum supported subscriber release, when the source API version may advance, how preview releases are handled, and which deploy/package/test matrix proves compatibility. Do not raise the version only because a local CLI supports it.

## Edge cases

Namespaced/unmanaged installs; standard/custom objects; Person Accounts; compound/encrypted/geolocation/address fields; polymorphic references; multi-currency; translated labels; restricted picklists; duplicate labels; inactive/deleted fields; package upgrades with stored config; locales/time zones; Experience Cloud users; and orgs with automation-heavy objects.

## Verification and exit gate

- [x] Architecture decision records approve packaging and public contracts.
- [x] `decisions/ADR-0001-packaging-strategy.md` is approved before any deployable metadata or public API name is created.
- [x] A manifest/package-boundary check proves every component appears exactly where intended.
- [x] A compatibility matrix covers fresh install, upgrade, uninstall, and namespace behavior.
- [x] Limits and unsupported features are visible to administrators and developers.
- [x] Each public contract has one canonical reference and one working example.
- [x] The package contains no long-form guide component or duplicated documentation content.
- [x] Every parity decision is Preserve, Change, or Remove; every Change/Remove decision has migration guidance and tests.
- [x] Research-to-production owners align with the approved package boundaries.
- [x] The deferred-integrations inventory is approved and contains no item represented as a supported core feature.
- [x] Naming checks prove project-owned public names are descriptive and collision-resistant for the selected namespace/package model.
- [x] The API-version policy distinguishes development, minimum supported, package, and scratch-org release versions and defines an upgrade test.
- [x] The four qualities are reviewed: clear ownership, growth path, extension contract, and newcomer-readable vocabulary.

Evidence: `docs/evidence/02-product-and-packaging/` — complete for the Step 2 design gate. Executable package lifecycle proofs remain assigned to Steps 8–10 after implementation.
