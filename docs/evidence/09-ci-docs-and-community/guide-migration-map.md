# Reference guide migration map

The ignored 1,690-line `bulkRecordUploadGuide.html` was reviewed by heading. Retained facts were rewritten against the approved version 1 contracts; reference prose and examples were not copied.

| Reference heading                                   | Disposition              | Primary public destination or reason                                           |
| --------------------------------------------------- | ------------------------ | ------------------------------------------------------------------------------ |
| Required Core Settings                              | Rewrite                  | `docs/admin/configure-upload-process.md`                                       |
| Behavior and Batching                               | Rewrite                  | `docs/admin/configure-field-behaviors.md` and `docs/admin/limits.md`           |
| Access Control                                      | Rewrite                  | `docs/admin/security-and-access.md`                                            |
| Slack Notifications                                 | Defer                    | `docs/reference/unsupported-features.md` only                                  |
| Identifying the Field                               | Rewrite                  | `docs/reference/configuration-fields.md`                                       |
| Defining the Behavior                               | Rewrite                  | `docs/reference/field-behaviors.md`                                            |
| Flags                                               | Rewrite                  | `docs/reference/configuration-fields.md`                                       |
| Match Key — When and How to Use It                  | Rewrite                  | `docs/reference/configuration-fields.md`                                       |
| App Builder Properties — Core                       | Rewrite                  | `docs/get-started/first-upload.md`; unsupported reference properties discarded |
| App Builder Properties — Display Options            | Discard                  | Reference-only presentation controls are not version 1 contracts               |
| App Builder Properties — Advanced                   | Discard                  | Reference-only controls are not shipped                                        |
| Default Values                                      | Discard                  | Default-value configuration is not shipped in version 1                        |
| Example 1 — Static Default Values                   | Discard                  | Depends on unsupported defaults                                                |
| Example 2 — Dynamic Defaults from a Record Page     | Discard                  | Depends on unsupported defaults                                                |
| Example 3 — Aura Wrapper                            | Discard                  | No Aura wrapper is shipped                                                     |
| Available Behaviors                                 | Rewrite                  | `docs/reference/field-behaviors.md`                                            |
| Default Behaviors (Any Field Type)                  | Rewrite in reduced scope | `docs/reference/field-behaviors.md`                                            |
| Text Behaviors (Text, LongTextArea)                 | Rewrite in reduced scope | `docs/reference/field-behaviors.md`                                            |
| Numeric Behaviors (Number, Currency, Percent)       | Discard                  | Reference behaviors are not registered in version 1                            |
| Date Behavior                                       | Discard                  | Reference behavior is not registered in version 1                              |
| Checkbox Behaviors (Boolean)                        | Discard                  | Reference behaviors are not registered in version 1                            |
| Multi-Select Picklist Behaviors                     | Discard                  | Reference behaviors are not registered in version 1                            |
| Behavior_Options__c JSON Keys                       | Discard                  | Field is not part of the approved metadata contract                            |
| Keys for Append / Prepend                           | Discard                  | JSON option contract is not shipped                                            |
| Keys for Date Fields                                | Discard                  | JSON option contract is not shipped                                            |
| Keys for Value Validation                           | Discard                  | JSON option contract is not shipped                                            |
| Keys for Numeric Behaviors                          | Discard                  | JSON option contract is not shipped                                            |
| Keys for Multi-Select Picklist                      | Discard                  | JSON option contract is not shipped                                            |
| Copy-Paste Examples                                 | Discard                  | Examples depend on unsupported configuration                                   |
| Append / Prepend — Controlling the Separator        | Discard                  | Separator option is not shipped                                                |
| Append / Prepend — Timestamp Only (No User Name)    | Discard                  | Timestamp option is not shipped                                                |
| Append / Prepend — Timestamp + Initials             | Discard                  | Timestamp option is not shipped                                                |
| Append / Prepend — Timestamp + Full Name            | Discard                  | Timestamp option is not shipped                                                |
| Append / Prepend — Timestamp + First Name           | Discard                  | Timestamp option is not shipped                                                |
| Date Fields — Input Format (dateFormat)             | Discard                  | Configurable date format is not shipped                                        |
| Number / Currency / Percent Fields                  | Rewrite as type boundary | `docs/reference/supported-field-types.md`                                      |
| Multi-Select Picklist (AddValue / RemoveValue)      | Discard                  | Behaviors are not shipped                                                      |
| Value Validation (allowedValues / restrictedValues) | Discard                  | JSON validator options are not shipped                                         |
| Setup / Configuration Errors                        | Rewrite                  | `docs/admin/troubleshooting.md`                                                |
| CSV Validation Errors                               | Rewrite                  | `docs/reference/csv-format.md` and `docs/admin/troubleshooting.md`             |
| Match Key Errors                                    | Rewrite                  | `docs/admin/troubleshooting.md`                                                |
| Runtime and Permission Errors                       | Rewrite                  | `docs/admin/security-and-access.md` and `docs/admin/troubleshooting.md`        |

The other reference documents, scripts, generated output, sample data, draft text, and presentation are dispositioned in `specs/artifacts/research-to-production-map.md`. The deck and draft were discarded. The two sample CSVs were not copied: their provenance is undocumented and their realistic names/values were unnecessary. Public CSV examples were written from scratch with deterministic fictional values.
