# Excluded local and generated reference trees

> [!NOTE]
> On this page, record grouped file counts and discard reasons for reference trees that cannot become project source.

Counts were collected recursively with hidden files included from the uncommitted snapshot at 2026-08-12T01:12:00.5521057-05:00.

| Reference path                            | File count | Disposition | Reason                                                                                                                                |
| ----------------------------------------- | ---------: | ----------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `research/bulkRecordUpload/.sf/`          |         56 | Discard     | Local Salesforce CLI state may contain aliases, instance details, org identifiers, authentication state, and generated command output |
| `research/bulkRecordUpload/.sfdx/`        |      6,110 | Discard     | Legacy local Salesforce state and generated tooling data are not source inputs                                                        |
| `research/bulkRecordUpload/.claude/`      |          1 | Discard     | Personal tool configuration is outside the distributable project boundary                                                             |
| `research/bulkRecordUpload/.husky/`       |          1 | Discard     | Reference repository hook configuration will not be copied; required checks must be project-owned                                     |
| `research/bulkRecordUpload/.vscode/`      |          3 | Discard     | Reference editor state is not a runtime or package artifact                                                                           |
| `research/bulkRecordUpload/node_modules/` |     30,415 | Discard     | Generated third-party dependency installation; dependencies must be resolved from reviewed manifests and lockfiles                    |
| `research/bulkRecordUpload/test-results/` |         17 | Discard     | Generated test output is stale evidence and may expose local paths or data                                                            |

The inventory owner confirmed that these grouped trees will not ship. The Step 1 secret and identifier review must inspect sensitive local-state categories without copying their values into tracked evidence.

## Related

- [Step 1 evidence summary](README.md)
- [Step 1 specification](../../../specs/01-baseline-and-ip-gate.md)
