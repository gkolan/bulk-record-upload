# Step 7 — Lightning user experience

## Goal

Deliver an accessible, resilient LWC flow for internal and supported Experience Cloud users.

## Work

1. Create a small orchestration component plus focused process selector, file input, mapping/validation, preview/confirmation, progress, history, and result-download components.
2. Use shared pure utilities for CSV preview/escaping and DTO normalization; never duplicate behavior across internal/community wrappers.
3. Define loading, empty, stale config, invalid file, permission denied, partial success, fatal failure, retry, cancellation, offline/network, and expired file states.
4. Use SLDS base components and styling hooks, keyboard/focus management, accessible names, live status announcements, high contrast, zoom/reflow, and localization-safe text.
5. Avoid sending 800-field descriptions to the browser. Render virtualized/paginated configured fields and cap preview rows/columns.
6. Prevent double submission and retain an idempotency key across safe retries.
7. Do not recreate the reference `bulkRecordUploadGuide` component. Replace its 1,690-line template with focused Markdown pages defined in Step 9. Keep in-product help short and contextual: explain the immediate choice, show validation or recovery guidance, and link to one relevant public documentation page when more detail is useful.
8. The application must remain usable when external documentation is unavailable. Do not fetch Markdown at runtime or make upload behavior depend on a documentation host.
9. Ship one exposed upload LWC. It has only the standard Lightning record-context public properties: `contextRecordId` and `contextObjectApiName`. Apex returns active process choices; one available process is selected automatically and two or more display the selector.

The number of active process choices is the single runtime gate: exactly one process is selected automatically; two or more processes display the selector as the first section at the top of the card. The component accepts no App Builder process or instruction override.

The file drop zone uses a native file input as its full-size interaction surface. A `lightning-input` host cannot reliably stretch its shadow-DOM file control to cover a custom drop zone, which leaves visible instructions without a dependable click target. The native control retains an accessible label, keyboard focus indication, file-type restriction, disabled state, and the same bounded parsing contract.
The input value is cleared immediately before each file-dialog invocation because
canceling a native chooser emits no `change` event. This guarantees that the
chooser can be reopened and that the same CSV can be selected again.

`Bulk_Record_Upload_Process__mdt` owns the process title icon, subtitle, and instructions.
The header renders the short subtitle, followed by its divider; process-specific
instructions render below that divider. Instruction markup supports paragraphs
and lists (`p`, `ul`, `ol`, and `li`) through Salesforce's sanitized
`lightning-formatted-rich-text` boundary rather than raw HTML injection. The LWC
receives only the compact presentation DTO for the selected authorized process.
The title icon accepts a validated SLDS `category:name` identifier and falls back
to `utility:upload` when blank or invalid. After the page instance was removed,
the deprecated App Builder `instructions` compatibility property was removed.
The process selector heading uses the same Salesforce heading color and title-scale
typography as the surrounding record-page section. Process instructions use the
same font family and scale as the subtitle.

## Verification and exit gate

- [x] Applicable LWC and SLDS skills were followed and recorded.
- [x] Jest covers every state, Apex failure, event contract, and cleanup path.
- [x] ESLint, formatting, SLDS validation, and accessibility automation pass.
- [ ] Keyboard-only and screen-reader manual checks are recorded. **Explicitly deferred to Step 10 by the project owner on 2026-08-12; this is not a pass.**
- [x] Performance budget passes for maximum configured fields and preview size.
- [ ] Internal and Experience Cloud permission/user scenarios pass without leaking data. **Interactive scenarios are explicitly deferred to Step 10; automated least-privilege tests pass.**
- [x] Components are small, composable, documented, and individually understandable.
- [x] No documentation-only LWC is shipped; contextual links resolve to stable pages and have understandable accessible names.
- [x] Offline or unreachable documentation does not block configuration, validation, upload, status, or results.

Evidence: `docs/evidence/07-lwc/README.md`; deferred manual procedure: `docs/evidence/07-lwc/manual-accessibility-checklist.md`

## Authorized gate exception

The project owner directed the program to move past the remaining interactive accessibility and Experience Cloud scenarios and revisit them at the end. Steps 8–9 may proceed because implementation, automated accessibility, security, performance, source, and scratch-deployment gates pass. Step 10 cannot close until the deferred checklist is completed or a final release decision explicitly accepts the known gap.
