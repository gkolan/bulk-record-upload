# Proposed improvements

> [!NOTE]
> On this page, see ideas for future work without treating them as available features or release commitments.

The first priority is completing the [release verification](project-status.md) for the current
upload workflow. The following ideas require design, implementation, and testing before they
can be documented as supported:

- More configuration-health and administration tools.
- A richer history and results view with guided failed-row retries.
- Cancellation of queued or in-progress uploads.
- A server-side full-file preflight report before saving records.
- Optional completion-event integrations for Flow, webhooks, or notifications.

There is no delivery schedule for these proposals. Existing file limits and security boundaries
continue to apply. Check [unsupported features](reference/unsupported-features.md) before planning
a workflow that depends on one of these ideas.
