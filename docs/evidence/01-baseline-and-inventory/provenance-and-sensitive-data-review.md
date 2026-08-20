# Provenance and sensitive-data review

> [!NOTE]
> On this page, see why reference artifacts may inform behavior but cannot be copied into the open-source project and how sensitive local inputs are contained.

## Provenance decision

No repository-level license, source-file SPDX identifier, or copyright grant was found for the reference implementation. Dependency license declarations in `package-lock.json` apply to those dependencies and do not license the reference Apex, metadata, Lightning Web Components, documents, samples, scripts, or presentation.

The project therefore uses these dispositions:

- **Reimplement:** Candidate behavior may be restated as a project requirement and implemented in independently written project source.
- **Replace:** Tooling and dependency manifests are rebuilt from the project's approved requirements, with each dependency reviewed under its own license.
- **Discard:** Reference binaries, local state, generated output, broad profile metadata, editor/agent configuration, and OS files do not ship.
- **Adapt with attribution:** No artifact currently qualifies.

Publication stops if later work needs reference expression rather than observed behavior. The product maintainer owns source provenance; the release maintainer owns dependency notices; the documentation maintainer owns project-written prose and attribution.

## Sensitive-data search

The reviewed search covered the bounded reference tree while excluding generated dependencies and previously classified local/generated trees from content publication.

| Category                                      | Observed result                                    | Disposition                                                                                                                            |
| --------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Private-key markers                           | 0 occurrences                                      | Clean for the reviewed meaningful-artifact scope                                                                                       |
| Token-like terms                              | 2 occurrences in the broad reference Admin profile | False-positive permission names; the profile is discarded                                                                              |
| Email-shaped values                           | 65 occurrences across 16 files                     | Synthetic examples and test data; none will be copied, and replacement data must be project-owned                                      |
| URLs                                          | 1,741 occurrences across 183 files                 | Primarily metadata namespaces and documentation/tool links; no approved-org host was present, and all URLs require review before reuse |
| Salesforce instance hosts outside local state | 0 occurrences                                      | Clean for the reviewed meaningful-artifact scope                                                                                       |

The `.sf/` tree contained 56 files and the `.sfdx/` tree contained 6,110 files. They were inspected only through category/count searches and are blanket-discarded. A full `.sfdx/` content scan exceeded the local command time limit, so this evidence does not claim that tree is clean; the entire tree remains excluded and ignored.

## Verification boundary

The project must repeat secret and identifier searches against the tracked/staged release set before every baseline or release commit. Passing content searches never authorizes publishing ignored local Salesforce state.

## Related

- [Reference artifact inventory](reference-artifact-inventory.csv)
- [Excluded local and generated trees](excluded-local-generated-trees.md)
