import { existsSync, readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";

const errors = [];
const core = resolve("force-app");
const manifest = readFileSync("manifest/package.xml", "utf8");
const deferredPatterns = [
  /Slack/i,
  /Webhook/i,
  /GlobalPlatformEvent/i,
  /SlackEnvelope/i,
  /FlowHandler/i,
  /status.?color/i
];

function walk(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = resolve(directory, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

const coreFiles = walk(core);
for (const file of coreFiles) {
  const contents = readFileSync(file, "utf8");
  for (const pattern of deferredPatterns) {
    if (pattern.test(file) || pattern.test(contents))
      errors.push(`Deferred Core surface: ${file} (${pattern})`);
  }
  if (/bulkRecordUploadGuide/i.test(file))
    errors.push(`Long-form guide component in Core: ${file}`);
  if (
    (file.endsWith(".flexipage-meta.xml") || file.endsWith(".app-meta.xml")) &&
    /(?:Account|Contact|Opportunity)_[A-Za-z_]*Demo/.test(contents)
  ) {
    errors.push(
      `Core page or application depends on optional demo metadata: ${file}`
    );
  }
}

if (manifest.includes("<members>*</members>"))
  errors.push("Core manifest contains a wildcard member.");
if (
  manifest.includes("research/") ||
  manifest.includes("development-standards/")
) {
  errors.push("Core manifest references a local-input directory.");
}

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

console.log(
  `Package boundary passed: ${coreFiles.length} Core files; no wildcard, deferred integration, long-form guide, or local-input member.`
);
