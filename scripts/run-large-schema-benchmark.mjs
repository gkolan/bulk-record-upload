import { performance } from "node:perf_hooks";

const SOURCE_FIELD_COUNT = 800;
const MAX_CONFIGURED_FIELDS = 100;
const ITERATIONS = 250;
const BYTE_BUDGET = 128 * 1024;
const TIME_BUDGET_MS = 50;

function descriptor(index) {
  const types = ["STRING", "DATE", "DECIMAL", "BOOLEAN", "REFERENCE"];
  return Object.freeze({
    apiName: `Synthetic_Field_${String(index).padStart(3, "0")}__c`,
    label: `Synthetic field ${index}`,
    type: types[index % types.length],
    createable: index % 11 !== 0,
    updateable: index % 13 !== 0,
    calculated: index % 17 === 0,
    encrypted: index % 29 === 0,
    referenceTo: index % 5 === 4 ? ["Account"] : []
  });
}

const schema = Object.freeze(
  Array.from({ length: SOURCE_FIELD_COUNT }, (_, index) =>
    descriptor(index + 1)
  )
);
const byName = new Map(schema.map((field) => [field.apiName, field]));

function project(configuredCount) {
  if (configuredCount < 1 || configuredCount > MAX_CONFIGURED_FIELDS) {
    throw new RangeError("Configured projection must contain 1-100 fields.");
  }
  return schema.slice(0, configuredCount).map((configured, index) => {
    const described = byName.get(configured.apiName);
    return {
      columnKey: `column_${index + 1}`,
      displayLabel: described.label,
      fieldApiName: described.apiName,
      fieldType: described.type,
      sequence: index + 1,
      canCreate: described.createable && !described.calculated,
      canUpdate: described.updateable && !described.calculated
    };
  });
}

function measure(configuredCount) {
  const started = performance.now();
  let result;
  for (let iteration = 0; iteration < ITERATIONS; iteration += 1) {
    result = project(configuredCount);
  }
  const elapsedMs = performance.now() - started;
  const bytes = Buffer.byteLength(JSON.stringify(result), "utf8");
  return {
    configuredFields: configuredCount,
    projectedFields: result.length,
    serializedBytes: bytes,
    meanProjectionMs: Number((elapsedMs / ITERATIONS).toFixed(4)),
    withinByteBudget: bytes <= BYTE_BUDGET,
    withinTimeBudget: elapsedMs / ITERATIONS <= TIME_BUDGET_MS
  };
}

const measurements = [5, 50, 100].map(measure);
let rejectsTwoHundred = false;
try {
  project(200);
} catch (error) {
  rejectsTwoHundred = error instanceof RangeError;
}

const output = {
  environment: {
    node: process.version,
    platform: process.platform,
    architecture: process.arch,
    iterations: ITERATIONS
  },
  sourceSchema: {
    kind: "synthetic-project-owned-projection-substitute",
    descriptorCount: schema.length,
    configuredFieldMaximum: MAX_CONFIGURED_FIELDS
  },
  budgets: { serializedBytes: BYTE_BUDGET, meanProjectionMs: TIME_BUDGET_MS },
  measurements,
  guards: {
    rejectsTwoHundred,
    neverProjectsAllSourceFields: measurements.every(
      ({ projectedFields }) => projectedFields <= MAX_CONFIGURED_FIELDS
    )
  }
};

if (
  !output.guards.rejectsTwoHundred ||
  !output.guards.neverProjectsAllSourceFields ||
  measurements.some(
    ({ withinByteBudget, withinTimeBudget }) =>
      !withinByteBudget || !withinTimeBudget
  )
) {
  console.error(JSON.stringify(output, null, 2));
  process.exit(1);
}

console.log(JSON.stringify(output, null, 2));
