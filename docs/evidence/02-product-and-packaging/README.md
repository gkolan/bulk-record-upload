# Step 2 product and packaging evidence

> [!NOTE]
> On this page, see the approved product, package, compatibility, naming, and API-version decisions that authorize security and architecture design.

## Approved decisions

- [ADR-0001 — Packaging strategy](../../../specs/decisions/ADR-0001-packaging-strategy.md)
- [ADR-0002 — Version 1 product contract](../../../specs/decisions/ADR-0002-product-contract.md)
- [ADR-0003 — Public naming and API versions](../../../specs/decisions/ADR-0003-public-naming-and-api-version.md)

## Package-boundary verification

- **Working-tree identity:** Uncommitted snapshot; no `HEAD` exists.
- **Command:** `node scripts/check-package-boundary.mjs`
- **Target:** Local
- **Expected result:** Only `force-app/` is Core; no wildcard, deferred integration, guide component, or ignored local-input path appears.
- **Observed result:** Passed with zero current Core files. The explicit manifest contains no members because implementation has not begun.
- **npm archive cross-check:** `npm pack --dry-run --json --ignore-scripts` listed 45 files and excluded `research/` and `development-standards/`.
- **Limitation:** Repeat this check after every metadata step; a zero-file boundary does not prove the later package is complete.

## Compatibility matrix

| Scenario             | Version 1 contract                                                                                        | Required proof                                                                      |
| -------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Fresh install        | Promoted no-namespace unlocked package into API 66.0+ supported edition                                   | Package install, permission assignment, configuration, first upload, package tests  |
| Upgrade              | Previous promoted ancestor to candidate; preserve subscriber configuration and supported operational data | Upgrade install, migration checks, upload regression, configuration/data comparison |
| Corrective recovery  | Install a new immutable patch version; never mutate a promoted version                                    | Candidate creation and upgrade evidence                                             |
| Uninstall            | Export required logs/files first; document observed package-owned data and Files behavior                 | Uninstall rehearsal and post-uninstall inventory                                    |
| No-namespace source  | Deploy `force-app/` without package namespace                                                             | Explicit source deployment and tests                                                |
| Namespace migration  | Unsupported in place; a namespaced package is a new product identity                                      | Separate future migration ADR                                                       |
| Examples             | Explicit post-Core deployment from `examples/`                                                            | Boundary check and deterministic setup verification                                 |
| Integration fixtures | Explicit post-Core deployment from `integration-tests/`; never a customer dependency                      | Core-only install before fixture deployment                                         |

## Canonical public contracts

- [Product contract](../../reference/product-contract.md)
- [CSV and results contract](../../reference/csv-and-results-contract.md)
- [Package and compatibility](../../reference/package-and-compatibility.md)
- [Unsupported features](../../reference/unsupported-features.md)
- [Working contract example](../../examples/first-upload-contract.md)

## Naming and API-version evidence

The approved package has no namespace and reserves `BRU`, `BulkRecordUpload`, `bru`, and `bru_` forms by metadata surface. Current source contains no public metadata names, so the initial collision search has zero candidates. Step 5 must run project, dependency, standard-name, and authorized-org checks before each name is created.

Development/package API version is 67.0; minimum subscriber API version is 66.0. Preview releases do not satisfy a gate. Every release must prove fresh install, previous-version upgrade, and no-namespace source deployment.

## Four-quality review

| Quality            | Acceptance evidence                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| Easy to maintain   | One owner and one canonical reference exist for each contract; Core has one explicit package directory                              |
| Easy to scale      | Hard byte/row/column/cell/concurrency limits and the 100-field compact projection are public                                        |
| Easy to extend     | Configuration, handler, status, and result contracts version independently; optional integrations remain separate                   |
| Easy to understand | Subscriber terminology, unsupported features, migration effects, and a first-upload result example are linked from `docs/README.md` |

## Limitations

Package creation, install, upgrade, uninstall, and authorized-org naming checks require verified Dev Hub/org state and later implementation. Their required procedures are approved here; executable results belong to Steps 8–10 and cannot be claimed yet.

## Related

- [Step 2 specification](../../../specs/02-product-contract-and-packaging.md)
