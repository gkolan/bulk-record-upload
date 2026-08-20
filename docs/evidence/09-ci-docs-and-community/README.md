# Step 9 — CI, documentation, and community evidence

Working-tree identity: uncommitted implementation snapshot; baseline commit remains maintainer-gated by Step 1.

## Published repository surface

The repository now includes MIT licensing, notices, conduct, contribution, security, support, governance, changelog, release instructions, issue/PR templates, Dependabot, and GitHub Actions. The README reflects implemented behavior and routes administrators, users, and developers through 20 task/reference pages under `docs/`.

`npm run check:all` passed on Windows with Node.js 24.13.1: ESLint, Prettier, 8 Jest suites/27 tests, 212-file package/metadata/Apex checks, 53-file Markdown validation, release-boundary scanning, and the large-schema benchmark. `npm audit --omit=dev` reported 0 vulnerabilities. CycloneDX 1.5 SBOM generation found 748 components and the CI retains the artifact for 30 days.

## Dependency and license review

The SBOM reported SPDX identifiers 0BSD, Apache-2.0, BlueOak-1.0.0, BSD-2-Clause, BSD-3-Clause, CC-BY-4.0, ISC, MIT, MPL-2.0, and Python-2.0. Three transitive development packages lacked SPDX IDs in the SBOM. `exit@0.1.2` contains an MIT license. `@lwc/state@0.28.0` and `@lwc/state-test-utils@0.28.0` contain Salesforce Terms of Use for Public Code (Non-OSS); they are transitive Jest tooling, are not in Salesforce metadata or the npm archive as installed code, and require maintainer/legal review before any redistribution beyond ordinary dependency installation. This limitation is not described as an open-source dependency clearance.

## Release and analyzer boundary

The checked-in release profile validates and disables 12 reviewed generic design/convention rules; the neutral findings remain documented in Step 8. A tool failure first exposed missing Jest version detection, which `eslint.config.js` now fixes explicitly. The final Recommended release scan found zero violations.

The npm dry-run archive initially exposed generated root analyzer reports and local planning material. `.npmignore` now excludes research, local standards, evidence, specifications, generated analyzer/coverage/auth state, local agent/editor files, and starter Apex/SOQL scripts. The final dry-run inventory contains 268 files (354,337 unpacked bytes) and zero forbidden paths; it contains project source and public documentation with no ignored reference tree or generated report.

CI keeps Salesforce work manual and environment-protected. It checks the approved persistent URL before authentication and uses the explicit alias `release-target`; it cannot fall back to a global default. Scratch-org creation/reuse remains governed by `AGENTS.md` and `docs/developer/testing.md`.

## Documentation review

- The [guide migration map](guide-migration-map.md) gives every reference-guide heading one destination or discard/defer reason.
- `specs/artifacts/research-to-production-map.md` covers the other documents, audits, configuration/onboarding/handler/schema guides, scripts, generated output, samples, draft, and deck.
- The deck and samples were excluded after provenance, branding, and data-safety review; new examples use fictional deterministic values.
- Deferred integrations appear only in the approved unsupported-feature/roadmap context and have no setup instructions or inactive controls.
- Facts review used source metadata, Apex contracts, ADRs, and executable results. Editorial review applied the required note, shortest path, Salesforce terms, cross-platform commands, troubleshooting, and next links.

Screenshots and their accessibility review remain deferred to Step 10 together with the owner-authorized interactive accessibility audit. No screenshot is represented as current evidence in Step 9.

## Four-quality review

- **Easy to maintain:** one local command and one CI workflow share the checks; primary pages own each fact.
- **Easy to scale:** limits and the 800-descriptor proof are linked from admin and developer paths.
- **Easy to extend:** handler, behavior, testing, compatibility, and release documents name the change path.
- **Easy to understand:** the landing page separates administrator, user, developer, and reference tasks.
