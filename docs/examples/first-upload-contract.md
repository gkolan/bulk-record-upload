# First-upload contract example

> [!NOTE]
> On this page, see a small version 1 CSV and the result shape an administrator can use to verify a configured insert process.

This example documents the contract before the runtime is implemented. Release documentation will add exact Setup and UI steps only after the metadata and Lightning components pass deployment and user tests.

Given an active insert process whose projection maps **Account Name** to `Account.Name`, prepare:

```csv
Account Name
Contract Example Account
```

A successful upload returns a results file shaped like:

```csv
bru_row_number,bru_status,bru_record_id,bru_error_code,bru_error_message,Account Name
2,SUCCESS,001000000000001,,,Contract Example Account
```

Verify that the status reaches `COMPLETED`, the result preserves row number 2, and the created record is visible to the running user. The ID above is illustrative and not a real org record.

## Next steps

- Review the [CSV and results contract](../reference/csv-and-results-contract.md).
- Check the [product limits and lifecycle](../reference/product-contract.md).
