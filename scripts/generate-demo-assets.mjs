import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const metadataDir = path.join(root, "examples", "main", "default");
const customMetadataDir = path.join(metadataDir, "customMetadata");
const csvDir = path.join(root, "docs", "examples", "demo");
fs.rmSync(customMetadataDir, { recursive: true, force: true });
fs.mkdirSync(customMetadataDir, { recursive: true });
fs.mkdirSync(csvDir, { recursive: true });

const objects = {
  Account: {
    label: "Account",
    insert: [
      ["Account Name", "Name", "STRING", true],
      ["Description", "Description", "TEXTAREA"],
      ["Phone", "Phone", "PHONE"],
      ["Website", "Website", "URL"],
      ["Employees", "NumberOfEmployees", "INTEGER"],
      ["Annual Revenue", "AnnualRevenue", "CURRENCY"]
    ],
    update: [
      [
        "External Key",
        "BulkRecordUploadDemoExternalId__c",
        "STRING",
        true,
        true
      ],
      ["Description", "Description", "TEXTAREA"],
      ["Phone", "Phone", "PHONE"],
      ["Employees", "NumberOfEmployees", "INTEGER"]
    ]
  },
  Contact: {
    label: "Contact",
    insert: [
      ["Last Name", "LastName", "STRING", true],
      ["First Name", "FirstName", "STRING"],
      ["Email", "Email", "EMAIL"],
      ["Phone", "Phone", "PHONE"],
      ["Birthdate", "Birthdate", "DATE"],
      ["Email Opt Out", "HasOptedOutOfEmail", "BOOLEAN"]
    ],
    update: [
      [
        "External Key",
        "BulkRecordUploadDemoExternalId__c",
        "STRING",
        true,
        true
      ],
      ["First Name", "FirstName", "STRING"],
      ["Email", "Email", "EMAIL"],
      ["Birthdate", "Birthdate", "DATE"],
      ["Email Opt Out", "HasOptedOutOfEmail", "BOOLEAN"]
    ]
  },
  Opportunity: {
    label: "Opportunity",
    insert: [
      ["Opportunity Name", "Name", "STRING", true],
      ["Stage", "StageName", "PICKLIST", true],
      ["Close Date", "CloseDate", "DATE", true],
      ["Amount", "Amount", "CURRENCY"],
      ["Probability", "Probability", "PERCENT"],
      ["Next Step", "NextStep", "STRING"],
      ["Description", "Description", "TEXTAREA"]
    ],
    update: [
      [
        "External Key",
        "BulkRecordUploadDemoExternalId__c",
        "STRING",
        true,
        true
      ],
      ["Stage", "StageName", "PICKLIST"],
      ["Close Date", "CloseDate", "DATE"],
      ["Amount", "Amount", "CURRENCY"],
      ["Probability", "Probability", "PERCENT"],
      ["Next Step", "NextStep", "STRING"]
    ]
  }
};

const operations = ["INSERT", "UPDATE", "UPSERT", "DELETE"];
const objectCodes = { Account: "Acct", Contact: "Cont", Opportunity: "Opp" };
const operationCodes = {
  INSERT: "Ins",
  UPDATE: "Upd",
  UPSERT: "Ups",
  DELETE: "Del"
};
const esc = (value) =>
  String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;");
const value = (field, type, body) =>
  `    <values>\n        <field>${field}</field>\n        <value xsi:type="xsd:${type}" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">${esc(body)}</value>\n    </values>`;
const customMetadata = (label, values) =>
  `<?xml version="1.0" encoding="UTF-8"?>\n<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">\n    <label>${label}</label>\n    <protected>false</protected>\n${values.join("\n")}\n</CustomMetadata>\n`;

for (const [objectApi, config] of Object.entries(objects)) {
  const objectDir = path.join(metadataDir, "objects", objectApi, "fields");
  fs.mkdirSync(objectDir, { recursive: true });
  fs.writeFileSync(
    path.join(objectDir, "BulkRecordUploadDemoExternalId__c.field-meta.xml"),
    `<?xml version="1.0" encoding="UTF-8"?>\n<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">\n    <fullName>BulkRecordUploadDemoExternalId__c</fullName>\n    <description>Stable synthetic key used only by the optional Bulk Record Upload demo processes.</description>\n    <externalId>true</externalId>\n    <inlineHelpText>Enter the synthetic key from the matching demo CSV file.</inlineHelpText>\n    <label>Bulk Record Upload Demo External ID</label>\n    <length>80</length>\n    <required>false</required>\n    <trackTrending>false</trackTrending>\n    <type>Text</type>\n    <unique>true</unique>\n</CustomField>\n`
  );

  for (const operation of operations) {
    const key = `${objectApi}_${operation[0]}${operation.slice(1).toLowerCase()}_Demo`;
    const processValues = [
      value("ObjectApiName__c", "string", objectApi),
      value("Operation__c", "string", operation),
      value("RowsPerBatch__c", "double", 100),
      value("RetentionDays__c", "double", 30),
      value("ConfigurationVersion__c", "double", 2),
      value("ProcessingMode__c", "string", "STANDARD_DML"),
      value("ProcessorKey__c", "string", "STANDARD_DML"),
      value("IsActive__c", "boolean", true)
    ];
    if (objectApi === "Contact" && operation === "INSERT") {
      processValues.push(
        value("RecordContextAction__c", "string", "DEFAULT_PARENT"),
        value("HostObjectApiName__c", "string", "Account"),
        value("RecordContextFieldApiName__c", "string", "AccountId")
      );
    }
    fs.writeFileSync(
      path.join(
        customMetadataDir,
        `Bulk_Record_Upload_Process.${key}.md-meta.xml`
      ),
      customMetadata(
        `${config.label} ${operation[0]}${operation.slice(1).toLowerCase()} Demo`,
        processValues
      )
    );

    let fields;
    if (operation === "INSERT") fields = config.insert;
    else if (operation === "DELETE")
      fields = [
        [
          "External Key",
          "BulkRecordUploadDemoExternalId__c",
          "STRING",
          true,
          true
        ]
      ];
    else fields = config.update;
    fields.forEach((field, index) => {
      const [header, api, , required = false, match = false] = field;
      const appendDemo =
        objectApi === "Account" &&
        operation === "UPDATE" &&
        api === "Description";
      const prependDemo =
        objectApi === "Opportunity" &&
        operation === "UPDATE" &&
        api === "NextStep";
      const existingAction = appendDemo
        ? "APPEND"
        : prependDemo
          ? "PREPEND"
          : "REPLACE";
      const separatorChoice = appendDemo
        ? "NEW_LINE"
        : prependDemo
          ? "SEMICOLON_SPACE"
          : "SPACE";
      const apiCode =
        api === "BulkRecordUploadDemoExternalId__c" ? "ExternalId" : api;
      const recordName = `${objectCodes[objectApi]}_${operationCodes[operation]}_${String(index + 1).padStart(2, "0")}_${apiCode}`;
      if (recordName.length > 40)
        throw new Error(
          `Custom Metadata record name exceeds 40 characters: ${recordName}`
        );
      const fieldValues = [
        value("ProcessDeveloperName__c", "string", key),
        value("CsvColumnHeader__c", "string", header),
        value("DisplayLabel__c", "string", header),
        value("FieldApiName__c", "string", api),
        value("ColumnOrder__c", "double", index + 1),
        value("ExistingValueAction__c", "string", existingAction),
        value("BlankValueAction__c", "string", required ? "REJECT" : "IGNORE"),
        value("TextSeparator__c", "string", separatorChoice),
        value("DuplicateTextAction__c", "string", "SKIP"),
        value("OverflowAction__c", "string", "REJECT"),
        value("IsRequired__c", "boolean", required),
        value("IsMatchField__c", "boolean", match),
        value(
          "IsUpsertExternalId__c",
          "boolean",
          operation === "UPSERT" && match
        ),
        value("IncludeInResult__c", "boolean", true),
        value("IsActive__c", "boolean", true)
      ];
      fs.writeFileSync(
        path.join(
          customMetadataDir,
          `Bulk_Record_Upload_Process_Field.${recordName}.md-meta.xml`
        ),
        customMetadata(`${config.label} ${operation} ${header}`, fieldValues)
      );
    });
  }
}

const csv = {
  Account_Insert_Demo: [
    "Account Name,Description,Phone,Website,Employees,Annual Revenue",
    "Bulk Upload CSV Account One,Created by insert demo,312-555-0101,https://example.test,25,125000",
    "Bulk Upload CSV Account Two,Created by insert demo,312-555-0102,https://example.test,50,250000"
  ],
  Account_Update_Demo: [
    "External Key,Description,Phone,Employees",
    "ACC-DEMO-001,Updated by update demo,312-555-0191,101",
    "ACC-DEMO-002,Updated by update demo,312-555-0192,202"
  ],
  Account_Upsert_Demo: [
    "External Key,Description,Phone,Employees",
    "ACC-DEMO-001,Updated by upsert demo,312-555-0181,111",
    "ACC-DEMO-NEW,Created by upsert demo,312-555-0182,12"
  ],
  Account_Delete_Demo: ["External Key", "ACC-DEMO-DELETE"],
  Contact_Insert_Demo: [
    "Last Name,First Name,Email,Phone,Birthdate,Email Opt Out",
    "CSV Contact One,Demo,csv.contact1@example.test,312-555-0201,1990-01-15,false",
    "CSV Contact Two,Demo,csv.contact2@example.test,312-555-0202,1992-06-30,true"
  ],
  Contact_Update_Demo: [
    "External Key,First Name,Email,Birthdate,Email Opt Out",
    "CON-DEMO-001,Updated,updated.contact1@example.test,1990-01-16,true",
    "CON-DEMO-002,Updated,updated.contact2@example.test,1992-07-01,false"
  ],
  Contact_Upsert_Demo: [
    "External Key,First Name,Email,Birthdate,Email Opt Out",
    "CON-DEMO-001,Upserted,upsert.contact1@example.test,1990-01-17,false",
    "CON-DEMO-NEW,Created,upsert.new@example.test,1995-05-05,true"
  ],
  Contact_Delete_Demo: ["External Key", "CON-DEMO-DELETE"],
  Opportunity_Insert_Demo: [
    "Opportunity Name,Stage,Close Date,Amount,Probability,Next Step,Description",
    "Bulk Upload CSV Opportunity One,Prospecting,2026-12-15,10000,10,Schedule discovery,Created by insert demo",
    "Bulk Upload CSV Opportunity Two,Qualification,2027-01-15,25000,20,Confirm requirements,Created by insert demo"
  ],
  Opportunity_Update_Demo: [
    "External Key,Stage,Close Date,Amount,Probability,Next Step",
    "OPP-DEMO-001,Qualification,2026-12-20,15000,25,Prepare proposal",
    "OPP-DEMO-002,Needs Analysis,2027-01-20,30000,35,Review needs"
  ],
  Opportunity_Upsert_Demo: [
    "External Key,Stage,Close Date,Amount,Probability,Next Step",
    "OPP-DEMO-001,Proposal/Price Quote,2026-12-22,17500,50,Send proposal",
    "OPP-DEMO-NEW,Prospecting,2027-02-15,5000,10,Schedule discovery"
  ],
  Opportunity_Delete_Demo: ["External Key", "OPP-DEMO-DELETE"]
};
for (const [key, lines] of Object.entries(csv))
  fs.writeFileSync(path.join(csvDir, `${key}.csv`), `${lines.join("\n")}\n`);
console.log(
  `Generated 12 processes, demo fields, and ${Object.keys(csv).length} CSV files.`
);
