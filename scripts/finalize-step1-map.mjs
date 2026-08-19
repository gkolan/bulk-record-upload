import { readFileSync, writeFileSync } from "node:fs";

const path = "specs/artifacts/research-to-production-map.md";
const source = readFileSync(path, "utf8");
const lines = source.split(/\r?\n/).map((line) => {
  if (
    !line.startsWith("| `") &&
    !line.startsWith("| Upload") &&
    !line.startsWith("| Apex") &&
    !line.startsWith("| Internal") &&
    !line.startsWith("| Configuration") &&
    !line.startsWith("| Example") &&
    !line.startsWith("| Slack") &&
    !line.startsWith("| Flow")
  ) {
    return line;
  }

  const cells = line.split("|").map((cell) => cell.trim());
  if (cells.length < 10) return line;

  const artifact = cells[1];
  const isDeferred =
    /Slack|Flow-handler|GlobalPlatformEvent|Upload-log trigger/.test(artifact);
  const isDiscarded = /Platform_Deck|SPEC\.md|SPEC_BUG|BUG_REPORT/.test(
    artifact
  );

  if (cells[5] === "Pending")
    cells[5] = isDeferred ? "Defer" : isDiscarded ? "Discard" : "Reimplement";
  if (cells[6] === "Pending") {
    cells[6] = isDiscarded
      ? "No source license found; excluded"
      : "No source license found; behavior-only clean-room input";
  }
  if (cells[8] === "Pending") {
    cells[8] = isDeferred
      ? "Product and integration owners"
      : artifact.includes("test") || artifact.includes("Test")
        ? "Test maintainer"
        : artifact.includes("LWC")
          ? "UI and test maintainers"
          : artifact.includes("metadata") || artifact.includes("log object")
            ? "Metadata, security, and test owners"
            : "Runtime and test owners";
  }

  return `| ${cells.slice(1, -1).join(" | ")} |`;
});

const marker =
  "Step 1 must expand this seed table to one row per inventoried artifact.";
const replacement =
  "The [reference artifact inventory](../../docs/evidence/01-baseline-and-inventory/reference-artifact-inventory.csv) is the authoritative one-row-per-file appendix to this responsibility map. " +
  marker;

writeFileSync(path, lines.join("\n").replace(marker, replacement), "utf8");
console.log(`Finalized ${path}`);
