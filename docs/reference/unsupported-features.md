# Unsupported and deferred features

> [!NOTE]
> On this page, confirm which reference ideas are intentionally absent from the version 1 Core package.

Version 1 does not include any of the following:

- Slack notifications or webhooks when an upload finishes
- A generic "upload completed" event a subscriber org could subscribe to — including a Platform Event named `SlackEnvelope__e`, which doesn't exist in this package
- Running a Flow as part of processing a row (only the Apex extension seam — see [Write and register an extension](../developer/custom-handler.md) — is supported)
- Typing an arbitrary Apex class name anywhere an admin configures the package, outside the two specific, reviewed extension fields the framework validates
- Custom colors for status values in the UI
- Cancelling an upload once it's queued
- Reading or writing a field that isn't explicitly configured on the process — there's no "upload every field" option

None of these exist even as an inactive setting, a hidden picklist value, or a disabled button — there's nothing partially built to turn on. Adding one of these later would go through this package's own product, security, and documentation review process from scratch.

## Related

- [Product contract](product-contract.md)
- [Proposed improvements](../roadmap.md)
