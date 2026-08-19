# Claude Code guidance

Read and obey `AGENTS.md` first. It is the authoritative repository policy.

Before any Salesforce-specific action, load the applicable installed skill sourced from <https://github.com/forcedotcom/sf-skills>. Also read the relevant ignored files under `development-standards/`. Use `specs/00-program-overview.md` to select the active gated step; do not skip its entry or exit criteria.

The only persistent org is `https://sfdo-gk-dev-ed.develop.my.salesforce.com`. Use explicit target-org flags and verify the resolved instance URL. Maintain no more than one reusable 30-day scratch org created with Salesforce sample data from `config/project-scratch-def.json`; create another only after documenting why reuse is impossible or unsafe.

Hard rules: common `BulkRecordUploadTestDataFactory` for reusable test data; no Apex class over 500 physical lines; optimize every design for maintainability, scalability, extensibility, and understandability; use compact cached schema projections for large objects; never deploy ignored `research/` or `development-standards/` content.
