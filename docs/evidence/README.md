# Verification evidence

> [!NOTE]
> On this page, record safe, reproducible proof for each specification step without publishing authentication data, org identifiers, or raw local-state files.

## Directory convention

Create one folder for each step when work begins:

```text
docs/evidence/
  01-baseline-and-inventory/
  02-product-and-packaging/
  03-security/
  04-architecture-and-cache/
  05-metadata-and-permissions/
  06-apex/
  07-lwc/
  08-large-org-benchmarks/
  09-ci-docs-and-community/
  10-release-validation/
```

Each folder contains a `README.md` summary and small reviewed text/Markdown/CSV artifacts when they are useful. Large or generated reports stay in their ignored tool-owned directories; link to their reproducible command and reviewed summary rather than committing the raw file.

## Required record format

Record each verification with:

- **Requirement:** specification checkbox or decision being proved.
- **Working-tree identity:** commit SHA, or a clearly labeled uncommitted snapshot when Step 1 precedes the baseline commit.
- **Timestamp:** ISO 8601 with time zone.
- **Actor/tool:** human, CI job, Salesforce skill, CLI, or test runner and its version.
- **Command or procedure:** exact safe command or numbered manual steps.
- **Target:** `local`, `synthetic`, `scratch`, `package`, or `approved persistent org`. For Salesforce work, record the approved alias and verified instance host, but redact username, org ID, tokens, and login URLs.
- **Expected result:** measurable pass condition.
- **Observed result:** pass, fail, or unavailable, with counts and useful non-sensitive details.
- **Artifact:** repository-relative path to the reviewed evidence or ignored raw artifact location.
- **Reviewer:** person or role that checked the result.
- **Limitations/follow-up:** anything the evidence does not prove.

## Safety rules

Never commit access tokens, auth URLs, org IDs, usernames, email addresses, local aliases that reveal identity, record data, uploaded CSV contents, private keys, full deployment responses, debug logs, or raw `.sf`/`.sfdx` state. Replace sensitive values with stable descriptions; do not use reversible encoding.

Before committing evidence, run the repository secret/identifier checks and inspect the staged diff. A passing command does not make its raw output safe to publish.

## Result language

Use **Passed** only when the recorded procedure ran against the stated target and met the expected result. Use **Unavailable** when a required tool or target could not be used. Use **Not run** for planned work. Do not turn missing evidence into a pass.

## Related

- [Open-source readiness program](../../specs/00-program-overview.md)
- [Step 1 — Baseline, provenance, and inventory](../../specs/01-baseline-and-ip-gate.md)
