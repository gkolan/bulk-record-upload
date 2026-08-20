# Step 1 baseline and inventory evidence

> [!NOTE]
> On this page, track the reviewed baseline, provenance, and inventory evidence needed to complete Step 1 without publishing local authentication state or generated output.

## Snapshot

- **Working-tree identity:** Uncommitted initial snapshot; `HEAD` does not exist.
- **Timestamp:** 2026-08-12T01:12:00.5521057-05:00
- **Target:** Local
- **Status:** Complete for the Step 1 exit gate
- **Reviewer:** Maintainer approval pending

## Environment preflight

| Requirement              | Command or procedure                                 | Expected result                                                       | Observed result                                                                          | Status      | Follow-up                                                                                 |
| ------------------------ | ---------------------------------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------- |
| Git baseline             | `git status --short` and `git rev-parse HEAD`        | Identify the commit and local changes                                 | The repository has no `HEAD`; all publishable project files are untracked                | Unavailable | Maintainer must review and approve the first commit; no commit was created automatically  |
| Ignore boundary          | `git check-ignore -v research development-standards` | Both local-input directories resolve to an ignore rule                | `.gitignore` lines 28 and 29 ignore both directories                                     | Passed      | Repeat before the Step 1 exit review                                                      |
| Salesforce CLI           | `sf --version`                                       | Report the installed CLI version                                      | `@salesforce/cli/2.146.3`, Windows x64, embedded Node `v22.23.1`                         | Passed      | The restricted-sandbox attempt failed; the read-only retry outside that sandbox succeeded |
| Code Analyzer            | `sf code-analyzer --help` and `sf plugins`           | Confirm that the installed command is readable and record its version | `code-analyzer 5.15.0`                                                                   | Passed      | The baseline scan used the installed skill workflow                                       |
| Node.js                  | `node --version`                                     | Meet the repository and analyzer runtime requirement                  | `v24.13.1`                                                                               | Passed      | Confirm CI uses a supported pinned version before release                                 |
| npm                      | `npm --version`                                      | Report the package manager version                                    | `11.8.0`                                                                                 | Passed      | None for this baseline                                                                    |
| Java                     | `java -version`                                      | Meet Code Analyzer's Java 11+ requirement                             | Eclipse Temurin OpenJDK `25.0.4` LTS                                                     | Passed      | Analyzer engine startup remains unverified until the CLI runs                             |
| Installed skill guidance | Read the applicable installed skill                  | The Code Analyzer workflow is available                               | `dx-code-analyzer-run` version 1.0 was read from the installed Salesforce skills library | Passed      | Use its bundled parser for every analyzer result                                          |

No org-affecting command ran. The approved alias-to-instance mapping remains unverified, so no retrieve, deploy, query, test, permission, data, or authentication action is authorized by this evidence.

## Baseline Code Analyzer result

- **Command:** `sf code-analyzer run --rule-selector Recommended --output-file ./code-analyzer-results-20260812-012154.json --include-fixes`
- **Actor/tool:** Salesforce Code Analyzer 5.15.0; results parsed with the installed `dx-code-analyzer-run` skill parser.
- **Expected result:** Capture the reference baseline without claiming that findings are fixed.
- **Observed result:** 782 findings across 28 files: 0 critical, 29 high, 255 moderate, 494 low, and 4 informational.
- **Leading high-severity rule:** 17 `ApexCRUDViolation` findings, concentrated in the reference controller.
- **Largest file concentration:** 195 findings in the reference `BulkRecordUploadBatchBase.cls`.
- **Artifact:** Ignored local files `code-analyzer-results-20260812-012154.json` and matching `.log`; this reviewed summary is the publishable evidence.
- **Limitation:** The scanner warned that the repository ESLint configuration was not applied automatically. This baseline is not a release-gate scan and does not establish a clean project configuration.

## Baseline inventory counts

| Scope                                   |                     File count | Review state                                                                   |
| --------------------------------------- | -----------------------------: | ------------------------------------------------------------------------------ |
| Entire bounded reference tree           |                         36,845 | Counted; meaningful-artifact inventory in progress                             |
| `force-app/`                            |                            198 | Detailed disposition pending                                                   |
| `config/`                               |                              1 | Detailed disposition pending                                                   |
| `manifest/`                             |                              6 | Detailed disposition pending                                                   |
| `sample/`                               |                              2 | Detailed disposition pending                                                   |
| `scripts/`                              |                              9 | Detailed disposition pending                                                   |
| Production Apex                         | 7 files / 3,594 physical lines | Counted from reference `.cls` files whose names are not tests                  |
| Test Apex, including the shared factory | 7 files / 4,753 physical lines | Counted from reference test `.cls` files and `BulkRecordUploadTestDataFactory` |
| Deployable metadata XML                 |                      161 files | Counted under reference `force-app/`                                           |

These counts describe the reference baseline. They do not establish correctness, package eligibility, coverage, or license compatibility.

## Evidence records

- [Reference artifact inventory](reference-artifact-inventory.csv)
- [Excluded local and generated trees](excluded-local-generated-trees.md)
- [Provenance and sensitive-data review](provenance-and-sensitive-data-review.md)
- [Observed reference architecture](reference-architecture.md)
- [Observed data flow and threat boundaries](reference-data-flow-and-threat-boundaries.md)
- [Four-quality review](four-quality-review.md)
- [Baseline verification results](baseline-verification.md)
- [Baseline commit review](baseline-commit-review.md)
- [Research-to-production map](../../../specs/artifacts/research-to-production-map.md)
- [Behavior parity matrix](../../../specs/artifacts/behavior-parity-matrix.md)
- [Deferred integrations](../../../specs/artifacts/deferred-integrations.md)

## Current limitations

- The baseline commit needs maintainer approval.
- Salesforce CLI, Code Analyzer version, analyzer results, tests, deployment results, coverage, and approved-org alias verification are unavailable.
- The meaningful-artifact inventory, provenance decisions, behavior reconciliation, threat boundaries, and four-quality acceptance criteria remain incomplete.
- Raw `.sf/`, `.sfdx/`, test output, dependency files, and other local/generated state were counted but are not reproduced here.

## Related

- [Step 1 — Baseline, provenance, and inventory](../../../specs/01-baseline-and-ip-gate.md)
- [Evidence format](../README.md)
