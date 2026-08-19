# Contributing

> [!NOTE]
> On this page, set up a safe local workspace, run the same checks as CI, and prepare a reviewable contribution.

## Local path

1. Install Node.js 22 or later and Salesforce CLI v2.
2. Run `npm ci`.
3. Read `AGENTS.md`, `specs/00-program-overview.md`, and the active step.
4. Run `npm run check:all` before opening a pull request.

Salesforce changes also require the applicable installed Salesforce skill, an explicit verified `--target-org`, package-scoped Apex tests, and Code Analyzer after tests. Never use an unknown global default org.

## Change expectations

- Keep Apex classes below 500 physical lines and use `BulkRecordUploadTestDataFactory` for reusable records.
- Keep `research/`, `development-standards/`, auth state, generated reports, and credentials outside commits and release archives.
- Add focused tests and update the active specification and documentation when behavior changes.
- Use Conventional Commit-style summaries when practical, such as `fix: preserve CSV row correlation`.

Maintainers review security, compatibility, tests, documentation, and the four engineering qualities before merge.

## Next steps

Read [developer testing](docs/developer/testing.md) and the [release process](RELEASING.md).
