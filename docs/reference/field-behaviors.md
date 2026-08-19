# Field behaviors

> [!NOTE]
> On this page, configure existing values and blank CSV cells as separate version 2 decisions.

| Existing Value Action | Behavior                                                        |
| --------------------- | --------------------------------------------------------------- |
| `REPLACE`             | Use the converted CSV value.                                    |
| `KEEP_EXISTING`       | Retain a nonnull Salesforce value.                              |
| `APPEND`              | Join existing then incoming text with the configured separator. |
| `PREPEND`             | Join incoming then existing text with the configured separator. |

Blank CSV Action is independently `IGNORE`, `CLEAR`, or `REJECT`. Append and
Prepend accept `SPACE`, `NEW_LINE`, `COMMA_SPACE`, `SEMICOLON_SPACE`, or `NONE`.
Duplicate text is `SKIP`, `KEEP`, or `REJECT`. Overflow always rejects the row.

Append and Prepend require a text-like field. Update and Upsert load only the
configured existing fields in one bounded user-mode query. Insert stays query-free;
Delete never invokes merge behavior. Version 1 `ValueHandling__c` remains only as
a migration fallback.

## Related

See [Configure field behaviors](../admin/configure-field-behaviors.md) and [Custom handlers](../developer/custom-handler.md).
