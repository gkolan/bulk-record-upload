import { formatLabel, labels } from "c/bulkRecordUploadLabels";

const PREVIEW_ROW_LIMIT = 10;
const PREVIEW_COLUMN_LIMIT = 20;

export function normalizeError(error) {
  return error?.body?.message || error?.message || labels.RequestError;
}

export function createIdempotencyKey(
  randomValues = globalThis.crypto?.getRandomValues?.bind(globalThis.crypto)
) {
  if (!randomValues) {
    throw new Error(labels.SecureRandomError);
  }
  const bytes = new Uint8Array(32);
  randomValues(bytes);
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join(
    ""
  );
}

export function parsePreview(csvText) {
  const records = parseRecords(csvText);
  if (records.length < 2) {
    throw new Error(labels.CsvDataRequired);
  }
  const headers = records[0].map((value, index) =>
    (index === 0 ? value.replace(/^\uFEFF/, "") : value).trim()
  );
  if (headers.some((value) => !value)) {
    throw new Error(labels.CsvBlankHeader);
  }
  const normalized = headers.map((value) => value.toLowerCase());
  if (new Set(normalized).size !== normalized.length) {
    throw new Error(labels.CsvDuplicateHeader);
  }
  const visibleHeaders = headers.slice(0, PREVIEW_COLUMN_LIMIT);
  const rows = records
    .slice(1, PREVIEW_ROW_LIMIT + 1)
    .map((record, rowIndex) => {
      if (record.length !== headers.length) {
        throw new Error(formatLabel(labels.CsvColumnCount, rowIndex + 2));
      }
      const values = { key: `row-${rowIndex + 2}`, bruRowNumber: rowIndex + 2 };
      visibleHeaders.forEach((header, columnIndex) => {
        values[`column${columnIndex}`] = record[columnIndex];
      });
      return values;
    });
  return {
    columns: [
      {
        label: labels.Row,
        fieldName: "bruRowNumber",
        type: "number",
        fixedWidth: 80
      },
      ...visibleHeaders.map((header, index) => ({
        label: header,
        fieldName: `column${index}`,
        type: "text",
        wrapText: false
      }))
    ],
    rows,
    totalRows: records.length - 1,
    totalColumns: headers.length,
    isTruncated:
      records.length - 1 > PREVIEW_ROW_LIMIT ||
      headers.length > PREVIEW_COLUMN_LIMIT
  };
}

function parseRecords(csvText) {
  if (!csvText?.trim()) {
    throw new Error(labels.CsvNonempty);
  }
  const records = [];
  let record = [];
  let cell = "";
  let insideQuotes = false;
  let afterClosingQuote = false;
  for (let index = 0; index < csvText.length; index += 1) {
    const character = csvText[index];
    if (character === '"') {
      if (insideQuotes && csvText[index + 1] === '"') {
        cell += '"';
        index += 1;
      } else if (insideQuotes) {
        insideQuotes = false;
        afterClosingQuote = true;
      } else {
        if (cell.length > 0 || afterClosingQuote) {
          throw new Error(labels.CsvUnterminated);
        }
        insideQuotes = true;
      }
    } else if (character === "," && !insideQuotes) {
      record.push(cell);
      cell = "";
      afterClosingQuote = false;
    } else if ((character === "\r" || character === "\n") && !insideQuotes) {
      record.push(cell);
      if (record.some((value) => value !== "")) {
        records.push(record);
      }
      record = [];
      cell = "";
      afterClosingQuote = false;
      if (character === "\r" && csvText[index + 1] === "\n") {
        index += 1;
      }
    } else {
      if (afterClosingQuote && !insideQuotes) {
        throw new Error(labels.CsvUnterminated);
      }
      cell += character;
    }
  }
  if (insideQuotes) {
    throw new Error(labels.CsvUnterminated);
  }
  record.push(cell);
  if (record.some((value) => value !== "")) {
    records.push(record);
  }
  return records;
}
