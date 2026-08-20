# Step 3 security design evidence

> [!NOTE]
> On this page, see the approved security model, threat ownership, permission boundaries, sharing declarations, and executable test obligations for Bulk Record Upload.

## Design authority

[ADR-0004 — Security and data-boundary model](../../../specs/decisions/ADR-0004-security-model.md) owns the object/field access, sharing, trusted identifier, handler, Files, output, cache, asynchronous, and observability policies.

## Threat register

| Boundary                          | Owner                                 | Primary threats                                                            | Approved mitigations                                                                                |
| --------------------------------- | ------------------------------------- | -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Browser → controller              | Request service                       | Bypassed client checks, oversized/malformed content, configuration probing | Uniform unavailable outcome, server limits, parser validation, Custom Permission                    |
| Configuration → Schema/runtime    | Configuration and projection services | SOQL injection, arbitrary objects/fields/permissions/groups                | Canonical Schema resolution and code-owned allowlists                                               |
| Handler registry → Apex           | Registry owner                        | Arbitrary class execution, privilege expansion                             | Compiled versioned registry; no configuration-driven `Type.forName`                                 |
| Controller/async → business data  | Access policy and persistence gateway | CRUD/FLS/sharing bypass, revoked permissions, record inference             | `with sharing`, user-mode query/DML, per-transaction revalidation, redacted partial results         |
| Runtime → Files/logs              | File and log services                 | Sensitive content disclosure, orphaned files, cross-user history           | Salesforce Files authorization, explicit links/ownership/retention, bounded access-filtered history |
| Runtime → generated CSV           | Result writer                         | Formula injection and sensitive errors                                     | Neutralization, stable reason codes, no raw values/exceptions                                       |
| Cache → another user/process      | Projection cache                      | Permission or configuration leakage                                        | Contract/config/access fingerprints, immutable compact values, no record data, safe miss rebuild    |
| Scheduler/cleanup → retained data | Retention service                     | Over-deletion or unrelated File deletion                                   | `with sharing`, package ownership proof, unrelated-link guard, safe skips and metrics               |
| Core → integration                | Product owner                         | Accidental sensitive event/callout                                         | No version 1 event, notification, webhook, or inactive integration surface                          |

## Verification status

- Permission and sharing matrices: approved in ADR-0004.
- Adversarial test specifications: approved; executable tests remain required in Steps 6 and 8.
- Security Code Analyzer policy: `Recommended` plus all severity 1–2 Security rules; the release scan must have zero unresolved findings and runs after tests.
- Current production source: empty, so no executable runtime security claim is possible or made.

## Four-quality review

- **Maintainable:** one access policy and one registry own security decisions.
- **Scalable:** authorization applies to a maximum 100-field compact projection, not an 800-field describe payload.
- **Extensible:** new handlers cannot widen access without registry, interface, permission, and negative-test review.
- **Understandable:** the threat, permission, and sharing tables use the same vocabulary as the product contract and planned class families.

## Related

- [Step 3 specification](../../../specs/03-security-and-data-boundaries.md)
