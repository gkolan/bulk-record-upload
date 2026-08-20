# Step 7 manual accessibility and runtime checklist

> [!NOTE]
> On this page, record the authenticated runtime evidence required to close Step 7. Do not mark a scenario passed from source inspection, Jest, Sa11y, or SLDS lint output alone.

## Environment record

Before testing, record:

- Date and tester.
- Browser name and version.
- Operating system.
- Assistive technology and version.
- Verified scratch-org alias and expiration date; omit org IDs, usernames, tokens, and front-door URLs.
- Application surface: Lightning Experience or Experience Cloud.
- User persona and assigned project permission sets; omit personal identifiers.
- Deployed job identifier or release commit.

## Keyboard-only flow

1. Open the **Upload Records** tab without using a pointer.
2. Traverse process selection, CSV selection, preview, confirmation, progress, history refresh, result download, and reset using `Tab` and `Shift+Tab`.
3. Activate buttons using `Enter` or `Space` as appropriate.
4. Verify focus is visible, follows visual order, never becomes trapped, and does not enter disabled controls.
5. Trigger an invalid-file error and verify focus remains usable and the error is announced.
6. Record **Pass**, **Fail**, or **Blocked**, plus concise observations.

Result: **Not run**

## Screen-reader flow

1. Start the platform screen reader before loading the application.
2. Verify the application title, process combobox, file input, validation summary, preview heading/table, confirmation, progress status, history table, result action, and reset action have understandable names and roles.
3. Verify live announcements occur for file readiness, submission, offline/online changes, lifecycle status, terminal state, and errors without duplicate or stale speech.
4. Verify table headers are associated with cells and expired results are described as unavailable.
5. Record the screen reader/version and **Pass**, **Fail**, or **Blocked**.

Result: **Not run**

## Contrast and forced-colors flow

1. Enable the operating system's high-contrast or forced-colors mode.
2. Verify text, focus indicators, alerts, progress, table boundaries, and disabled states remain distinguishable without color alone.
3. Confirm no private SLDS hook or fixed project color masks the system palette.
4. Record the mode and **Pass**, **Fail**, or **Blocked**.

Result: **Not run**

## Zoom and reflow flow

1. Set browser zoom to 200% at a 1280 × 720 viewport.
2. Verify process/file controls reflow to one column, headings and alerts remain readable, horizontal scrolling is limited to the preview/history table region, and no action is clipped.
3. Repeat at a narrow mobile-equivalent viewport supported by the application target.
4. Record viewport values and **Pass**, **Fail**, or **Blocked**.

Result: **Not run**

## Internal permission scenarios

Run each scenario with a dedicated test persona:

| Scenario                       | Expected result                                                         | Result  |
| ------------------------------ | ----------------------------------------------------------------------- | ------- |
| No project permission set      | Application/API access denied without configuration disclosure          | Not run |
| `Bulk_Record_Upload_User` only | Approved non-delete process visible; shared upload history only         | Not run |
| User plus preview permission   | Preview-gated process visible when target CRUD/FLS also permits it      | Not run |
| User plus deletion permission  | Delete process available only when target delete access also permits it | Not run |
| Administrator                  | Configuration/audit visibility without implicit target-object CRUD/FLS  | Not run |

For every row, inspect visible text and browser console output for configuration, record, file, or error-detail leakage.

## Experience Cloud scenarios

1. Add the exposed component to a supported authenticated Experience Cloud page.
2. Test the least-privilege member persona and a persona without project access.
3. Exercise configuration loading, local CSV validation, upload submission, polling, history, result download, offline recovery, and expired-result behavior.
4. Verify no runtime documentation request occurs and blocking the public documentation host does not affect the application.
5. Record page type, persona permission sets, and **Pass**, **Fail**, or **Blocked**.

Result: **Not run**

## Evidence record

For each completed scenario, record the timestamp, tester, exact surface, expected result, observed result, and a sanitized screenshot or console artifact path when useful. Never retain credentials, org IDs, usernames, CSV contents, record values, or front-door URLs.

Step 7 closes only when every required scenario above is passed or a specification change formally removes it. A tool limitation or unavailable authenticated session is a blocker, not a pass.
