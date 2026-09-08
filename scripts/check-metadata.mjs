import { existsSync, readFileSync, readdirSync } from "node:fs";
import { basename, relative, resolve, sep } from "node:path";

const root = resolve("force-app/main/default");
const manifest = readFileSync(resolve("manifest/package.xml"), "utf8");
const errors = [];
const retiredConfigurationFields = [
  "Bulk_Record_Upload_Process__mdt.ConfigurationVersion__c",
  "Bulk_Record_Upload_Process__mdt.ProcessingMode__c",
  "Bulk_Record_Upload_Process__mdt.ProcessorKey__c",
  "Bulk_Record_Upload_Process_Field__mdt.CustomMergeStrategyClass__c"
];
const retainedExistingValueActions = new Set([
  "REPLACE",
  "KEEP_EXISTING",
  "APPEND",
  "PREPEND",
  "ADD_VALUES",
  "REMOVE_VALUES",
  "ADD",
  "SUBTRACT",
  "USE_LATER",
  "USE_EARLIER",
  "TRUE_IF_EITHER",
  "TRUE_IF_BOTH"
]);
const retiredConfigurationIdentifiers = [
  "ConfigurationVersion__c",
  "ProcessingMode__c",
  "ProcessorKey__c",
  "CustomMergeStrategyClass__c",
  "CUSTOM_APEX",
  "BulkRecordUploadProcessor",
  "BulkRecordUploadProcessors",
  "BulkRecordUploadMergeStrategyRegistry",
  "BulkRecordUploadLongerTextStrategy"
];
const checkedTextExtensions = new Set([
  ".apex",
  ".cls",
  ".js",
  ".json",
  ".md",
  ".xml",
  ".yaml",
  ".yml"
]);

function walk(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = resolve(directory, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

function values(xml, element) {
  return [
    ...xml.matchAll(
      new RegExp(`<${element}\\b[^>]*>([\\s\\S]*?)</${element}>`, "g")
    )
  ].map((match) => match[1].trim());
}

function requireManifestMember(member, source) {
  if (!values(manifest, "members").includes(member)) {
    errors.push(`${source}: missing manifest member ${member}`);
  }
}

function requireSameValues(name, expected, actual) {
  const missing = [...expected].filter((value) => !actual.has(value));
  const extra = [...actual].filter((value) => !expected.has(value));
  if (missing.length || extra.length) {
    errors.push(
      `${name}: unexpected values; missing=${missing.join(",") || "none"}; extra=${extra.join(",") || "none"}`
    );
  }
}

const publicContractFiles = [
  ...walk(root),
  ...walk(resolve("examples")),
  ...walk(resolve("docs")),
  ...walk(resolve("scripts")),
  resolve("README.md"),
  resolve("manifest/package.xml")
].filter(
  (file) =>
    checkedTextExtensions.has(file.slice(file.lastIndexOf("."))) &&
    basename(file) !== "check-metadata.mjs" &&
    !file.includes(`${sep}docs${sep}evidence${sep}`)
);

for (const file of publicContractFiles) {
  const contents = readFileSync(file, "utf8");
  for (const identifier of retiredConfigurationIdentifiers) {
    if (contents.includes(identifier)) {
      errors.push(
        `${relative(resolve("."), file).split(sep).join("/")}: retired configuration identifier ${identifier}`
      );
    }
  }
}

for (const field of retiredConfigurationFields) {
  if (values(manifest, "members").includes(field)) {
    errors.push(`manifest/package.xml: retired configuration field ${field}`);
  }
  const [objectName, fieldName] = field.split(".");
  const path = resolve(
    root,
    "objects",
    objectName,
    "fields",
    `${fieldName}.field-meta.xml`
  );
  if (existsSync(path)) {
    errors.push(`${field}: retired configuration metadata still exists`);
  }
}

const existingValueActionPath = resolve(
  root,
  "objects",
  "Bulk_Record_Upload_Process_Field__mdt",
  "fields",
  "ExistingValueAction__c.field-meta.xml"
);
if (!existsSync(existingValueActionPath)) {
  errors.push("ExistingValueAction__c: required retained field is missing");
} else {
  const existingValueActionXml = readFileSync(existingValueActionPath, "utf8");
  const actions = new Set(
    [
      ...existingValueActionXml.matchAll(
        /<value>[\s\S]*?<fullName>([^<]+)<\/fullName>[\s\S]*?<\/value>/g
      )
    ].map((match) => match[1])
  );
  requireSameValues(
    "ExistingValueAction__c",
    retainedExistingValueActions,
    actions
  );
}

const files = walk(root);
for (const file of files) {
  if (!file.endsWith(".xml")) continue;
  const xml = readFileSync(file, "utf8");
  const source = relative(root, file).split(sep).join("/");

  if (!/^<\?xml version="1\.0" encoding="UTF-8"\s*\?>/i.test(xml)) {
    errors.push(`${source}: missing canonical XML declaration`);
  }

  for (const description of values(xml, "description")) {
    if (description.length > 255) {
      errors.push(`${source}: description exceeds 255 characters`);
    }
  }
  for (const helpText of values(xml, "inlineHelpText")) {
    if (helpText.length > 255) {
      errors.push(`${source}: inline help exceeds 255 characters`);
    }
  }
  if (
    values(xml, "caseSensitive").includes("true") &&
    !values(xml, "unique").includes("true")
  ) {
    errors.push(`${source}: caseSensitive requires unique=true`);
  }
  if (file.endsWith(".customPermission-meta.xml")) {
    for (const dependency of values(xml, "requiredPermission")) {
      if (
        !dependency.includes("<customPermission>") ||
        !dependency.includes("<dependency>")
      ) {
        errors.push(`${source}: malformed Custom Permission dependency`);
      }
    }
  }

  if (file.endsWith(".field-meta.xml")) {
    if (!values(xml, "description").length)
      errors.push(`${source}: field description missing`);
    if (!values(xml, "inlineHelpText").length)
      errors.push(`${source}: field inline help missing`);
    const parts = source.split("/");
    requireManifestMember(
      `${parts[1]}.${basename(file, ".field-meta.xml")}`,
      source
    );
  } else if (file.endsWith(".object-meta.xml")) {
    if (!values(xml, "description").length)
      errors.push(`${source}: object description missing`);
    requireManifestMember(basename(file, ".object-meta.xml"), source);
  } else if (file.endsWith(".permissionset-meta.xml")) {
    if (!values(xml, "description").length)
      errors.push(`${source}: permission-set description missing`);
    requireManifestMember(basename(file, ".permissionset-meta.xml"), source);
  } else if (file.endsWith(".customPermission-meta.xml")) {
    requireManifestMember(basename(file, ".customPermission-meta.xml"), source);
  } else if (file.endsWith(".tab-meta.xml")) {
    requireManifestMember(basename(file, ".tab-meta.xml"), source);
  } else if (file.endsWith(".app-meta.xml")) {
    requireManifestMember(basename(file, ".app-meta.xml"), source);
  } else if (file.endsWith(".listView-meta.xml")) {
    const parts = source.split("/");
    requireManifestMember(
      `${parts[1]}.${basename(file, ".listView-meta.xml")}`,
      source
    );
  } else if (file.endsWith(".flexipage-meta.xml")) {
    requireManifestMember(basename(file, ".flexipage-meta.xml"), source);
  }
}

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

console.log(
  `Metadata checks passed for ${files.length} source files with explicit manifest coverage.`
);
