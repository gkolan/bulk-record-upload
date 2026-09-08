import { existsSync, readFileSync, readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { extname, relative, resolve } from "node:path";

const forbiddenPaths = [
  "research/",
  "development-standards/",
  "specs/",
  "bugs/",
  "docs/evidence/",
  "docs/internal/",
  "docs/research/",
  "internal/",
  ".agents/",
  ".codex/",
  ".claude/",
  ".sf/",
  ".sfdx/",
  "coverage/",
  "report/",
  "reports/",
  "test-results/",
  "review-artifacts/",
  "artifacts/",
  "tmp/",
  "temp/",
  "code-analyzer/"
];
const localFiles = new Set([
  "AGENTS.md",
  "CLAUDE.md",
  "docs/research-assessment.md",
  "scripts/generate-step1-inventory.mjs",
  "scripts/finalize-step1-map.mjs",
  "scripts/finalize-step1-parity-evidence.mjs",
  "scripts/finalize-step2-parity-decisions.mjs",
  "scripts/apex/hello.apex",
  "scripts/soql/account.soql",
  "manifest/package-empty.xml"
]);
const sensitivePatterns = [
  /(?:password|access[_-]?token|client[_-]?secret)\s*[:=]\s*["'][^"']+/i,
  /test-[a-z0-9]+@example\.com/i
];
const orgIdPattern = /00D[A-Za-z0-9]{12,15}/;
const errors = [];

function checkNpmArchive() {
  const npmExecutable = process.env.npm_execpath ? process.execPath : "npm";
  const npmArguments = process.env.npm_execpath
    ? [process.env.npm_execpath]
    : [];
  const output = execFileSync(
    npmExecutable,
    [...npmArguments, "pack", "--dry-run", "--json", "--ignore-scripts"],
    {
      encoding: "utf8",
      env: { ...process.env, npm_config_cache: resolve(".npm-cache") },
      stdio: ["ignore", "pipe", "pipe"]
    }
  );
  const archive = JSON.parse(output)[0];
  const archivedFiles = archive.files.map((entry) =>
    entry.path.replaceAll("\\", "/")
  );
  for (const file of archivedFiles) {
    if (
      forbiddenPaths.some((prefix) => file.startsWith(prefix)) ||
      localFiles.has(file) ||
      file.includes("/node_modules/") ||
      /^manifest\/destructiveChanges-.*\.xml$/u.test(file)
    ) {
      errors.push(`${file}: forbidden npm archive path`);
    }
  }
  if (archive.entryCount > 1000) {
    errors.push(
      `npm archive contains ${archive.entryCount} files; expected at most 1000`
    );
  }
  if (archive.unpackedSize > 10 * 1024 * 1024) {
    errors.push(
      `npm archive expands to ${archive.unpackedSize} bytes; expected at most 10 MiB`
    );
  }
}

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
        "internal",
        ".sf",
        "coverage",
        "report",
        "reports",
        "test-results",
        "review-artifacts",
        "artifacts",
        "tmp",
        "temp",
        "code-analyzer"
      ].includes(entry.name)
    )
      continue;
    const child = resolve(path, entry.name);
    const shown = relative(process.cwd(), child).replaceAll("\\", "/");
    if (
      forbiddenPaths.some((prefix) => `${shown}/`.startsWith(prefix)) ||
      localFiles.has(shown) ||
      /^manifest\/destructiveChanges-.*\.xml$/u.test(shown)
    )
      continue;
    if (entry.isDirectory()) result.push(...walk(child));
    else result.push(child);
  }
  return result;
}

let trackedCandidates;
if (existsSync(resolve(".git"))) {
  const gitFiles = (args) =>
    execFileSync("git", ["ls-files", "-z", ...args], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"]
    })
      .split("\0")
      .filter(Boolean);
  for (const file of gitFiles([
    "--cached",
    "--ignored",
    "--exclude-standard"
  ])) {
    errors.push(
      `${file}: ignored file is still tracked; remove it from the Git index`
    );
  }
  trackedCandidates = [
    ...new Set(gitFiles(["--cached", "--others", "--exclude-standard"]))
  ]
    .map((file) => resolve(file))
    .filter((file) => existsSync(file));
} else {
  // ZIP downloads do not contain Git metadata.
  trackedCandidates = walk(process.cwd());
}
for (const file of trackedCandidates) {
  const shown = relative(process.cwd(), file).replaceAll("\\", "/");
  if (
    forbiddenPaths.some((prefix) => shown.startsWith(prefix)) ||
    localFiles.has(shown) ||
    /^manifest\/destructiveChanges-.*\.xml$/u.test(shown)
  )
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
      ".txt",
      ".csv",
      ".apex",
      ".soql"
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

checkNpmArchive();

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}
console.log("Release-boundary and sensitive-data checks passed.");
