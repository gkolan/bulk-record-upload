import { readFileSync, writeFileSync } from "node:fs";

const path = "specs/artifacts/behavior-parity-matrix.md";
const decisions = new Map([
  [
    "Process availability",
    [
      "Preserve",
      "No migration; inactive and missing processes remain unavailable"
    ]
  ],
  [
    "Preview access",
    [
      "Preserve",
      "No migration; permission identity moves to the full product-name policy"
    ]
  ],
  ["Operations", ["Preserve", "No migration for supported objects and fields"]],
  [
    "Match key",
    [
      "Change",
      "Processes must select one validated accessible key; ambiguous or unsuitable keys fail configuration validation"
    ]
  ],
  [
    "Field behaviors",
    [
      "Change",
      "Only the versioned behavior/type matrix ships; unsupported combinations fail validation instead of being attempted"
    ]
  ],
  [
    "Default values",
    [
      "Preserve",
      "Uploaded nonblank values continue to win over configured defaults"
    ]
  ],
  [
    "`Return_All_Fields`",
    [
      "Change",
      "Rename the setting to configured result fields; it never expands beyond the process projection"
    ]
  ],
  [
    "Default columns",
    ["Preserve", "No migration within the configured projection"]
  ],
  [
    "CSV header labels",
    [
      "Change",
      "Use stable configured column keys with optional display labels; translated labels are not field identity"
    ]
  ],
  [
    "Template order",
    [
      "Change",
      "Use explicit process order after fixed package result columns; no implicit ID/Name priority"
    ]
  ],
  [
    "CSV parsing",
    [
      "Preserve",
      "Existing compatible UTF-8 comma CSVs remain valid within documented limits"
    ]
  ],
  [
    "Status lifecycle",
    [
      "Change",
      "Add VALIDATING and use uppercase stable values; migrate reports and automation to the version 1 status reference"
    ]
  ],
  [
    "Start time",
    [
      "Change",
      "Replace the overwritten field with separate submission, processing-start, and completion timestamps"
    ]
  ],
  [
    "Row errors",
    [
      "Preserve",
      "One-based physical data-row correlation remains stable; message text becomes redacted and reason-code driven"
    ]
  ],
  [
    "Audit files",
    [
      "Preserve",
      "Files remain the audit medium but gain explicit ownership and retention rules"
    ]
  ],
  [
    "Upload history",
    [
      "Change",
      "Location text is display context, not an authorization boundary; history is access-filtered and cursor/page bounded"
    ]
  ],
  [
    "Sharing groups",
    [
      "Change",
      "Raw group names are replaced by validated project configuration and least-privilege share handling"
    ]
  ],
  [
    "Archive",
    [
      "Preserve",
      "Archive continues to hide ordinary history but does not change retention"
    ]
  ],
  [
    "Standard handler",
    [
      "Preserve",
      "Generic configured-object processing remains, implemented through a compact projection"
    ]
  ],
  [
    "Custom handlers",
    [
      "Change",
      "Replace administrator class names with versioned trusted registry keys"
    ]
  ],
  [
    "Completion event",
    [
      "Remove",
      "No Core completion event ships; remove event metadata, triggers, permissions, examples, and subscriber claims"
    ]
  ],
  [
    "Upload request limits",
    [
      "Change",
      "Adopt the version 1 hard limits and server-side enforcement documented in ADR-0002"
    ]
  ],
  [
    "Dynamic defaults",
    [
      "Change",
      "Accept typed defaults only for configured fields; `$recordId` may resolve only from trusted component context"
    ]
  ],
  [
    "Result downloads",
    [
      "Preserve",
      "Keep Salesforce Files downloads but require ordinary Files authorization and safe missing-file handling"
    ]
  ]
]);

const output = readFileSync(path, "utf8")
  .split(/\r?\n/)
  .map((line) => {
    if (!line.startsWith("|")) return line;
    const cells = line.split("|").map((cell) => cell.trim());
    const decision = decisions.get(cells[1]);
    if (!decision) return line;
    cells[4] = decision[0];
    cells[6] = decision[1];
    return `| ${cells.slice(1, -1).join(" | ")} |`;
  })
  .join("\n");

writeFileSync(path, output, "utf8");
console.log(`Finalized Step 2 decisions in ${path}`);
