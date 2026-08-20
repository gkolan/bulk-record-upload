# Step 5 metadata and permissions evidence

> [!NOTE]
> On this page, trace the Core metadata boundary and the verification required before Apex implementation starts.

## Implemented Core metadata

- Private `Bulk_Record_Upload__c` execution records with stable lifecycle values, history, counts, retention, and Salesforce File identifiers.
- Controlled-by-parent `Bulk_Record_Upload_Chunk__c` durable staging records with bounded payload and ordered row correlation.
- Process and field Custom Metadata Types with no shipped subscriber records.
- Four composable permission sets and four dependency-aware Custom Permissions.
- A standard Lightning application, upload object tab, and operational list views.
- An explicit API 67.0 manifest with no wildcard members.

## Local verification

| Date       | Command                                                       | Target         | Result                                                                                                                                     | Artifact                                                                              |
| ---------- | ------------------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| 2026-08-12 | `npm run check:source`                                        | Local source   | Passed: 56 Core files, no deferred/local-input boundary violation, descriptions/help within project limits, and explicit manifest coverage | Console output recorded in this task                                                  |
| 2026-08-12 | PowerShell XML parse of all `force-app/main/default/**/*.xml` | Local source   | Passed                                                                                                                                     | Console output recorded in this task                                                  |
| 2026-08-12 | `sf template generate flexipage ...`                          | Local CLI only | Passed after supplying the actual shell name to bypass a host Node `os.userInfo()` failure; generated the page from the supported template | `force-app/main/default/flexipages/Bulk_Record_Upload_Record_Page.flexipage-meta.xml` |

## Scratch-org verification

| Date       | Command                                                               | Target                        | Result                                                                                 | Artifact  |
| ---------- | --------------------------------------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------- | --------- |
| 2026-08-12 | `sf org list --json --skip-connection-status`                         | Local authenticated inventory | Confirmed one active 30-day project scratch org created by the authorized Dev Hub      | This page |
| 2026-08-12 | `sf project deploy preview --source-dir force-app --json`             | `sfdo826`                     | Passed: no conflicts, ignored files, retrievals, or destructive changes                | This page |
| 2026-08-12 | `sf project deploy start --dry-run ... --test-level NoTestRun --json` | `sfdo826`                     | Passed: 56 of 56 components, including three list views; zero component or test errors | This page |
| 2026-08-12 | `sf project deploy start ... --test-level NoTestRun --json`           | `sfdo826`                     | Passed: fresh deployment of 56 of 56 components; zero component or test errors         | This page |
| 2026-08-12 | `sf org assign permset` for all four project permission sets          | `sfdo826`                     | Passed: four assignments to the scratch administrator; zero failures                   | This page |

## Reference graph

The manifest owns all current project references from permission sets, the application, tab, and list views. Custom Metadata records are intentionally absent. `Target_Object__c`, `Field_API_Name__c`, `Handler_Key__c`, and `Preview_Permission__c` are subscriber-supplied references; their required validation and failure behavior are specified in [configuration, metadata, and permissions](../../reference/configuration-and-permissions.md) and become executable in Steps 6 and 8.

## Least-privilege review

- The user permission set grants no target-object permission and no delete capability.
- Preview and delete capabilities are separate permission sets; each includes the required run Custom Permission while target-object access remains subscriber-owned.
- The administrator permission set has no `Modify All Data` or `View All Data`; broad visibility is limited to the two project-owned runtime objects.
- The chunk object is not placed in app navigation.
- Required upload fields are not repeated as field-permission entries.

## Portability and dependency conclusion

The scratch org contained none of the project components before deployment. The complete source deployed without subscriber Custom Metadata records or dependencies on development-org-only metadata. Subscriber-supplied identifiers have documented allowed boundaries and failure guidance; their executable validation and negative-path tests are owned by Steps 6 and 8.

## Four-quality review

- **Maintainable:** setup descriptions, narrow metadata roles, one explicit manifest, and automated checks expose drift early.
- **Scalable:** field configuration defines a compact projection; chunk staging remains separate from the upload record.
- **Extendable:** subscriber records add processes and fields without adding target-object access to package permission sets.
- **Understandable:** app navigation, list views, stable status codes, and role-based permission documentation use one terminology set.

## Related

- [Step 5 specification](../../../specs/05-core-metadata-and-permissions.md)
- [Step 4 architecture evidence](../04-architecture-and-cache/README.md)
