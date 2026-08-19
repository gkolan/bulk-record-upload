# Step 9 — CI, documentation, and community readiness

## Goal

Make the repository safe and straightforward for strangers to evaluate and contribute to.

## Work

The installed Apex test skill requires behavior-oriented test method names such as `subject_Scenario_Result`, while the generic PMD `MethodNamingConventions` rule requires lower camel case. The release profile follows the more specific Salesforce test workflow, excludes that generic rule, and keeps production method naming under ESLint/Apex review. This resolves the guidance conflict without renaming established tests or suppressing source lines.

1. Add license, notice/attribution, code of conduct, contributing guide, security policy, support policy, changelog, release process, issue/PR templates, and governance/maintainer expectations.
2. Replace the starter README with product purpose, screenshots, supported editions/releases, limits, architecture link, quick start, permissions, configuration example, testing, upgrade/uninstall, troubleshooting, security reporting, and roadmap status.
3. Document the one-org policy for maintainers without exposing credentials. Document scratch-org reuse, 30-day duration, sample data, metadata/list-view deploy, seed data, and cleanup.
4. Add cross-platform npm scripts and CI gates for formatting, lint, Jest, Apex architecture/line count, factory usage, docs/links, manifest completeness, secrets, dependencies/licenses, Code Analyzer, scratch deploy, Apex tests, package build/install, and artifact inspection.
5. Pin or intentionally range dependencies, enable automated updates, create an SBOM/provenance artifact, and set artifact retention.
6. Replace the reference `bulkRecordUploadGuide.html` content with focused Markdown pages. Use this initial information architecture:
   - `docs/README.md`: choose a path by reader and task.
   - `docs/get-started/install.md`, `permissions.md`, `first-upload.md`.
   - `docs/admin/configure-upload-process.md`, `configure-field-behaviors.md`, `security-and-access.md`, `limits.md`, `troubleshooting.md`.
   - `docs/user/prepare-csv.md`, `preview-and-submit.md`, `monitor-upload.md`, `understand-results.md`.
   - `docs/developer/architecture.md`, `custom-handler.md`, `cache-design.md`, `testing.md`.
   - `docs/reference/configuration-fields.md`, `field-behaviors.md`, `csv-format.md`, `statuses-and-results.md`, `supported-field-types.md`.
7. During migration, map every meaningful guide section to exactly one destination page. Remove duplicated, stale, implementation-only, and unsupported material instead of copying the template mechanically.
8. Apply the documentation standard to every page: required “On this page,” note; shortest useful path first; one primary source per fact; exact Salesforce terminology; accessible links; cross-platform commands; troubleshooting; and next-step navigation.
9. Add documentation checks for formatting, internal and external links, duplicate headings/content, required page structure, exact API-name references, code examples, spelling/terminology, orphaned pages, and LWC documentation URLs.
10. Generate roadmap and limitation content from `artifacts/deferred-integrations.md`. Do not describe a deferred item as available, beta, configurable, or coming in a particular release unless an approved product decision changes its status and supplies evidence.
11. Extend the documentation migration map beyond `bulkRecordUploadGuide.html`. Give each root reference document, audit/spec document, configuration guide, onboarding/upload-flow guide, handler guide, schema/template guide, slide deck, draft text file, sample-data set, script, and generated CLI dump one disposition in `artifacts/research-to-production-map.md`: rewrite into one primary public page, retain only as reviewed test/example input, adapt with attribution, defer, or discard.
12. Review the slide deck and every sample-data file for copyright, branding, personal/customer information, IDs, URLs, realistic sensitive values, and license compatibility before using any part. Public examples must be newly owned, deterministic, safe, and documented.

## Verification and exit gate

- [x] A new contributor follows only published docs from clone to passing local checks.
- [x] CI runs from a clean clone and cannot accidentally target an unauthorized org.
- [x] Release archive contains no ignored folder, secret, local alias, generated report, test-only fixture, or unsupported integration claim.
- [ ] Links, commands, examples, and screenshots are current and accessible. Links, commands, and examples pass automated review; screenshots and their accessibility review are deferred to Step 10 by the project owner.
- [x] Every meaningful section from the 1,690-line guide has a reviewed disposition and one primary Markdown destination when retained.
- [x] Every other reference document, binary, sample-data set, script, and generated dump has a reviewed disposition; no deck or sample file is copied without provenance and data-safety approval.
- [x] The documentation landing page provides clear administrator, user, developer, and reference paths.
- [x] No long-form instructional content is embedded in a Lightning template or duplicated across multiple pages.
- [x] Documentation and UI searches show every deferred integration only in the approved limitations/roadmap context, with no setup instructions or inactive controls.
- [x] Each page passes a facts review and an editorial review against `development-standards/documentation-standard.md` and `writing-guide.md`.
- [x] Dependency/license/security scans have reviewed outcomes.
- [x] Documentation makes maintenance, scale limits, extensions, and architecture easy to understand.

Evidence: `docs/evidence/09-ci-docs-and-community/` — implementation and automated gates complete. The owner-authorized screenshot/accessibility exception is carried to Step 10; it is not a pass claim.
