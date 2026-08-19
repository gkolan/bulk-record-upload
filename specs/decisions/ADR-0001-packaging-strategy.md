# ADR-0001 — Packaging strategy

> [!NOTE]
> On this page, decide how subscribers install and upgrade Bulk Record Upload before public names or deployable metadata make the choice expensive to change.

- **Status:** Approved on 2026-08-12 for implementation and validation.
- **Decision owners:** Product maintainer, Salesforce architect, security reviewer, and release maintainer.
- **Decision deadline:** Before Step 3, any deployable metadata, or any public API-name commitment—whichever would otherwise occur first.

## Context

The product needs a repeatable install, upgrade, dependency, namespace, example, and support model. The choice between a second-generation managed package and an unlocked package affects public API names, subscriber editability, extension contracts, ancestor rules, destructive changes, security review, release automation, and documentation.

## Options to evaluate

### Second-generation managed package

Record namespace ownership, subscriber visibility/editability, managed public/global Apex contracts, security-review expectations, package dependencies, example distribution, and upgrade/deprecation behavior.

### Unlocked package

Record namespace/no-namespace choice, subscriber editability and resulting support expectations, dependency handling, metadata deletion/deprecation behavior, example distribution, and upgrade conflict recovery.

### Unpackaged metadata

Evaluate only as a local development or source example path. It is not an automatic fallback for the installable product requirement and requires an explicit rejection/exception decision if selected for release.

## Required evidence

- Subscriber audience and distribution channel.
- Namespace availability and ownership.
- Fresh-install, upgrade, rollback/recovery, and uninstall proof-of-concept results.
- Public Apex/LWC/metadata extension requirements.
- Core, examples, tests, and optional integration boundaries.
- Dependency and supported-edition/release matrix.
- Security-review and operational support implications.
- CI credentials, package version creation, promotion, retention, and artifact provenance plan.
- Compatibility impact on every behavior-parity decision and production mapping.

## Decision

Use a second-generation unlocked package named **Bulk Record Upload**. Unpackaged source deployment remains a contributor and diagnostic workflow, not the subscriber release artifact.

### Namespace and ownership

The package uses no namespace. Core object APIs use the complete `Bulk_Record_Upload` product name, Apex APIs use `BulkRecordUpload`, public LWC APIs use `bulkRecordUpload`, and fields use contextual PascalCase names. The owner approved this pre-release convention after comparison with the Record Health Check project. Public names must pass collision checks before source is created. A later namespace migration would be a new package line and is not an in-place upgrade.

### Ancestor and version policy

Use semantic product versions and Salesforce four-part package versions: product `MAJOR.MINOR.PATCH` maps to `MAJOR.MINOR.PATCH.NEXT` before version creation. Released versions are immutable. Every promoted version after the first declares the immediately preceding supported release as its ancestor unless Salesforce requires a documented ancestor branch. Breaking public-contract changes require a major version and an explicit migration path.

The initial development line is `0.1.0.NEXT`. Version `1.0.0` is the first supported public contract; pre-1.0 versions are development-only and cannot be treated as upgrade ancestors for subscribers without an explicit release decision.

### Core, examples, tests, and integrations

- `force-app/` is the only customer package boundary. It contains core runtime metadata, least-privilege permission sets, self-contained package tests, and no customer data.
- `examples/` contains optional project-owned examples and deterministic seed data. It is deployed only by an explicit setup command after Core.
- `integration-tests/` contains adversarial metadata, handlers, users, and test fixtures. It never ships.
- Optional integrations use separate future packages or explicit source deployments with their own contracts. Deferred fields, events, permissions, UI controls, and documentation do not appear in Core.
- Long-form documentation stays under `docs/`; the package may contain concise contextual help and stable links but no guide component.

### Installation, upgrade, recovery, and uninstall

Subscribers install a promoted unlocked-package version and then assign a least-privilege user or administrator permission set. Upgrades validate from the previously supported promoted version and preserve subscriber-owned configuration and operational records unless release notes declare a compatible migration.

Unlocked-package rollback means reinstalling or upgrading to a separately created corrective version; a promoted version is never mutated. Destructive metadata changes require a deprecation release and migration before removal. Uninstall removes package-owned metadata and may remove package-owned data according to Salesforce behavior, so administrators must export required logs/results and review Files retention before uninstalling.

## Consequences

- Subscribers can inspect and, where Salesforce permits, modify unlocked metadata. Support covers the published package state; local modifications must be reproduced against an unmodified version before a defect is accepted.
- No namespace makes source deployment and ordinary custom-handler development simpler, but every public global name becomes a permanent collision commitment. Prefix checks are mandatory.
- Public Apex intended for subscriber implementation uses `global` only when cross-package access requires it. Internal package code remains `public` or `private` with the narrowest visibility.
- Examples and integrations require a second explicit deployment, preventing customer dependencies and inactive promises from entering Core.
- A managed 2GP package was rejected for the initial release because the project does not have a verified owned namespace or a managed-package distribution/security-review plan. Moving later requires a new package identity and migration.
- Unpackaged-only release was rejected because it does not provide immutable version identity, ancestor tracking, or a repeatable subscriber upgrade path.

## Verification

- [x] Decision evidence is linked and reproducible.
- [x] Product, architecture, security, and release owners approve the same option.
- [ ] `sfdx-project.json`, manifests, CI, documentation, and package boundaries match the decision.
- [ ] Fresh install and supported upgrade paths work in the one reusable scratch-org workflow.
- [x] Public API names are not committed before namespace strategy approval.

## Related

- [Step 2 — Product contract and packaging](../02-product-contract-and-packaging.md)
- [Behavior parity matrix](../artifacts/behavior-parity-matrix.md)
- [Research-to-production map](../artifacts/research-to-production-map.md)
