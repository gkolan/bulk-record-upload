# Contributing

> [!NOTE]
> On this page, set up a safe local workspace, run the same checks as CI, and prepare a reviewable contribution.

## Local path

1. Install Node.js 22 or later and Salesforce CLI v2.
2. Run `npm ci`.
3. Read the [architecture](docs/developer/architecture.md), [testing guide](docs/developer/testing.md), and the public documentation for the behavior you want to change.
4. Run `npm run check:all` before opening a pull request.

Salesforce changes require an explicit verified `--target-org`, project Apex tests, and Salesforce Code Analyzer after tests. Use a development org you control and never rely on an unknown global default. Coordinate shared maintainer-org work with the project owner before running org commands; the project's only authorized persistent maintainer org is `https://sfdo-gk-dev-ed.develop.my.salesforce.com`.

## Change expectations

- Keep Apex classes below 500 physical lines and use `BulkRecordUploadTestDataFactory` for reusable records.
- Keep local plans, specifications, review notes, agent state, generated reports, and credentials outside commits and release archives. The ignore rules cover these files; they are not prerequisites for contributors.
- Keep source, tests, CI, reusable demo assets, and developer documentation in Git so others can reproduce and extend the project.
- Add focused tests and update public documentation when behavior changes. Describe design decisions and verification in the pull request.
- Use Conventional Commit-style summaries when practical, such as `fix: preserve CSV row correlation`.

Maintainers review security, compatibility, tests, documentation, and the four engineering qualities before merge.

## Next steps

Read [developer testing](docs/developer/testing.md) and the [release process](RELEASING.md).
