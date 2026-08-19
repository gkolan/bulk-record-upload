# Repository instructions

These instructions apply to every human or coding agent working in this repository.

## Mandatory sources of guidance

1. Before a Salesforce task, select and read the applicable installed skill from the Salesforce skills library derived from <https://github.com/forcedotcom/sf-skills>. Follow its workflow, required companion skills, validation, and reporting rules. Do not substitute remembered guidance.
2. Read the relevant files in `development-standards/` before designing or changing code, metadata, tests, documentation, packaging, CI, or deployment behavior. Although that directory is intentionally ignored by Git, it is the local engineering standard.
3. When the skill and local standard differ, follow the stricter safety, security, testing, and verification requirement. Record any material conflict and its resolution in the active specification.
4. Never edit generated or deployable Salesforce metadata without using the applicable metadata context skill when that skill requires it.

## Org policy

- The only persistent Salesforce org authorized for this project is `https://sfdo-gk-dev-ed.develop.my.salesforce.com`.
- Resolve and verify the target org before every org-affecting command. Never deploy, retrieve, query, mutate data, assign permissions, or run tests against another persistent org.
- Use an explicit `--target-org` value. Do not rely on an unknown global default. If authentication or the alias-to-URL mapping is not verifiable, stop.
- A scratch org is the sole exception. Keep at most one active project scratch org, create it for the Salesforce maximum duration (currently 30 days), and reuse it.
- Use `config/project-scratch-def.json`, which requests Salesforce sample data. After creation, deploy the complete project metadata and seed assets, including list views and project test data.
- Never create a replacement scratch org merely for a clean state. Reset data/configuration where safe. Replacement requires an expired, corrupted, incompatible, or demonstrably irrecoverable org, or a release-specific isolation requirement. Document the reason first.
- Scratch-org creation/opening must use the installed `dx-org-manage` skill. Default-org changes must use `dx-org-switch`.

## Engineering invariants

Every design and review must explicitly optimize for: easy to maintain, easy to scale, easy to extend, and easy to understand. A change is incomplete if its verification evidence does not address all four.

- No Apex class may exceed 500 physical lines, including test classes. Treat 450 lines as the refactor warning threshold.
- All reusable Apex test records are created through one common `BulkRecordUploadTestDataFactory`. Test methods may create only behavior-specific values that do not belong in reusable setup.
- No SOQL, DML, describe lookup, callout, or async enqueue in an unbounded loop.
- Use explicit sharing and user-mode CRUD/FLS enforcement at business-data boundaries.
- Dynamic object, field, and handler identifiers must be resolved through trusted allowlists and Schema describe; never trust CSV or administrator text directly.
- Cache schema/configuration in layers: transaction-static cache first; bounded Platform Cache only for cross-transaction immutable projections; client cache only for safe read models. Every cache needs a key version, TTL where applicable, miss path, invalidation path, size bound, and tests.
- For objects approaching 800 fields, never describe, serialize, query, or return every field by default. Resolve only fields configured for the selected upload process and cache the compact projection.
- Keep controllers thin. Separate configuration, authorization, parsing, validation, schema projection, persistence, job orchestration, result generation, logging, and notifications behind narrow contracts.
- Favor partial-success bulk DML and preserve row-to-result correlation.
- Do not log CSV contents, secrets, or sensitive field values.

## Required workflow

1. Read `specs/00-program-overview.md` and the active step file.
2. Confirm the previous step's exit gate is satisfied before implementing the next step.
3. Keep source changes within the active step's scope; update the spec when new constraints or decisions emerge.
4. Use the common test factory and keep every Apex file below 500 lines.
5. Run the local and org verification named in the step. Run Salesforce Code Analyzer through its installed skill.
6. Record command, target org, result, and artifact path. Never claim a deployment or test passed without captured evidence.

## Open-source boundary

`research/` and `development-standards/` are local inputs and must not ship. Do not copy secrets, org identifiers other than the approved documented URL, proprietary content, stale generated reports, or borrowed branding into distributable source. Reimplement ideas with project-owned documentation and attribution where required.
