# Step 1 — Baseline, provenance, and inventory

## Goal

Establish what can legally and technically become project source before copying any reference artifact.

## Work

1. Run the environment preflight: confirm the applicable installed Salesforce skills can be read; record `sf` CLI and Code Analyzer versions; confirm Node/npm requirements; verify Git state; and identify the approved org alias without making an org change. Before any later org action, separately verify that the explicit alias resolves to `https://sfdo-gk-dev-ed.develop.my.salesforce.com`.
2. Establish a reviewed baseline commit or record why a commit cannot yet be created. The baseline must include repository policy, specifications, and public planning files while excluding ignored research, local state, secrets, generated output, and borrowed standards. Do not commit automatically; the maintainer approves the baseline contents and commit action.
3. Inventory the bounded reference inputs under `research/bulkRecordUpload`: deployable source in `force-app/`; root project/configuration files; root documentation and binaries; and `config/`, `manifest/`, `sample/`, and `scripts/`. Inventory one row per meaningful artifact, subject to the grouping rule in the research-to-production map.
4. Blanket-discard local/generated reference trees—`.sf/`, `.sfdx/`, `.claude/`, `.husky/`, `.vscode/`, `node_modules/`, `test-results/`, coverage, caches, and generated analyzer/deployment output—after recording each tree's path, file count, reason, and confirmation that it will not ship. Do not enumerate tens of thousands of generated library files one row at a time.
5. For each reviewed item record purpose, runtime/test/example status, dependencies, owner, expected package boundary, and disposition: reimplement, adapt with attribution, replace, defer, or discard.
6. Locate licenses and copyright notices for the reference and every dependency. Stop publication of anything without a compatible provenance decision.
7. Capture baseline counts: production/test lines, methods, metadata members, test coverage, analyzer findings, deploy errors, and documentation contradictions.
8. Create an architecture diagram and data-flow/threat-boundary diagram from observed code, not reference claims.
9. Reconcile reference docs with implementation for operations, field behaviors, cache semantics, status transitions, sharing, files, and incomplete features.
10. Confirm ignored directories do not enter package, npm files, archives, or manifests.
11. Complete `artifacts/research-to-production-map.md`. Map every reviewed class, component, metadata type and field, document, integration, test asset, sample-data set, and binary to a proposed production owner and one disposition: reimplement, adapt with attribution, defer, or discard. Do not use “TBD” when closing this step.
12. Complete the reference side of `artifacts/behavior-parity-matrix.md`. Record the observed behavior and evidence location before proposing whether the open-source product preserves, changes, or removes it.
13. Complete `artifacts/deferred-integrations.md` with every incomplete or promised integration found in source, metadata, UI, tests, and documentation.

## Edge cases

Include hidden files, binaries, copied CLI dumps, generated reports, test-only Custom Metadata, example records, personal aliases, usernames, URLs, secrets, stale API versions, unsupported list views, and metadata that exists in docs but not source. Explicitly inspect `research/bulkRecordUpload/.sf/` and `.sfdx/` for org IDs, usernames, aliases, instance URLs, auth state, and deployment reports before blanket disposal; never reproduce those values in tracked evidence.

## Verification and exit gate

- [x] Inventory has one row per meaningful artifact or approved mechanical group, every grouped member is enumerated, and no binary is unexplained.
- [x] Inventory scope covers `force-app/`, project/configuration files, root documentation and binaries, `config/`, `manifest/`, `sample/`, and `scripts/`; every excluded local/generated tree has a count and blanket-discard record.
- [x] Environment evidence records installed skill availability and CLI/tool versions; no unavailable tool is reported as verified.
- [x] The maintainer has approved a clean baseline commit or a tracked explanation records why the repository remains uncommitted.
- [x] License/provenance review has an owner and decision for every candidate artifact.
- [x] `git check-ignore -v research development-standards` succeeds.
- [x] Searches for credentials, tokens, private keys, personal email, and non-approved org URLs are clean or dispositioned.
- [x] Baseline analyzer and test/deploy results are captured without claiming failures are fixed.
- [x] The research-to-production map covers every inventoried runtime, metadata, test, documentation, and integration artifact and has no unresolved disposition.
- [x] The behavior parity matrix records source evidence, target decision owner, compatibility effect, security effect, and required tests for each behavior.
- [x] The deferred-integrations inventory reconciles source, metadata, UI, examples, tests, and documentation so no unfinished promise is mistaken for supported behavior.
- [x] The four-quality review identifies at least one measurable acceptance criterion per quality.
- [x] Evidence is linked here before Step 2 begins.

Evidence: `docs/evidence/01-baseline-and-inventory/` — complete for the Step 1 gate. Failed and unavailable baseline checks remain recorded as baseline conditions, not passes.

Required artifacts:

- `artifacts/research-to-production-map.md`
- `artifacts/behavior-parity-matrix.md`
- `artifacts/deferred-integrations.md`
