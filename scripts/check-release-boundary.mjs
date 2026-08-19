import { readFileSync, readdirSync } from "node:fs";
import { extname, relative, resolve } from "node:path";

const forbiddenPaths = [
  "research/",
  "development-standards/",
  ".sf/",
  "coverage/",
  "code-analyzer/"
];
const sensitivePatterns = [
  /(?:password|access[_-]?token|client[_-]?secret)\s*[:=]\s*["'][^"']+/i,
  /test-[a-z0-9]+@example\.com/i
];
const orgIdPattern = /00D[A-Za-z0-9]{12,15}/;
const errors = [];

function walk(path) {
  const entries = readdirSync(path, { withFileTypes: true });
  const result = [];
  for (const entry of entries) {
    if (
      [
        ".git",
        "node_modules",
        "research",
        "development-standards",
        ".sf",
        "coverage",
        "code-analyzer"
      ].includes(entry.name)
    )
      continue;
    const child = resolve(path, entry.name);
    if (entry.isDirectory()) result.push(...walk(child));
    else result.push(child);
  }
  return result;
}

const trackedCandidates = walk(process.cwd());
for (const file of trackedCandidates) {
  const shown = relative(process.cwd(), file).replaceAll("\\", "/");
  if (forbiddenPaths.some((prefix) => shown.startsWith(prefix)))
    errors.push(`${shown}: forbidden release path`);
  if (
    ![
      ".md",
      ".json",
      ".js",
      ".mjs",
      ".yml",
      ".yaml",
      ".xml",
      ".cls",
      ".html",
      ".css",
      ".txt"
    ].includes(extname(file))
  )
    continue;
  const source = readFileSync(file, "utf8");
  for (const pattern of sensitivePatterns) {
    if (pattern.test(source))
      errors.push(`${shown}: possible secret or org identifier`);
  }
  if (shown !== "package-lock.json" && orgIdPattern.test(source))
    errors.push(`${shown}: possible org identifier`);
}

const manifest = readFileSync(resolve("manifest/package.xml"), "utf8");
for (const term of [
  "Slack",
  "Webhook",
  "PlatformEvent",
  "FlowHandler",
  "bulkRecordUploadGuide"
])
  if (manifest.includes(term))
    errors.push(`manifest/package.xml: unsupported member ${term}`);

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}
console.log("Release-boundary and sensitive-data checks passed.");
