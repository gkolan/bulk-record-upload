# Create a custom handler

> [!NOTE]
> On this page, extend row preparation through a registered version 1 handler without accepting administrator-supplied class names.

Implement `BulkRecordUploadHandlerV1`, keep the handler bulk-safe, and return rows without DML, SOQL, callouts, or async enqueue inside an unbounded loop. Add the implementation to `BulkRecordUploadHandlerRegistry` under a stable key, then use that key in `ProcessingHandler__c`.

Add focused registry, mapping, access, bulk, and negative tests. A Custom Metadata value that names an unregistered class is rejected; dynamic class loading is not part of the extension contract.

## Processing extension choices

Use a row handler for bounded normalization or validation before mapping; it must
not perform DML. Use `BulkRecordUploadProcessorV1` when reviewed Apex must own the
bounded persistence call. Use `BulkRecordUploadPostActionV1` after safe row results
exist. Post-actions receive identifiers and safe results, never raw CSV content.

Every implementation must be added to its code-owned registry. Configuration uses
a stable key such as `ACCOUNT_DOMAIN_V1`, never an Apex class name.

## Next steps

Run the [developer test workflow](testing.md) and update the [field behavior reference](../reference/field-behaviors.md) when the extension adds a behavior.
