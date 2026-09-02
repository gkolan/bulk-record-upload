import { existsSync, readFileSync, readdirSync } from "node:fs";
import { basename, resolve } from "node:path";

const classesDirectory = resolve("force-app/main/default/classes");
const manifest = readFileSync(resolve("manifest/package.xml"), "utf8");
const errors = [];

function valuesFromContract(source, prefix) {
  return new Set(
    [
      ...source.matchAll(
        new RegExp(
          `public static final String ${prefix}_[A-Z_]+ =(?:\\s*)'([^']+)'`,
          "g"
        )
      )
    ].map((match) => match[1])
  );
}

function valuesFromPicklist(path) {
  const source = readFileSync(resolve(path), "utf8");
  return new Set(
    [
      ...source.matchAll(
        /<value>[\s\S]*?<fullName>([^<]+)<\/fullName>[\s\S]*?<\/value>/g
      )
    ].map((match) => match[1])
  );
}

function requireSameValues(name, expected, actual) {
  const missing = [...expected].filter((value) => !actual.has(value));
  const extra = [...actual].filter((value) => !expected.has(value));
  if (missing.length || extra.length) {
    errors.push(
      `${name}: runtime/metadata value mismatch; missing=${missing.join(",") || "none"}; extra=${extra.join(",") || "none"}`
    );
  }
}

if (existsSync(classesDirectory)) {
  for (const entry of readdirSync(classesDirectory, { withFileTypes: true })) {
    if (!entry.isFile() || !entry.name.endsWith(".cls")) continue;
    const path = resolve(classesDirectory, entry.name);
    const source = readFileSync(path, "utf8");
    const className = basename(entry.name, ".cls");
    const lineCount = source.split(/\r?\n/).length;

    if (lineCount > 500)
      errors.push(
        `${entry.name}: ${lineCount} lines exceeds the 500-line limit`
      );
    if (!manifest.includes(`<members>${className}</members>`)) {
      errors.push(`${entry.name}: missing explicit ApexClass manifest member`);
    }
    if (/\b(System\.)?debug\s*\(/.test(source))
      errors.push(`${entry.name}: System.debug is forbidden`);
    if (/\b@future\b/i.test(source))
      errors.push(`${entry.name}: @future is forbidden`);

    const recordAccess =
      /\[[\s\S]*?\bSELECT\b/i.test(source) ||
      /\bDatabase\.(insert|update|upsert|delete)\s*\(/i.test(source) ||
      /(?:^|[;{}])\s*(insert|update|upsert|delete)\s+[A-Za-z_]/im.test(source);
    const explicitSharing =
      /\b(with|without|inherited)\s+sharing\s+(class|interface)\b/.test(source);
    if (recordAccess && !explicitSharing) {
      errors.push(
        `${entry.name}: record-accessing class lacks an explicit sharing declaration`
      );
    }
    // ADR-0004 (2026-08-19 amendment) permits Type.forName in exactly one
    // reviewed class: the package's one open extension seam. The name it
    // resolves comes only from a Bulk_Record_Upload_Extension__mdt record,
    // never CSV or free text, and is gated by an instanceof check before
    // use. Every other class stays subject to the blanket prohibition.
    const allowsDynamicType = className === "BulkRecordUploadExtensionRegistry";
    if (
      (/\bType\.forName\b/i.test(source) && !allowsDynamicType) ||
      /\bSELECT\s+\*\b/i.test(source)
    ) {
      errors.push(
        `${entry.name}: untrusted dynamic type or unbounded field selection`
      );
    }
    if (
      /Test\.cls$/i.test(entry.name) &&
      entry.name !== "BulkRecordUploadTestDataFactory.cls" &&
      /(?:^|[;{}])\s*(insert|update|upsert|delete)\s+[A-Za-z_]/im.test(source)
    ) {
      errors.push(
        `${entry.name}: reusable test DML must use BulkRecordUploadTestDataFactory`
      );
    }
  }
}

const contractPath = resolve(
  classesDirectory,
  "BulkRecordUploadRuntimeContract.cls"
);
if (!existsSync(contractPath)) {
  errors.push(
    "BulkRecordUploadRuntimeContract.cls: required runtime contract is missing"
  );
} else {
  const contract = readFileSync(contractPath, "utf8");
  requireSameValues(
    "Upload Status",
    valuesFromContract(contract, "STATUS"),
    valuesFromPicklist(
      "force-app/main/default/objects/Bulk_Record_Upload__c/fields/Status__c.field-meta.xml"
    )
  );
  requireSameValues(
    "Chunk Status",
    valuesFromContract(contract, "CHUNK"),
    valuesFromPicklist(
      "force-app/main/default/objects/Bulk_Record_Upload_Chunk__c/fields/Status__c.field-meta.xml"
    )
  );
}

for (const businessQueryOwner of [
  "BulkRecordUploadRecordResolver.cls",
  "BulkRecordUploadExistingValueMerger.cls"
]) {
  const source = readFileSync(
    resolve(classesDirectory, businessQueryOwner),
    "utf8"
  );
  if (/WITH\s+SYSTEM_MODE/i.test(source)) {
    errors.push(
      `${businessQueryOwner}: business-data queries must reject system mode`
    );
  }
}

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

console.log(
  "Apex architecture checks passed: manifest, size, sharing, stable-value parity, user-mode business queries, and forbidden-pattern rules."
);
