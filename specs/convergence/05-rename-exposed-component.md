# Step 05 — Rename the exposed component

## Goal

The one name a subscriber ever types should describe the product.

## Why

The package's single exposed component is `bulkRecordUploadMultiProcess`. The
name encodes a multi-process versus single-process distinction that Step 7 of the
main program eliminated when it made the count of authorized processes a runtime
gate rather than a component choice. There is now one component that selects
automatically when one process is authorized and shows a selector when two or
more are. Nothing is "multi" about it as opposed to something else.

The `masterLabel` is already "Bulk Record Upload", so administrators dragging it
in App Builder see the right thing. The wrong name is on the developer-facing
surface: the directory, the module name, and any `c/` import.

Renaming a component inside a distributed package is expensive and disruptive.
Right now it costs one commit.

## Preconditions

Step 04 complete, so the rename does not have to carry dead members along with
it.

## Must not change

- `isExposed`, the `targets` list, and the `targetConfigs` — including the
  Experience Cloud context properties added in step 01. The rename moves the
  component; it does not re-scope where it can be placed.
- The `masterLabel` and description shown in App Builder.
- Component behavior, markup, and styling. This is a rename, not a refactor. Do
  not take the opportunity to restructure the file.

## Work

1. Rename the bundle directory and all four member files to `bulkRecordUpload`.
2. Update every `c/bulkRecordUploadMultiProcess` import and every template tag
   reference. Search the whole repository, not just `lwc/` — tests, docs,
   `manifest/package.xml`, permission sets, FlexiPages under `flexipages/`, and
   any example or screenshot reference.
3. Check `force-app/main/default/flexipages/` for a page that places the
   component by its old name. A stale FlexiPage reference deploys but renders an
   error tile.
4. Update documentation that names the component, including any install or
   configuration guide.
5. If any FlexiPage in the authorized persistent org places the old component,
   record what must be re-placed manually after deploy. A component rename does
   not migrate existing page placements.

## Verification

- [ ] Repository-wide search for `bulkRecordUploadMultiProcess` returns nothing.
- [ ] Jest passes with no renamed-module import errors.
- [ ] `sf project deploy start --dry-run` succeeds against the scratch org.
- [ ] After deploy to the scratch org, the component appears in App Builder under
      "Bulk Record Upload" and can be placed on a record page, an app page, and an
      Experience Cloud page.
- [ ] A placed component still receives record context, re-running the step 01
      record-page check to confirm the rename did not drop `targetConfigs`.
- [ ] Any page placements needing manual re-placement are listed in the evidence.

## Exit gate

- [ ] All verification items pass with recorded evidence.
- [ ] Exactly one component has `isExposed=true` and it is named
      `bulkRecordUpload`.
- [ ] Evidence recorded at `docs/evidence/convergence/05/`.

## Rollback

Recoverable from git, but note that any FlexiPage placement made against the new
name must be re-placed if the rename is reverted after deployment.
