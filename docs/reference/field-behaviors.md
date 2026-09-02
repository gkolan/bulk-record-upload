# Field behaviors

> [!NOTE]
> On this page, look up every column setting on a **Bulk Record Upload Process Field** record, with a use case and a copy-ready example for each one.
> **Reference:** exact behavior and allowed values for every field on `Bulk_Record_Upload_Process_Field__mdt`. See [Configure field behaviors](../admin/configure-field-behaviors.md) for the shorter setup walkthrough.

Every example configures one **Bulk Record Upload Process Field** (`Bulk_Record_Upload_Process_Field__mdt`) record and shows a CSV cell going in and the Salesforce value coming out. Copy one, change the field API name, and adjust.

## Create one, step by step

In Salesforce Setup, search for **Custom Metadata Types**, open it, find **Bulk Record Upload Process Field**, and click **Manage Records**, then **New**. This opens an ordinary Salesforce record form — text boxes, checkboxes, and picklists, the same as creating any other record. There is no JSON, no code, and no separate file to write. Every setting on this page is one field on that one form.

Most fields on the form are exactly what they look like: type a name, pick a picklist value, check a checkbox. A handful hold plain text written in a specific shape. None of them are JSON — here's exactly what you type into each one:

| Field on the form                                                                                 | What you literally type into the text box                                                                                                                                                                                                                       |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Label                                                                                             | Anything readable — this is just the record's name, e.g. `Contact First Name`                                                                                                                                                                                   |
| CSV Column Header (`CsvColumnHeader__c`)                                                          | The exact column header your CSV file uses, e.g. `first_name`                                                                                                                                                                                                   |
| Field API Name (`FieldApiName__c`)                                                                | The Salesforce field this column writes to, e.g. `FirstName`                                                                                                                                                                                                    |
| Blank Tokens (`BlankTokens__c`)                                                                   | Plain words separated by commas, nothing more — `N/A, NULL, -`                                                                                                                                                                                                  |
| Source Template (`SourceTemplate__c`)                                                             | Plain text, with another column's CSV Column Header wrapped in curly braces where you want its value inserted — `{first_name} {last_name}`. The braces aren't JSON or code; they just mark "put that column's value here," the same idea as a mail-merge field. |
| Validation Pattern (`ValidationPattern__c`)                                                       | A regular expression — a short pattern a value must match, e.g. `[0-9]{5}` means "exactly 5 digits"                                                                                                                                                             |
| Custom Merge Strategy Class (`CustomMergeStrategyClass__c`)                                       | The exact name of an Apex class already deployed to your org, e.g. `BulkRecordUploadLongerTextStrategy`                                                                                                                                                         |
| Everything else on this page (Existing Value Action, Blank CSV Action, Text Separator, and so on) | Pick a value from that field's picklist — you don't type these at all                                                                                                                                                                                           |

Fill in the settings for one column, save, check **Is Active**, and repeat for the next CSV column. That's the whole process. Every example below shows what to put in these same fields.

## Every supported field type, with a sample CSV value

Before the individual settings: every field type the framework accepts, a real object and field to try it on, and what a valid CSV cell looks like for that type. This table is just about the shape of the value — for what a setting _does_ with it (merge, blank handling, and so on), follow the link.

| Field type             | Example field                   | What the CSV cell looks like                               | See the full example in                                                               |
| ---------------------- | ------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Text                   | Account `Name`                  | `Acme Corp`                                                | [Trim Value, Case Action, and Blank Tokens](#trim-value-case-action-and-blank-tokens) |
| Text Area              | Account `Description`           | `2026-08-07 — PK: Renewed for another 3 years.`            | [Append and Prepend](#append-and-prepend-text-fields)                                 |
| Email                  | Contact `Email`                 | `ada@acme.com`                                             | [Validation Pattern and value limits](#validation-pattern-and-value-limits)           |
| Phone                  | Contact `Phone`                 | `(415) 555-0100`                                           | [Blank CSV cells](#blank-csv-cells)                                                   |
| URL                    | Account `Website`               | `https://acme.com`                                         | [Overflow Action](#overflow-action)                                                   |
| Picklist               | Account `Rating`                | `Cold` (must match a Setup picklist value exactly)         | [Replace and Keep Existing](#replace-and-keep-existing)                               |
| Multi-Select Picklist  | Contact `Interests__c`          | `Webinar;Demo Request` (selections joined by `;`)          | [Add Values and Remove Values](#add-values-and-remove-values-multi-select-picklists)  |
| Checkbox               | Contact `DoNotCall`             | `true` or `false`                                          | [True If Either and True If Both](#true-if-either-and-true-if-both-checkboxes)        |
| Number (whole)         | Account `NumberOfEmployees`     | `250`                                                      | [Validation Pattern and value limits](#validation-pattern-and-value-limits)           |
| Number (decimal)       | Contact `Satisfaction_Score__c` | `4.5`                                                      | [Add and Subtract](#add-and-subtract-numbers)                                         |
| Currency               | Account `AnnualRevenue`         | `1200000` (no currency symbol or commas)                   | [Add and Subtract](#add-and-subtract-numbers)                                         |
| Percent                | Opportunity `Probability`       | `90` (not `0.9`)                                           | [Add and Subtract](#add-and-subtract-numbers)                                         |
| Date                   | Opportunity `CloseDate`         | `2026-09-30` (`YYYY-MM-DD`)                                | [Use Later and Use Earlier](#use-later-and-use-earlier-dates)                         |
| Date/Time              | Contact `Last_Contacted__c`     | `2026-08-21T14:30:00Z`                                     | [Use Later and Use Earlier](#use-later-and-use-earlier-dates)                         |
| Lookup / Master-Detail | Contact `AccountId`             | `Acme Corp` (matched by name, with Lookup Match Field set) | [Lookup Match Field](#lookup-match-field)                                             |

## Existing Value Action at a glance

**Existing Value Action** (`ExistingValueAction__c`) decides what happens when the target record already has a value in that field (Update and Upsert only). Insert never has an existing value, so this setting has nothing to act on.

| Existing Value Action | Works on                                                            | What it does                                                                                        |
| --------------------- | ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `REPLACE`             | Any field                                                           | Use the CSV value as-is. This is the default.                                                       |
| `KEEP_EXISTING`       | Any field                                                           | Keep the Salesforce value; ignore the CSV cell.                                                     |
| `APPEND`              | Text, Text Area, Email, Phone, URL, Picklist, Multi-Select Picklist | Add the CSV value after the existing value, with a separator between them.                          |
| `PREPEND`             | Same as Append                                                      | Add the CSV value before the existing value, with a separator between them.                         |
| `ADD_VALUES`          | Multi-Select Picklist                                               | Add the CSV selections to whatever is already selected.                                             |
| `REMOVE_VALUES`       | Multi-Select Picklist                                               | Remove the CSV selections from whatever is already selected.                                        |
| `ADD`                 | Number, Currency, Percent                                           | Add the CSV number to the existing number.                                                          |
| `SUBTRACT`            | Number, Currency, Percent                                           | Subtract the CSV number from the existing number.                                                   |
| `USE_LATER`           | Date, Date/Time                                                     | Keep whichever date is later — existing or incoming.                                                |
| `USE_EARLIER`         | Date, Date/Time                                                     | Keep whichever date is earlier — existing or incoming.                                              |
| `TRUE_IF_EITHER`      | Checkbox                                                            | Turn the checkbox on if either value is checked.                                                    |
| `TRUE_IF_BOTH`        | Checkbox                                                            | Turn the checkbox on only if both values are checked.                                               |
| `CUSTOM`              | Whatever your Apex class supports                                   | Runs your own class instead. See [Write and register an extension](../developer/custom-handler.md). |

Setting an action a field doesn't support — `ADD` on a Text field, for example — fails that row with a clear error instead of silently doing nothing.

## Replace and Keep Existing

**Use case:** Your sales team hand-curates Account `Rating` in Salesforce. A weekly firmographic import shouldn't be allowed to overwrite their judgment call, no matter what the data vendor says.

| Setting                         | Value                            |
| ------------------------------- | -------------------------------- |
| Existing Value Action           | `KEEP_EXISTING`                  |
| Existing `Rating` on the record | `Hot`                            |
| CSV cell for `rating`           | `Cold`                           |
| Result                          | `Hot` — the CSV value is ignored |

**Use case:** An ordinary firmographic import should overwrite Account `Rating` with whatever the file says, because in this process the file is the source of truth.

| Setting                         | Value                       |
| ------------------------------- | --------------------------- |
| Existing Value Action           | `REPLACE` (the default)     |
| Existing `Rating` on the record | `Hot`                       |
| CSV cell for `rating`           | `Cold`                      |
| Result                          | `Cold` — the CSV value wins |

## Append and Prepend (text fields)

**Use case:** A weekly call-note file has one row per Account and one `call_note` column. The Account `Description` should keep the older notes and add the new note at the bottom instead of replacing the whole field.

| Setting               | Value                                                                                         |
| --------------------- | --------------------------------------------------------------------------------------------- |
| Existing Value Action | `APPEND`                                                                                      |
| Text Separator        | `NEW_LINE`                                                                                    |
| Duplicate Text Action | `SKIP` — if Friday's file gets uploaded twice, the second run doesn't add the same note again |

Bulk Record Upload joins the text already in the CSV cell. It does not add a date or a name. Format each note as `date — initials: text` in the source file if that is how the Account description should look.

| Upload                                        | CSV cell for `call_note`                                                | `Description` after this upload                                                                           |
| --------------------------------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Week 1 (field starts empty)                   | `2026-08-07 — PK: Renewed for another 3 years, champion is now the VP.` | `2026-08-07 — PK: Renewed for another 3 years, champion is now the VP.`                                   |
| Week 2 (a different team member)              | `2026-08-14 — JT: Left voicemail re: upcoming QBR, no callback yet.`    | Week 1's line, then `2026-08-14 — JT: Left voicemail re: upcoming QBR, no callback yet.` on the next line |
| Week 3                                        | `2026-08-21 — PK: QBR confirmed for next Tuesday.`                      | Weeks 1–2, then `2026-08-21 — PK: QBR confirmed for next Tuesday.` on the next line                       |
| Week 3's file gets uploaded again by accident | same as Week 3                                                          | unchanged — the exact same line already exists, so `SKIP` leaves it alone                                 |

**Text Separator** options: `SPACE`, `NEW_LINE`, `COMMA_SPACE` (`, `), `SEMICOLON_SPACE` (`; `), `NONE`, or `CUSTOM` (reads **Custom Separator**, `CustomSeparator__c`, exactly as typed, including any spaces). **Duplicate Text Action** is `SKIP` (leave the value alone if the incoming text is already there), `KEEP` (add it again anyway), or `REJECT` (fail the row instead — useful if a repeat upload should stop and get looked at, not quietly succeed).

**Use case:** The newest note should appear at the top of `Description`. Use the same weekly file and column, but choose Prepend instead of Append.

| Setting               | Value      |
| --------------------- | ---------- |
| Existing Value Action | `PREPEND`  |
| Text Separator        | `NEW_LINE` |
| Duplicate Text Action | `SKIP`     |

| Upload                      | CSV cell for `call_note`                                                | `Description` after this upload                                                                           |
| --------------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Week 1 (field starts empty) | `2026-08-07 — PK: Renewed for another 3 years, champion is now the VP.` | `2026-08-07 — PK: Renewed for another 3 years, champion is now the VP.`                                   |
| Week 2                      | `2026-08-14 — JT: Left voicemail re: upcoming QBR, no callback yet.`    | `2026-08-14 — JT: Left voicemail re: upcoming QBR, no callback yet.`, then Week 1's line on the next line |
| Week 3                      | `2026-08-21 — PK: QBR confirmed for next Tuesday.`                      | `2026-08-21 — PK: QBR confirmed for next Tuesday.`, then Weeks 2–1 below it, newest first                 |

Append and Prepend also work on Multi-Select Picklist fields — they join the raw `;`-separated text, the same as any other text field. For set behavior instead (add or remove individual selections without duplicates), use Add Values or Remove Values below.

## Add Values and Remove Values (multi-select picklists)

**Use case:** A marketing list-upload adds `Interests__c` selections from a webinar sign-up sheet without wiping out interests a prospect already had, and without ending up with the same interest listed twice.

| Setting                  | Value                                                          |
| ------------------------ | -------------------------------------------------------------- |
| Existing Value Action    | `ADD_VALUES`                                                   |
| Existing `Interests__c`  | `Newsletter;Webinar`                                           |
| CSV cell for `interests` | `Webinar;Demo Request`                                         |
| Result                   | `Newsletter;Webinar;Demo Request` — `Webinar` isn't duplicated |

**Use case:** A prospect unsubscribes from webinar invitations. A suppression-list upload should remove that one interest without touching anything else they're signed up for.

| Setting                  | Value                                                                                                        |
| ------------------------ | ------------------------------------------------------------------------------------------------------------ |
| Existing Value Action    | `REMOVE_VALUES`                                                                                              |
| Existing `Interests__c`  | `Newsletter;Webinar`                                                                                         |
| CSV cell for `interests` | `Webinar;Demo Request`                                                                                       |
| Result                   | `Newsletter` — `Webinar` is removed, and `Demo Request` (which wasn't selected anyway) has nothing to remove |

## Add and Subtract (numbers)

**Use case:** A returns-processing file should reduce Account `AnnualRevenue` by a refunded amount, not overwrite the whole figure with just the refund.

| Setting                       | Value      |
| ----------------------------- | ---------- |
| Existing Value Action         | `SUBTRACT` |
| Existing `AnnualRevenue`      | `50000`    |
| CSV cell for `annual_revenue` | `1200`     |
| Result                        | `48800`    |

**Use case:** A new-orders file should increase Account `AnnualRevenue` by each new deal's amount, on top of whatever revenue was already on file.

| Setting                       | Value   |
| ----------------------------- | ------- |
| Existing Value Action         | `ADD`   |
| Existing `AnnualRevenue`      | `50000` |
| CSV cell for `annual_revenue` | `1200`  |
| Result                        | `51200` |

Works the same way on Percent fields — a weekly Opportunity `Probability` adjustment file could `ADD` or `SUBTRACT` a few points instead of overwriting a value someone already adjusted in Salesforce.

## Use Later and Use Earlier (dates)

**Use case:** Several teams upload Opportunity data throughout the week. A `CloseDate` should only ever move later as a deal firms up — an older, stale file re-uploaded by mistake shouldn't be able to drag it back earlier.

| Setting                   | Value                                                             |
| ------------------------- | ----------------------------------------------------------------- |
| Existing Value Action     | `USE_LATER`                                                       |
| Existing `CloseDate`      | `2026-09-30`                                                      |
| CSV cell for `close_date` | `2026-08-15`                                                      |
| Result                    | `2026-09-30` — the later date wins, so the CSV value is discarded |

**Use case:** Legal tracks a contract's original signed date. If a more accurate record turns up later — the countersigned copy was actually dated a day earlier than what got typed in first — the field should only ever move earlier, never later.

| Setting                            | Value                                |
| ---------------------------------- | ------------------------------------ |
| Existing Value Action              | `USE_EARLIER`                        |
| Existing `Contract_Signed_Date__c` | `2026-06-10`                         |
| CSV cell for `signed_date`         | `2026-06-09`                         |
| Result                             | `2026-06-09` — the earlier date wins |

Both actions work the same way on Date and Date/Time fields.

## True If Either and True If Both (checkboxes)

**Use case:** A "do not contact" flag should turn on the moment any source — a compliance export, a support case, a manual list — says a contact opted out, and should never be flipped back off by a bulk file that doesn't know about the opt-out.

| Setting                    | Value            |
| -------------------------- | ---------------- |
| Existing Value Action      | `TRUE_IF_EITHER` |
| Existing `DoNotCall`       | `false`          |
| CSV cell for `do_not_call` | `true`           |
| Result                     | `true`           |

**Use case:** A `Verified_Contact__c` checkbox should only stay true while two independent data sources — say, a CRM sync and a quarterly manual audit — both currently confirm the contact is good. If either one stops agreeing, the flag should drop, not stay stuck on from an earlier upload.

| Setting                        | Value                                                             |
| ------------------------------ | ----------------------------------------------------------------- |
| Existing Value Action          | `TRUE_IF_BOTH`                                                    |
| Existing `Verified_Contact__c` | `true`                                                            |
| CSV cell for `verified`        | `false`                                                           |
| Result                         | `false` — one source no longer confirms it, so the flag turns off |

## Custom (your own Apex class)

**Use case:** None of the built-in actions fit — for example, keeping whichever of two text values is longer, or a merge rule specific to your business that no built-in action covers.

This framework ships one working example class, `BulkRecordUploadLongerTextStrategy`, which keeps whichever of the existing or incoming text is longer. Point a column at it directly, no Apex writing required to try this:

| Setting                     | Value                                                                           |
| --------------------------- | ------------------------------------------------------------------------------- |
| Existing Value Action       | `CUSTOM`                                                                        |
| Custom Merge Strategy Class | `BulkRecordUploadLongerTextStrategy`                                            |
| Existing `Description`      | `Short note.`                                                                   |
| CSV cell for `description`  | `A much longer note with more detail than before.`                              |
| Result                      | `A much longer note with more detail than before.` — the longer of the two wins |

The class name is checked the moment the process configuration is saved — a typo or a class that doesn't exist is caught immediately, before any file is ever uploaded, instead of failing partway through a real upload.

To write your own instead of using the shipped example, name your own Apex class the same way — **Custom Merge Strategy Class** just needs the exact name of any Apex class already deployed to your org that implements the framework's merge interface. See [Write and register an extension](../developer/custom-handler.md) for the full class you'd write and how to register it.

## Blank CSV cells

**Blank CSV Action** (`BlankValueAction__c`) decides what an empty cell does, independently of Existing Value Action:

| Blank CSV Action   | What happens to an empty cell                                                                     |
| ------------------ | ------------------------------------------------------------------------------------------------- |
| `IGNORE` (default) | Leave the Salesforce field exactly as it is.                                                      |
| `CLEAR`            | Set the Salesforce field to blank.                                                                |
| `REJECT`           | Fail the row.                                                                                     |
| `DEFAULT`          | Use **Default Value** (`DefaultValue__c`) instead, parsed the same way an uploaded cell would be. |

**Use case:** A vendor's export leaves `Phone` blank for contacts who never provided one. Rather than fail those rows, or wipe out a phone number already on file, the process should just leave the existing value in Salesforce alone.

| Setting              | Value                        |
| -------------------- | ---------------------------- |
| Blank CSV Action     | `IGNORE`                     |
| Existing `Phone`     | `(415) 555-0100`             |
| CSV cell for `phone` | _(empty)_                    |
| Result               | `(415) 555-0100` — unchanged |

**Use case:** `Rating` is required on every Account this process creates, but the source file sometimes leaves it blank for a brand-new lead nobody has qualified yet. Rather than fail those rows, give them a safe starting value.

| Setting               | Value     |
| --------------------- | --------- |
| Blank CSV Action      | `DEFAULT` |
| Default Value         | `Warm`    |
| CSV cell for `rating` | _(empty)_ |
| Result                | `Warm`    |

**Use case:** A vendor feed sometimes sends a blank `Website` for accounts it has no data on. Leaving Salesforce untouched isn't safe here — a blank cell should actually clear out a stale website from a previous vendor.

| Setting                | Value                                |
| ---------------------- | ------------------------------------ |
| Blank CSV Action       | `CLEAR`                              |
| Existing `Website`     | `https://old-domain-example.com`     |
| CSV cell for `website` | _(empty)_                            |
| Result                 | _(blank)_ — the old value is removed |

**Use case:** `Email` must never go blank on a Contact import — a missing email means the export itself is broken and the row needs to be fixed at the source, not silently skipped.

| Setting              | Value                                                |
| -------------------- | ---------------------------------------------------- |
| Blank CSV Action     | `REJECT`                                             |
| CSV cell for `email` | _(empty)_                                            |
| Result               | row fails, instead of saving a Contact with no email |

## Overflow Action

**Overflow Action** (`OverflowAction__c`) decides what happens when a value — including the result of an Append or Prepend — is longer than the Salesforce field allows:

| Overflow Action    | What happens                                                                                   |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| `REJECT` (default) | Fail the row.                                                                                  |
| `TRUNCATE`         | Cut the value at the exact character limit.                                                    |
| `TRUNCATE_AT_WORD` | Back off to the end of the last whole word that still fits, so a word doesn't get cut in half. |

**Use case:** An import appends a note to a field with a 12-character limit for this example, and the combined text runs over. The row should be saved with a clean cutoff instead of failing outright.

| Setting                                 | Value                                                                                     |
| --------------------------------------- | ----------------------------------------------------------------------------------------- |
| Existing Value Action                   | `APPEND`, Text Separator `SPACE`                                                          |
| Overflow Action                         | `TRUNCATE_AT_WORD`                                                                        |
| Existing value                          | `Existin`                                                                                 |
| CSV cell                                | `g Overflow`                                                                              |
| Joined text before the limit is applied | `Existin g Overflow` (18 characters)                                                      |
| Result at a 12-character limit          | `Existin g` — the last whole word that fits, instead of a mid-word cut like `Existin g O` |

## Trim Value, Case Action, and Blank Tokens

These three clean up a cell before anything else — before the blank check, before Default Value, before any merge — so a messy CSV export doesn't need to be fixed by hand first.

| Setting                               | Options                                                                                                                                                                |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Trim Value (`TrimValue__c`, checkbox) | Removes leading and trailing spaces                                                                                                                                    |
| Case Action (`CaseAction__c`)         | `NONE` (default), `UPPER`, `LOWER`, `TITLE`                                                                                                                            |
| Blank Tokens (`BlankTokens__c`)       | A comma-separated list of cell values to treat as blank, in addition to a truly empty cell — for example `N/A, NULL, -`. Matching ignores case and surrounding spaces. |

**Use case:** A CSV exported from another system has stray spaces around every value, inconsistent capitalization, and marks missing data with the literal text `N/A` instead of leaving the cell empty.

| Column   | Setting                                      | CSV cell   | Result                                                                |
| -------- | -------------------------------------------- | ---------- | --------------------------------------------------------------------- |
| `name`   | Trim Value checked, Case Action `UPPER`      | `  acme  ` | `ACME`                                                                |
| `status` | Blank Tokens `N/A`, Blank CSV Action `CLEAR` | `N/A`      | field cleared — treated as blank, not saved as the literal text `N/A` |

On a Multi-Select Picklist, Case Action applies to each selected value on its own, so `;` is never treated as part of a word: `red;dark blue` with Case Action `TITLE` becomes `Red;Dark Blue`, not `Red;Dark blue`.

## Validation Pattern and value limits

Two independent checks fail a row before it reaches Salesforce, applied after the cleanup above and before any merge decision. Both are checked when the process configuration is saved, so a typo in the pattern, or a minimum greater than a maximum, is caught immediately — not on the next upload.

**Use case:** A contact-import file sometimes has an `Email` value that does not match the configured
email pattern or a `NumberOfEmployees` placeholder outside the allowed range. Each value should fail
only its row instead of changing other data or blocking valid rows.

| Setting                                                           | Value                                          | CSV cell       | Result                                 |
| ----------------------------------------------------------------- | ---------------------------------------------- | -------------- | -------------------------------------- |
| Validation Pattern (`ValidationPattern__c`): `[^@]+@[^@]+\.[^@]+` | must match the whole cell, not just part of it | `not-an-email` | row fails, naming the field            |
| Maximum Value (`MaxValue__c`): `100000`                           | Number, Currency, or Percent only              | `999999999`    | row fails — value is above the maximum |

Set **Minimum Value** and **Maximum Value** (`MinValue__c` / `MaxValue__c`) alone or together.

## Source Template (calculated columns)

**Use case:** A CSV export only has separate `first_name` and `last_name` columns, but Account `Description` should read as one combined line — without asking whoever builds the export file to pre-combine them.

**Source Template** (`SourceTemplate__c`) builds one column's value from other columns in the same upload, instead of reading it from its own CSV header. Write `{columnKey}` tokens using the CSV Column Header of another configured column in the same process.

| Column configured             | CSV Column Header                        | Source Template            |
| ----------------------------- | ---------------------------------------- | -------------------------- |
| First name                    | `first_name`                             | _(none — read directly)_   |
| Last name                     | `last_name`                              | _(none — read directly)_   |
| Combined name → `Description` | _(none — this column has no CSV header)_ | `{first_name} {last_name}` |

| CSV row                                    | Result                                 |
| ------------------------------------------ | -------------------------------------- |
| `first_name = Ada`, `last_name = Lovelace` | `Description` is set to `Ada Lovelace` |

A few things worth knowing before you use this:

- A token can only reference an ordinary uploaded column, never another Source Template column — you can't chain two calculated columns together.
- If a referenced cell is missing, the token is replaced with empty text rather than failing the row.
- The composed value still goes through Trim Value, Case Action, Blank Tokens, Validation Pattern, and the Existing Value Action merge, exactly like a column read straight from the CSV.
- A Source Template column never appears in the downloadable CSV template, and its **Required** checkbox is never enforced against the uploaded headers — the CSV was never expected to contain it in the first place.

## Lookup Match Field

**Use case:** A Contact-import CSV comes from a system that knows company names, not Salesforce record Ids. Asking the export owner to look up an 18-character Account Id for every row isn't realistic — matching on the name the file already has is.

By default, a lookup or master-detail column expects the exact 15- or 18-character Salesforce Id in the CSV cell. **Lookup Match Field** (`LookupMatchField__c`) lets the CSV carry something more familiar instead.

| Setting                     | Value                                                                          |
| --------------------------- | ------------------------------------------------------------------------------ |
| Field API Name              | `AccountId`                                                                    |
| Lookup Match Field          | `Name`                                                                         |
| CSV cell for `account_name` | `Acme Corp`                                                                    |
| Result                      | `AccountId` is set to the Id of the Account record whose `Name` is `Acme Corp` |

If a value matches zero Account records, or more than one, only the rows using that value fail — the rest of the upload still goes through. This works with one bounded query per lookup column per chunk of rows, not one query per row.

**Lookup Match Field** must name a filterable field on the lookup's target object. Polymorphic lookups — a field that can point to more than one kind of object, like Task `WhoId`, which can be a Lead or a Contact — are not supported, because there's no single target object to match against.

## What Update, Upsert, Insert, and Delete each load

Update and Upsert read every configured existing value in one bounded query per chunk of rows, so none of the behaviors above cost an extra query per row. Insert never reads existing values, so Existing Value Action has nothing to compare against. Delete doesn't use any of these settings.

## Related

See [Configure field behaviors](../admin/configure-field-behaviors.md), [Write and register an extension](../developer/custom-handler.md), and [the three-object demonstration kit](../examples/demo/README.md) for a working set of processes to try these settings in your own org.
