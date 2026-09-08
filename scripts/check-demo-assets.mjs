import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import xmlPlugin from "@prettier/plugin-xml";
import * as prettier from "prettier";

const root = process.cwd();
const temporaryRoot = fs.mkdtempSync(
  path.join(os.tmpdir(), "bru-demo-assets-")
);
const failures = [];

function filesBelow(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs
    .readdirSync(directory, { recursive: true, withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => path.join(entry.parentPath, entry.name));
}

async function normalized(relativePath, contents) {
  if (!relativePath.endsWith(".xml")) return contents.replaceAll("\r\n", "\n");
  return prettier.format(contents, { parser: "xml", plugins: [xmlPlugin] });
}

try {
  const generatorSource = path.join(
    root,
    "scripts",
    "generate-demo-assets.mjs"
  );
  const temporaryGenerator = path.join(
    temporaryRoot,
    "generate-demo-assets.mjs"
  );
  fs.copyFileSync(generatorSource, temporaryGenerator);
  const generation = spawnSync(process.execPath, [temporaryGenerator], {
    cwd: temporaryRoot,
    encoding: "utf8"
  });
  if (generation.status !== 0) {
    throw new Error(
      generation.stderr || generation.stdout || "Demo generation failed."
    );
  }

  const generatedRoots = ["examples/main/default", "docs/examples/demo"];
  let compared = 0;
  for (const generatedRoot of generatedRoots) {
    const candidateRoot = path.join(temporaryRoot, generatedRoot);
    for (const candidatePath of filesBelow(candidateRoot)) {
      const relativePath = path.relative(temporaryRoot, candidatePath);
      const repositoryPath = path.join(root, relativePath);
      compared += 1;
      if (!fs.existsSync(repositoryPath)) {
        failures.push(`missing ${relativePath}`);
        continue;
      }
      const expected = await normalized(
        relativePath,
        fs.readFileSync(candidatePath, "utf8")
      );
      const actual = await normalized(
        relativePath,
        fs.readFileSync(repositoryPath, "utf8")
      );
      if (expected !== actual) failures.push(`stale ${relativePath}`);
    }
  }

  if (failures.length > 0) {
    console.error("Generated demo asset parity failed:");
    for (const failure of failures) console.error(`- ${failure}`);
    process.exitCode = 1;
  } else {
    console.log(`Generated demo asset parity passed for ${compared} files.`);
  }
} finally {
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
}
