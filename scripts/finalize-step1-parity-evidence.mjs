import { readFileSync, writeFileSync } from "node:fs";

const path = "specs/artifacts/behavior-parity-matrix.md";
const evidence = new Map([
  [
    "Process availability",
    "`BulkRecordUploadController.getConfig`; `BulkRecordUploadConfig__mdt.IsActive__c`"
  ],
  [
    "Preview access",
    "`BulkRecordUploadController.getConfig`; `Preview_Custom_Permission__c`"
  ],
  ["Operations", "`BulkRecordUploadBatchBase.execute`; `Operation_Type__c`"],
  [
    "Match key",
    "`BulkRecordUploadStandardBatch.queryCurrentByExternalKey`; field-behavior match-key metadata"
  ],
  [
    "Field behaviors",
    "`BulkRecordUploadBatchBase.applyField` and typed behavior helpers"
  ],
  [
    "Default values",
    "`BulkRecordUploadBatchBase.ensureDefaultValuesLoaded`; `bulkRecordUploadInternal` defaults inputs"
  ],
  [
    "`Return_All_Fields`",
    "`BulkRecordUploadBatchBase.setUploadedHeaders`; `Return_All_Fields__c`"
  ],
  [
    "Default columns",
    "`BulkRecordUploadBatchBase.setDefaultColumns`; `Show_Default_Columns__c`"
  ],
  [
    "CSV header labels",
    "`BulkRecordUploadController.processUpload`; `bulkRecordUploadUtils.checkDuplicateLabels`"
  ],
  [
    "Template order",
    "`bulkRecordUploadUtils.downloadTemplate`; configured field-behavior records"
  ],
  [
    "CSV parsing",
    "`BulkRecordUploadCSVParser.parse`; `BulkRecordUploadCSVParserTest`"
  ],
  [
    "Status lifecycle",
    "`BulkRecordUploadBatchBase.start/finish`; `Status__c.field-meta.xml`"
  ],
  [
    "Start time",
    "`BulkRecordUploadController.processUpload`; `BulkRecordUploadBatchBase.start`"
  ],
  [
    "Row errors",
    "`BulkRecordUploadBatchBase.markScopeAsError/captureSaveResults`; batch tests"
  ],
  [
    "Audit files",
    "`BulkRecordUploadController.processUpload`; `BulkRecordUploadBatchBase.finish`"
  ],
  [
    "Upload history",
    "`BulkRecordUploadController.getUploadLogs`; `bulkRecordUploadStatus`"
  ],
  [
    "Sharing groups",
    "`BulkRecordUploadController.processUpload`; `Sharing_Groups__c`"
  ],
  [
    "Archive",
    "`BulkRecordUploadController.getUploadLogs`; `IsArchived__c`; controller archive test"
  ],
  [
    "Standard handler",
    "`BulkRecordUploadStandardBatch.getSObjectType/buildSelectFieldSet`"
  ],
  [
    "Custom handlers",
    "`BulkRecordUploadController.processUpload`; `BulkRecordUploadBatchHandler`"
  ],
  [
    "Completion event",
    "`BulkRecordUploadLogTriggerHandler` no-op methods; `GlobalPlatformEvent__e` metadata"
  ]
]);

const output = readFileSync(path, "utf8")
  .split(/\r?\n/)
  .map((line) => {
    if (!line.startsWith("|")) return line;
    const cells = line.split("|").map((cell) => cell.trim());
    const observed = evidence.get(cells[1]);
    if (observed && cells[3] === "Pending Step 1 evidence") cells[3] = observed;
    return observed ? `| ${cells.slice(1, -1).join(" | ")} |` : line;
  })
  .join("\n");

writeFileSync(path, output, "utf8");
console.log(`Finalized Step 1 evidence in ${path}`);
