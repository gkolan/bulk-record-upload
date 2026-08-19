# Architecture

> [!NOTE]
> On this page, trace an upload across configuration, authorization, parsing, staging, processing, results, logging, and retention.

The Lightning controller calls a thin Apex controller. Configuration and Schema services build a versioned projection containing only 1–100 configured fields and current-user access decisions. The request service validates CSV, creates the upload and Files, and stores ordered chunks. Queueable jobs map rows, resolve existing records in one bounded query when required, use partial user-mode DML, and write correlated results.

Registries own operation, row-handler, processor, post-action, and field-policy extensions. The standard processor performs partial-success user-mode DML. Custom processors are selected only by reviewed registry keys, and post-actions receive safe row results after a bounded processor invocation. Logs store safe lifecycle data, while retention removes expired package-owned state without deleting a File that has another link.

## Component entry points

`bulkRecordUploadMultiProcess` is the single exposed App Builder component. An administrator selects one active bundle for each component instance. Apex resolves only the active processes assigned to that bundle in configured display order. The component selects a sole process automatically and shows the process selector only when the bundle contains multiple available processes.

On record FlexiPages, the design-time bundle picker scopes choices to bundles containing an active process for the page object. It defaults the sole compatible bundle, leaves ambiguous choices unset, and the runtime displays an administrator configuration notice until a bundle is selected.

The fixed key is a configuration choice, not an authorization grant. Apex validates it through the same projection service used for submission and returns only history for that process. The browser cannot use the wrapper to bypass run, preview, delete, CRUD, FLS, sharing, registry, or active-configuration checks.

## Related

Read [Cache design](cache-design.md), [Custom handlers](custom-handler.md), and the [product contract](../reference/product-contract.md).
