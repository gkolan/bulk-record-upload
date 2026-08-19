import { existsSync, readFileSync, readdirSync } from "node:fs";
import { dirname, extname, relative, resolve } from "node:path";

const roots = [
  "README.md",
  "docs",
  "CONTRIBUTING.md",
  "SECURITY.md",
  "SUPPORT.md"
];
const errors = [];
const files = [];

function collect(path) {
  if (!existsSync(path)) return;
  const entries = readdirSync(path, { withFileTypes: true });
  for (const entry of entries) {
    const child = resolve(path, entry.name);
    if (entry.isDirectory()) collect(child);
    else if (extname(entry.name) === ".md") files.push(child);
  }
}

for (const root of roots) {
  const path = resolve(root);
  if (!existsSync(path)) errors.push(`${root}: missing required documentation`);
  else if (extname(path) === ".md") files.push(path);
  else collect(path);
}

for (const file of files) {
  const source = readFileSync(file, "utf8");
  const shown = relative(process.cwd(), file);
  if (!source.startsWith("# ")) errors.push(`${shown}: missing H1 title`);
  if (
    shown.startsWith(`docs${process.platform === "win32" ? "\\" : "/"}`) &&
    !shown.includes(
      `${process.platform === "win32" ? "\\" : "/"}evidence${process.platform === "win32" ? "\\" : "/"}`
    )
  ) {
    if (!/> \[!NOTE\][\s\S]{0,240}On this page,/m.test(source))
      errors.push(`${shown}: missing required On this page note`);
  }
  const headings = [...source.matchAll(/^#{1,6} (.+)$/gm)].map(
    (match) => match[1]
  );
  const duplicates = headings.filter(
    (heading, index) => headings.indexOf(heading) !== index
  );
  if (duplicates.length)
    errors.push(`${shown}: duplicate heading ${duplicates[0]}`);
  for (const match of source.matchAll(
    /\[[^\]]+\]\((?!https?:|mailto:|#)([^)#]+)(?:#[^)]+)?\)/g
  )) {
    const target = resolve(dirname(file), decodeURIComponent(match[1]));
    if (!existsSync(target)) errors.push(`${shown}: broken link ${match[1]}`);
  }
}

const runtimeContract = readFileSync(
  resolve("force-app/main/default/classes/BulkRecordUploadRuntimeContract.cls"),
  "utf8"
);
const limitsSource = readFileSync(resolve("docs/admin/limits.md"), "utf8");
const chunkLimit = runtimeContract.match(/MAX_CHUNKS\s*=\s*(\d+)/)?.[1];
const documentedChunks = limitsSource.match(
  /\| Durable chunks\s*\|\s*(\d+)\s*\|/
)?.[1];
if (!chunkLimit || chunkLimit !== documentedChunks) {
  errors.push(
    `docs/admin/limits.md: durable chunk limit ${documentedChunks ?? "missing"} does not match Apex ${chunkLimit ?? "missing"}`
  );
}

const numericLimits = new Map(
  [
    ...runtimeContract.matchAll(
      /public static final Integer (MAX|MIN)_([A-Z_]+)\s*=\s*(\d+);/g
    )
  ].map((match) => [`${match[1]}_${match[2]}`, match[3]])
);
const documentedLimitChecks = [
  ["MAX_CSV_ROWS", /\| Data rows\s*\|\s*([\d,]+)\s*\|/, 1],
  ["MAX_CSV_COLUMNS", /\| Configured columns\s*\|\s*(\d+)\s*\|/, 1],
  [
    "MAX_CSV_CELL_CHARACTERS",
    /\| Cell length\s*\|\s*([\d,]+) characters\s*\|/,
    1
  ],
  ["MIN_CHUNK_ROWS", /\| Batch\/chunk rows\s*\|\s*(\d+)–\d+\s*\|/, 1],
  ["MAX_CHUNK_ROWS", /\| Batch\/chunk rows\s*\|\s*\d+–(\d+)\s*\|/, 1]
];
for (const [constant, pattern, multiplier] of documentedLimitChecks) {
  const documented = limitsSource.match(pattern)?.[1]?.replaceAll(",", "");
  const runtime = numericLimits.get(constant);
  if (
    !documented ||
    !runtime ||
    Number(documented) * multiplier !== Number(runtime)
  ) {
    errors.push(
      `docs/admin/limits.md: ${constant} documentation does not match the runtime contract`
    );
  }
}

const statusesSource = readFileSync(
  resolve("docs/reference/statuses-and-results.md"),
  "utf8"
);
for (const match of runtimeContract.matchAll(
  /public static final String REASON_[A-Z_]+\s*=\s*'([^']+)'/g
)) {
  if (!statusesSource.includes(`\`${match[1]}\``)) {
    errors.push(
      `docs/reference/statuses-and-results.md: missing package reason code ${match[1]}`
    );
  }
}

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}
console.log(`Documentation checks passed for ${files.length} Markdown files.`);
