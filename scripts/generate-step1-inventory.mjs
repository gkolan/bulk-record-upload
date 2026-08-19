import { readdirSync, statSync, writeFileSync } from "node:fs";
import { extname, relative, resolve, sep } from "node:path";

const referenceRoot = resolve("research/bulkRecordUpload");
const outputPath = resolve(
  "docs/evidence/01-baseline-and-inventory/reference-artifact-inventory.csv"
);
const excludedTrees = new Set([
  ".claude",
  ".husky",
  ".sf",
  ".sfdx",
  ".vscode",
  "node_modules",
  "test-results"
]);

function walk(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    if (
      entry.isDirectory() &&
      directory === referenceRoot &&
      excludedTrees.has(entry.name)
    ) {
      return [];
    }
    const fullPath = resolve(directory, entry.name);
    return entry.isDirectory() ? walk(fullPath) : [fullPath];
  });
}

function classify(path) {
  const normalized = path.split(sep).join("/");
  const name = normalized.split("/").at(-1);
  const extension = extname(name).toLowerCase();

  if (name === ".DS_Store") {
    return [
      "OS-generated file",
      "Generated",
      "None",
      "Discard",
      "Not a source input",
      "None"
    ];
  }
  if (name === "BulkRecordUpload_Platform_Deck.pptx") {
    return [
      "Reference presentation binary",
      "Documentation",
      "Documentation maintainer",
      "Discard",
      "No source license found",
      "None"
    ];
  }
  if (name === "CLAUDE.md") {
    return [
      "Reference agent instructions",
      "Repository local",
      "None",
      "Discard",
      "No source license found",
      "None"
    ];
  }
  if (normalized.startsWith("force-app/")) {
    if (extension === ".cls") {
      const isTest =
        /Test\.cls$/.test(name) ||
        name === "BulkRecordUploadTestDataFactory.cls";
      return [
        isTest
          ? "Reference Apex test behavior"
          : "Reference Apex runtime behavior",
        isTest ? "Tests" : "Core runtime",
        isTest ? "Test maintainer" : "Runtime owner",
        "Reimplement",
        "No source license found; behavior-only clean-room input",
        "Salesforce platform"
      ];
    }
    if (extension === ".trigger") {
      return [
        "Reference trigger behavior",
        "Optional integration or core runtime",
        "Runtime owner",
        "Reimplement",
        "No source license found; behavior-only clean-room input",
        "Apex and referenced object"
      ];
    }
    if (normalized.includes("/lwc/")) {
      return [
        "Reference Lightning UI behavior",
        "Core UI",
        "UI owner",
        "Reimplement",
        "No source license found; behavior-only clean-room input",
        "LWC, Apex DTOs, SLDS"
      ];
    }
    if (normalized.includes("/profiles/")) {
      return [
        "Reference broad profile access",
        "Security",
        "Security owner",
        "Discard",
        "No source license found; profiles are not portable least-privilege inputs",
        "Referenced metadata"
      ];
    }
    if (normalized.includes("/customMetadata/") && name.includes(".Test_")) {
      return [
        "Reference test configuration record",
        "Tests",
        "Test maintainer",
        "Reimplement",
        "No source license found; behavior-only clean-room input",
        "Custom Metadata schema"
      ];
    }
    if (normalized.includes("/customMetadata/")) {
      return [
        "Reference example configuration record",
        "Examples",
        "Documentation and test maintainers",
        "Reimplement",
        "No source license found; behavior-only clean-room input",
        "Custom Metadata schema"
      ];
    }
    return [
      "Reference Salesforce metadata behavior",
      "Core metadata",
      "Metadata owner",
      "Reimplement",
      "No source license found; behavior-only clean-room input",
      "Metadata API and referenced components"
    ];
  }
  if (
    normalized.startsWith("sample/") ||
    normalized.startsWith("scripts/test-data/")
  ) {
    return [
      "Reference CSV example or test case",
      "Examples and tests",
      "Test maintainer",
      "Reimplement",
      "No source license found; create synthetic project-owned data",
      "Approved CSV contract"
    ];
  }
  if (normalized.startsWith("scripts/")) {
    return [
      "Reference repository automation",
      "Tooling",
      "Release maintainer",
      "Reimplement",
      "No source license found; reproduce only required behavior",
      "Reviewed CLI workflow"
    ];
  }
  if (normalized.startsWith("manifest/")) {
    return [
      "Reference deployment manifest",
      "Packaging",
      "Release maintainer",
      "Reimplement",
      "No source license found; rebuild from approved package boundary",
      "Approved production metadata"
    ];
  }
  if (normalized.startsWith("config/")) {
    return [
      "Reference scratch-org definition",
      "Tooling",
      "Release maintainer",
      "Reimplement",
      "No source license found; rebuild from project org policy",
      "Salesforce scratch-org features"
    ];
  }
  if (
    [
      "package.json",
      "package-lock.json",
      "eslint.config.js",
      "jest.config.js",
      ".prettierrc",
      ".prettierignore"
    ].includes(name)
  ) {
    return [
      "Reference JavaScript tool configuration",
      "Tooling",
      "Release maintainer",
      "Replace",
      "Dependency licenses must be reviewed independently",
      "Node.js toolchain"
    ];
  }
  if ([".gitignore", ".forceignore"].includes(name)) {
    return [
      "Reference ignore configuration",
      "Repository",
      "Release maintainer",
      "Replace",
      "No source license found; derive from project boundaries",
      "Repository and Salesforce CLI"
    ];
  }
  if (name === "sfdx-project.json") {
    return [
      "Reference Salesforce project configuration",
      "Packaging",
      "Release maintainer",
      "Reimplement",
      "No source license found; derive from approved package contract",
      "Salesforce DX"
    ];
  }
  if (extension === ".md" || extension === ".txt") {
    return [
      "Reference documentation or planning claim",
      "Documentation evidence",
      "Documentation maintainer",
      "Reimplement",
      "No source license found; facts require source reconciliation and project-owned prose",
      "Approved product and runtime contracts"
    ];
  }
  return [
    "Unclassified reference artifact",
    "Review required",
    "Step 1 inventory owner",
    "Discard",
    "No source license found",
    "None"
  ];
}

function csv(value) {
  return `"${String(value).replaceAll('"', '""')}"`;
}

const header = [
  "reference_path",
  "bytes",
  "observed_purpose",
  "boundary",
  "owner",
  "disposition",
  "provenance_decision",
  "dependencies"
];
const rows = walk(referenceRoot)
  .sort()
  .map((fullPath) => {
    const path = relative(referenceRoot, fullPath).split(sep).join("/");
    return [path, statSync(fullPath).size, ...classify(path)]
      .map(csv)
      .join(",");
  });

writeFileSync(
  outputPath,
  `${header.map(csv).join(",")}\n${rows.join("\n")}\n`,
  "utf8"
);
console.log(
  `Wrote ${rows.length} reviewed inventory rows to ${relative(resolve("."), outputPath)}`
);
