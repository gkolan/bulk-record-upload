# Cache design

> [!NOTE]
> On this page, understand what's actually cached, for how long, and why a cache miss or a config change can never produce a stale or wrong result.

## Scope

This explains `BulkRecordUploadProjectionCache` — the in-memory cache that avoids rebuilding the same process configuration repeatedly within one upload. It's an implementation detail, not something you configure; read this if you're debugging performance or extending the projection-building code, not to change any settings.

## What's cached and for how long

What's cached is the **projection** — the compact, per-process snapshot described in [Architecture](architecture.md#the-pipeline-end-to-end): which columns a process has, and what the current user can do. Building it means reading Custom Metadata and Salesforce's Schema describe information, which is more work than a straight cache lookup, so it's worth reusing within a single transaction.

The cache holds at most 50 entries and lives only for the current Apex transaction — Apex's own `static` variables reset between transactions, so there is nothing persistent to clear, expire, or worry about leaking between users. If a 51st distinct entry is added, the oldest one is dropped to make room.

## What the cache key looks like

A real key, built from real inputs, looks like this:

```text
bru:projection:1:0.1:Contact_Insert_Weekly:9f2a...(config hash)...:7c1e...(access fingerprint)
```

It's built from:

- The process's Developer Name (`Contact_Insert_Weekly` above) — so different processes never share an entry.
- A hash of that process's own configuration (every column setting, every extension it registers) — so editing the configuration in Custom Metadata produces a different key automatically, with nothing to manually invalidate.
- A hash of what the _current user_ can do — their object permissions, their **Bulk Record Upload Run** and **Bulk Record Upload Delete** Custom Permissions, and their locale. This means two different users, or the same user before and after a permission change, never share a cache entry — one user's field-level security never leaks into another user's projection.

## What happens on a miss

If a key isn't in the cache — the first time it's needed in a transaction, after a configuration change produced a new key, or if a cached value somehow fails to deserialize — the projection is rebuilt from scratch, from Custom Metadata and Schema describe, exactly the way it would be built with no cache at all. Nothing about correctness depends on a cache hit; the cache only saves repeated work within the same transaction, never changes the answer.

## What this deliberately doesn't do

There's no Salesforce Platform Cache (org-wide, cross-transaction cache) involved. That means nothing here needs an org's Platform Cache partition to be provisioned for the package to install or work correctly — one less piece of setup for a subscriber org.

## Related

See the [large-schema measurements](../evidence/08-large-org-benchmarks/README.md) for how this performs on an object with hundreds of fields.
