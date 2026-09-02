import { readFileSync } from "node:fs";

// Keep shared-org validation scoped to the test classes in the Core manifest.
const manifest = readFileSync("manifest/package.xml", "utf8");
const apex = [...manifest.matchAll(/<types>([\s\S]*?)<\/types>/g)].find(
  ([, contents]) => /<name>ApexClass<\/name>/.test(contents)
);
const tests = [...(apex?.[1] ?? "").matchAll(/<members>(\w+Test)<\/members>/g)]
  .map(([, name]) => name)
  .sort();
if (!tests.length)
  throw new Error("No Apex test classes found in the Core manifest");
console.log(tests.join("\n"));
