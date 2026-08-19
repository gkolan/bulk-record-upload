import { existsSync, readFileSync, readdirSync } from "node:fs";
import { basename, relative, resolve, sep } from "node:path";

const root = resolve("force-app/main/default");
const manifest = readFileSync(resolve("manifest/package.xml"), "utf8");
const errors = [];

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
