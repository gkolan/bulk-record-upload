# Step 02 — Decision record — evidence

Step spec: [../../../specs/convergence/02-decision-record.md](../../../specs/convergence/02-decision-record.md)

## Verification

- **Requirement:** "ADR exists, is numbered 0007, and follows the structure of
  ADR-0001..0006."
- **Working-tree identity:** branch `convergence/02-decision-record`, commit
  `Record ADR-0007: configuration over code extension`.
- **Timestamp:** 2026-08-19 (session date).
- **Actor/tool:** Claude (agent), manual document authoring.
- **Command/procedure:** Read ADR-0004 and ADR-0006 for structure (status/owners
  header, Decision, Consequences, Related), then wrote
  `specs/decisions/ADR-0007-configuration-over-code-extension.md` following the
  same shape and added it to the `Related` section of ADR-0004 and ADR-0006 (the
  repository has no separate ADR index; cross-links in `Related` sections are
  the existing convention).
- **Target:** local (documentation only).
- **Expected result:** ADR-0007 states the decision, the predictability rule
  verbatim, an explicit DML-closed refusal, and is citable by steps 03 and 06.
- **Observed result:** Passed. Steps 03 and 06's spec files already cite
  "ADR-0007" by name ("the worked example behind the predictability rule in
  ADR-0007" in step 03; "per ADR-0007" and "citing ADR-0007" in step 06's exit
  gate), confirming the ADR supplies what those steps expect to reference.
- **Artifact:**
  `specs/decisions/ADR-0007-configuration-over-code-extension.md`.
- **Reviewer:** Claude (agent), pending human review.

## Markdown lint / Prettier

- **Command:**
  `npx prettier --check specs/decisions/ADR-0007-configuration-over-code-extension.md specs/decisions/ADR-0006-runtime-principles.md specs/decisions/ADR-0004-security-model.md`
- **Target:** local.
- **Expected result:** No formatting issues.
- **Observed result:** Passed. No dedicated markdownlint config exists in this
  repository (`scripts/check-docs.mjs` only enforces file presence under
  `README.md`, `docs/`, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, none of
  which cover `specs/`); Prettier is the applicable formatting check for this
  file.
- **Reviewer:** Claude (agent), pending human review.

## Exit gate

- [x] Verification items pass.
- [x] Markdown lint and Prettier pass.
- [x] No source or metadata changed (confirmed: only `specs/decisions/*.md`
      files touched).

## Four-invariant summary (per AGENTS.md)

- **Maintainable/Understandable:** One recorded decision that later steps cite
  by section instead of each re-justifying the same tradeoff.
- **Extensible:** Names the one seam that is meant to be open and states why
  everything else is deliberately closed, so a future contributor does not
  reopen a seam this program just closed.
- **Scalable:** N/A — documentation only, no runtime surface.
