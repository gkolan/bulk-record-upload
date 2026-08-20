# Step 06 — One extension seam

**The largest step in this program. It is the only one I would accept splitting
if it grows past a reviewable size.**

## Goal

Reduce five registry-shaped concepts to one extension seam a subscriber can
actually use, plus closed internals with honest names.

## Why

Five classes are named `*Registry` and they are two unrelated things wearing one
name:

- `OperationRegistry` and `FieldBehaviorRegistry` are **closed sets** — fixed
  allowlists resolving to one parameterized class. They were never intended to be
  subscriber-extensible.
- `HandlerRegistry`, `ProcessorRegistry`, and `PostActionRegistry` are **plugin
  points** with interfaces.

Nothing in the code tells a reader which is which. And all three plugin points
are hardcoded `if` chains inside the package, so a subscriber cannot register
anything — `ProcessorRegistry` has one implementation and `PostActionRegistry`
has one whose entire behavior is to do nothing. Extension currently means forking
the package. The code looks extensible and is not, which is the worst of both.

**Important correction to an earlier reading:** all four surviving registries are
live in the runtime path at `BulkRecordUploadJob.cls:100-136`. This step reduces
_concepts_, not dead code. `FieldBehaviorRegistry` was the only dead one and step
03 removes it. Nothing here may be deleted on the assumption that it is unused.

## Preconditions

Steps 02 and 03 complete. Step 02 supplies the decision this step executes; step
03 removes `FieldBehaviorRegistry` so this step deals with four registries, not
five.

## Must not change

- **The trusted-allowlist rule still holds.** This step changes how one seam is
  registered, not whether identifiers are validated. A class name from metadata
  is resolved with `Type.forName` and accepted only after an `instanceof` check
  against the reviewed interface. Administrator text is still never instantiated
  blindly.
- **The DML path stays closed**, per ADR-0007. Extensions transform data; they
  never persist it. This is the containment that makes opening the seam safe:
  persistence remains in package-owned code running under user-mode enforcement.
- **`BulkRecordUploadTrimHandler
` must survive** as a shipped implementation of
  the new interface. It is existing working behavior and a subscriber may be
  relying on `TRIM_TEXT_V1`. Do not drop it in the migration.
- **The job remains the single readable lifecycle.** After this step the
  end-to-end order must still be visible in one file.
- Existing `ProcessingHandler__c` and `PostProcessingAction__c` values must keep
  producing the same behavior.

## Design

One interface, two lifecycle phases matching the two points where the job already
calls out to reviewed code:

```
public interface BulkRecordUploadExtension
 {
  List<BulkRecordUploadRow
> beforeMap(projection, rows);
  void afterProcess(uploadId, projection, outcomes);
}
```

A `virtual` base class supplies no-op defaults so an implementer overrides only
the phase they need.

Registration moves to `Bulk_Record_Upload_Extension__mdt`:
`ProcessDeveloperName__c`, `ClassName__c`, `SortOrder__c`, `IsActive__c`.
Multiple active extensions per process run in `SortOrder__c` order.

Resolution validates at configuration load _and_ at resolve time:
`Type.forName` returns a type, the type instantiates, and the instance is
`instanceof BulkRecordUploadExtension
`. Any failure is a configuration error
naming the class, never a silent skip.

## Work

1. Add the interface, the virtual no-op base, and
   `Bulk_Record_Upload_Extension__mdt`.
2. Add a resolver that validates and instantiates registered extensions, ordered,
   with a bounded count per process.
3. Port `BulkRecordUploadTrimHandler
` and the standard handler to the new
   interface as shipped implementations.
4. Replace the `HandlerRegistry` and `PostActionRegistry` calls in
   `BulkRecordUploadJob` with the single extension resolver, preserving the
   existing call order: extensions run `beforeMap` where the handler ran, and
   `afterProcess` where the post action ran.
5. Migrate configuration. `ProcessingHandler__c = TRIM_TEXT_V1` maps to the
   shipped trim extension; `STANDARD_V1` and a blank or `NONE_V1`
   `PostProcessingAction__c` map to no extension. Follow the same
   distribution-history branch as step 03 work item 5: delete the old fields if
   nothing has shipped, otherwise deprecate, translate, and schedule removal.
6. Rename `OperationRegistry` to a name that says "closed set"
   (`BulkRecordUploadOperations`) and do the same for the processor resolver.
   Document both as closed in their class comments, citing ADR-0007.
7. Contain extension failures: a throwing extension fails its upload with a
   recorded error and must not corrupt chunk state or leave a chunk wedged
   mid-status. Never let an extension's exception be silently swallowed.
8. Document how a subscriber writes and registers an extension, with a worked
   example. This is the step's real deliverable — extensibility nobody can find
   is not extensibility.

## Verification

- [ ] A subscriber-authored class registered in metadata runs at both phases, in
      `SortOrder__c` order, proven by a test that registers two extensions.
- [ ] A registered class that does not implement the interface fails at
      configuration load with a message naming the class.
- [ ] A registered class name that does not resolve fails the same way.
- [ ] An extension attempting DML does not bypass user-mode enforcement; the
      persistence path is unchanged and still package-owned.
- [ ] A throwing extension fails its upload cleanly, records the error, and
      leaves no chunk in an inconsistent status.
- [ ] `TRIM_TEXT_V1` behavior is byte-identical before and after migration,
      proven on the same fixture.
- [ ] Existing `ProcessingHandler__c` and `PostProcessingAction__c` values
      produce unchanged results.
- [ ] The end-to-end lifecycle is still readable in one file.
- [ ] No class exceeds 450 lines.
- [ ] Salesforce Code Analyzer passes with no new violations.
- [ ] The extension-authoring documentation is followed end to end by someone who
      did not write it, and the worked example runs.

## Exit gate

- [ ] All verification items pass with recorded evidence.
- [ ] Exactly one class in the package is named `*Registry`, and it is the
      extension registry.
- [ ] ADR-0007 is cited in the class comments of both closed resolvers.
- [ ] Evidence recorded at `docs/evidence/convergence/06/`.

## Rollback

The riskiest step. Keep the old registries in place behind the new resolver until
verification passes, then delete them in a final commit, so rollback before that
commit is a one-line change in the job.
