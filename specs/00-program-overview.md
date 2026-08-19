# Open-source readiness program

## Objective

Create a secure, portable, configuration-driven Salesforce bulk record upload package that a subscriber can install, configure, operate, extend, test, and upgrade without knowledge of the original reference repository.

## Non-negotiable constraints

- Follow `AGENTS.md`, applicable Salesforce skills, and relevant local development standards.
- Use only the approved persistent org URL. Maintain at most one 30-day scratch org with Salesforce sample data.
- No Apex class over 500 physical lines. Warn and split at 450 lines.
- Reusable Apex test data comes from `BulkRecordUploadTestDataFactory`.
- Every step must prove maintainability, scalability, extensibility, and understandability.
- Support mature objects near 800 fields by using compact, bounded, versioned schema/configuration projections.
- Do not import `research/` wholesale. Each production artifact must have an explicit owner, purpose, permission model, test, manifest entry, and documentation reference.

## Execution order

**Active step:** Step 10 — Release validation, concurrently with the
`convergence/` remediation program, starting at
`convergence/01-record-page-context-binding.md`.  
**Status:** Steps 1–9 are closed subject to the project owner's explicit deferral of interactive accessibility, Experience Cloud, and screenshot review to Step 10. Step 10 is authorized and must resolve or report those release gates without claiming an unperformed pass.  
**Convergence authorization:** The project owner has authorized the
`convergence/` remediation program described below. It runs alongside Step 10
under its own working rules and gates (see `convergence/00-overview.md`);
its steps are tracked independently of the Steps 1–10 exit gates above.  
**Implementation lock:** Removed. Production work must follow the approved product, security, architecture, metadata-context, and active-step contracts.

**Evidence convention:** Store reviewed, safe-to-publish evidence summaries under `docs/evidence/<step-number>/` using the format in `docs/evidence/README.md`. Raw CLI responses, analyzer output, auth state, org IDs, usernames, and deploy reports remain ignored unless a reviewer has cleaned them for publication.

1. `01-baseline-and-ip-gate.md`
2. `02-product-contract-and-packaging.md`
3. `03-security-and-data-boundaries.md`
4. `04-architecture-and-cache-design.md`
5. `05-core-metadata-and-permissions.md`
6. `06-apex-implementation.md`
7. `07-lwc-experience.md`
8. `08-testing-and-large-org-benchmarks.md`
9. `09-ci-documentation-and-community.md`
10. `10-release-validation.md`
11. `convergence/` — authorized remediation program. Start at
    `convergence/00-overview.md`. Superseded the earlier draft
    `11-record-context-sources.md`, since deleted; its subject is now
    `convergence/07-record-context-sources.md`.

Do not begin a step until all prior exit-gate checkboxes are satisfied and evidence paths are recorded in that step. If discovery changes a public contract or cross-step assumption, update this overview and every affected downstream step before implementation continues.

Update the active-step marker only when the current step's complete exit gate has evidence and the next step is authorized. A partially completed checklist does not advance the marker.

## Definition of done

The complete manifest validates in the single scratch org and approved persistent org; all tests and scanners pass; install/uninstall/upgrade paths are documented; large-schema benchmarks meet stated budgets; least-privilege users can perform only authorized operations; all public contracts and extension points are documented; and no ignored research/borrowed-standard material appears in the release artifact.
