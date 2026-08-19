# Step 02 — Decision record: configuration over code extension

## Goal

Write the thesis down as an ADR before the steps that depend on it, so the
refactors that follow are executing a recorded decision rather than improvising
one.

## Why

The package currently sends mixed signals about how a subscriber extends it.
Five classes are named `*Registry`, but they are two unrelated things wearing one
name, and none of them can be extended by a subscriber without forking the
package. Steps 03 and 06 resolve that, and both need a decision to point at.

`specs/decisions/` already holds ADR-0001 through ADR-0006. This adds ADR-0007.

## Preconditions

None.

## Must not change

Nothing. This step produces documentation only.

## Work

Create `specs/decisions/ADR-0007-configuration-over-code-extension.md` recording:

1. **Decision.** Flexibility is delivered through configuration a subscriber can
   change in metadata, not through code surfaces they must fork. Where a code
   seam genuinely earns its place there is exactly one, and it is registered
   safely.
2. **Consequences, stated plainly:**
   - Closed sets — operations, field merge behaviors — are code constants, not
     interfaces, and are not named `Registry`.
   - Exactly one interface is open to subscriber implementations, registered
     through metadata and validated as implementing the interface, behind a
     custom permission.
   - The DML path stays closed. Replacing it would bypass the user-mode
     enforcement the security model depends on. This is a deliberate refusal and
     is recorded as one.
   - The App Builder property surface stays minimal. Configuration lives in
     metadata so there is a single answer to "where is this configured?"
3. **The predictability rule**, which governs every future setting:
   > A new setting ships only if an administrator can predict the outcome from
   > that field alone, without knowing another field's value or which of two
   > fields wins.
   > Record `ValueHandling__c` as the worked example that fails this rule and the
   > reason step 03 exists.
4. **Rejected alternatives** and why: a plugin architecture open at every
   lifecycle point (unreviewable security surface, five concepts to learn);
   fully closed with no seam (fails the stated extensibility goal, forces forks).

Add the ADR to any index that lists decision records.

## Verification

- [ ] ADR exists, is numbered 0007, and follows the structure of ADR-0001..0006.
- [ ] The predictability rule is stated verbatim and is quotable by later steps.
- [ ] The closed-DML refusal is explicit, not implied.
- [ ] Steps 03 and 06 can cite specific ADR sections.

## Exit gate

- [ ] Verification items pass.
- [ ] Markdown lint and Prettier pass.
- [ ] No source or metadata changed.

## Rollback

Delete the file.
