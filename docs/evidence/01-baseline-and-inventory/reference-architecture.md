# Observed reference architecture

> [!NOTE]
> On this page, see the reference implementation boundaries observed in Apex, Lightning Web Components, metadata, and Salesforce Files before the project defines its replacement architecture.

## Runtime landscape

```mermaid
%%{init: {"flowchart": {"nodeSpacing": 55, "rankSpacing": 60}} }%%
flowchart LR
    U["Uploader"] --> WRAP["Internal or community wrapper LWC"]
    WRAP --> FORM["Upload form LWC"]
    WRAP --> STATUS["Status and history LWC"]
    WRAP --> GUIDE["In-app guide LWC"]

    subgraph apex["REFERENCE APEX"]
        CTRL["BulkRecordUploadController"]
        CSV["BulkRecordUploadCSVParser"]
        BATCH["BulkRecordUploadBatchBase"]
        STANDARD["BulkRecordUploadStandardBatch"]
        LOGTRIGGER["Upload-log trigger handler"]
        EVENT["Generic event handler"]
    end

    subgraph data["SALESFORCE DATA AND CONFIGURATION"]
        CONFIG[("Process and field-behavior CMT")]
        FILES[("Salesforce Files")]
        LOG[("Bulk_Record_Upload_Log__c")]
        BUSINESS[("Configured business object")]
        PE[("GlobalPlatformEvent__e")]
    end

    FORM -->|"processUpload"| CTRL
    STATUS -->|"getUploadLogs"| CTRL
    WRAP -->|"getConfig"| CTRL
    CTRL --> CSV
    CTRL --> CONFIG
    CTRL --> FILES
    CTRL --> LOG
    CTRL --> BATCH
    BATCH --> STANDARD
    STANDARD --> BUSINESS
    BATCH --> FILES
    BATCH --> LOG
    LOG --> LOGTRIGGER
    LOGTRIGGER -. "No-op extension point" .-> PE
    PE --> EVENT

    style apex fill:#f5f3ff,stroke:#6d28d9,stroke-dasharray:5
    style data fill:#ecfeff,stroke:#0e7490,stroke-dasharray:5
    style CTRL fill:#ddd6fe,stroke:#6d28d9,color:#1f2937
    style CSV fill:#ddd6fe,stroke:#6d28d9,color:#1f2937
    style BATCH fill:#ddd6fe,stroke:#6d28d9,color:#1f2937
    style STANDARD fill:#ddd6fe,stroke:#6d28d9,color:#1f2937
    style LOGTRIGGER fill:#fde68a,stroke:#b45309,color:#1f2937
    style EVENT fill:#fde68a,stroke:#b45309,color:#1f2937
```

```text
Uploader
   |
   v
Wrapper LWC ---> Upload form ---> Controller ---> CSV parser
     |                                 |  |  |
     +-------> Status/history          |  |  +--> Salesforce Files
     +-------> In-app guide            |  +-----> Upload log
                                       +--------> Configuration CMT
                                                    |
Controller ---> Batch base ---> Standard handler ---> Business records
                    |  |
                    |  +--> Results file
                    +-----> Upload-log status
                               |
                               +--> No-op integration/event extension points
```

The diagram records responsibilities, not an approved target design. The controller combines configuration, authorization checks, file persistence, log persistence, sharing, handler dispatch, and history queries. The batch base combines orchestration, conversion, field behavior, DML, result generation, files, and logging and exceeds the project's 500-line limit.

## Evidence

- `research/bulkRecordUpload/force-app/main/default/classes/BulkRecordUploadController.cls`: `getConfig`, `processUpload`, and `getUploadLogs`.
- `research/bulkRecordUpload/force-app/main/default/classes/BulkRecordUploadBatchBase.cls`: batch lifecycle, field behavior, partial DML, Files, and log updates.
- `research/bulkRecordUpload/force-app/main/default/classes/BulkRecordUploadStandardBatch.cls`: dynamic object resolution and generic DML record construction.
- `research/bulkRecordUpload/force-app/main/default/lwc/`: wrapper, form, status, guide, and utility components.
- `research/bulkRecordUpload/force-app/main/default/objects/` and `customMetadata/`: configuration, upload log, event, and example/test records.

## Related

- [Observed data flow and threat boundaries](reference-data-flow-and-threat-boundaries.md)
- [Step 1 evidence summary](README.md)
