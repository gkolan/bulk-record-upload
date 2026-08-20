# Baseline verification results

> [!NOTE]
> On this page, see the local test, lint, package-boundary, and unavailable org results captured before implementation begins.

## Local results

| Requirement              | Command                                                                 | Expected result                                                                   | Observed result                                                                           | Status      |
| ------------------------ | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ----------- |
| JavaScript lint baseline | `npm run lint`                                                          | Capture the scaffold/reference lint state                                         | Failed with 8 errors and 1 warning because the root glob traversed ignored reference LWCs | Failed      |
| LWC test baseline        | `npm test`                                                              | Capture existing unit-test state                                                  | Failed because no LWC unit tests exist in the active project                              | Failed      |
| npm package boundary     | `npm pack --dry-run --json --ignore-scripts`                            | Neither `research/` nor `development-standards/` appears in the archive file list | Dry run listed 45 files; neither ignored local-input directory appeared                   | Passed      |
| Manifest boundary        | Review `manifest/package.xml` and search tracked planning/tooling paths | No ignored reference path is a manifest member                                    | No ignored reference path is a manifest member; active Salesforce source is empty         | Passed      |
| Org deployment and tests | Verify approved alias, then run the step's explicit org commands        | Capture deployment, Apex test, and coverage baselines                             | Approved alias-to-host mapping is unverified, so no org command ran                       | Unavailable |

The failed lint and test baselines are not treated as fixed. Step 9 must scope local tooling to project source so ignored research cannot affect release checks, and Steps 7–8 must add and run LWC tests.

## Reference size and method counts

| Measure                                  |                                     Count |
| ---------------------------------------- | ----------------------------------------: |
| Production Apex files                    |                                         7 |
| Production Apex physical lines           |                                     3,594 |
| Production method declarations matched   |                                        67 |
| Test/factory Apex files                  |                                         7 |
| Test/factory Apex physical lines         |                                     4,753 |
| Test/factory method declarations matched |                                        35 |
| Deployable reference metadata XML files  |                                       161 |
| Apex test coverage                       |        Unavailable; no authorized org run |
| Reference deploy errors                  | Unavailable; no authorized org deployment |

Method counts use a declaration-pattern baseline and can undercount constructors or multiline signatures. They are sizing evidence, not an API inventory.

## Related

- [Step 1 evidence summary](README.md)
- [Research-to-production map](../../../specs/artifacts/research-to-production-map.md)
