# Governance

## Maintainer responsibilities

Maintainers protect the product contract, security boundary, package compatibility, test evidence, and published documentation. At least one maintainer reviews source changes; security- or release-sensitive changes require a second reviewer when the project has two available maintainers.

Decisions that change packaging, public contracts, supported releases, limits, or security require an ADR under `specs/decisions/`. Maintainers record conflicts between Salesforce skill guidance and local standards in the active specification.

## Releases

A release owner follows [RELEASING.md](RELEASING.md), retains evidence, and does not promote with an open release gate. No maintainer may bypass the authorized-org policy.
