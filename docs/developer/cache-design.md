# Cache design

> [!NOTE]
> On this page, understand why compact projections remain correct on cache misses, version changes, eviction, and different user access.

Version 1 uses a transaction-static cache of at most 50 serialized projections. Keys include contract/product version, process, configuration hash, and a permission fingerprint. Values never include the full object field map.

The service rebuilds from Custom Metadata, Schema describe, and current-user access on every miss or corrupt value. Optional Platform Cache is not enabled, so no org partition is required for correctness or installation.

## Related

See the [large-schema measurements](../evidence/08-large-org-benchmarks/README.md).
