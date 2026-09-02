import {
  createIdempotencyKey,
  encodeUtf8Base64,
  normalizeError,
  parsePreview
} from "c/bulkRecordUploadUtils";

describe("bulkRecordUploadUtils", () => {
  it("parses quoted CSV and caps browser preview", () => {
    const rows = ["Name,Description"];
    for (let index = 0; index < 12; index += 1) {
      rows.push(`Account ${index},"value, ${index}"`);
    }
    const preview = parsePreview(rows.join("\r\n"));
    expect(preview.totalRows).toBe(12);
    expect(preview.totalColumns).toBe(2);
    expect(preview.rows).toHaveLength(10);
    expect(preview.rows[0].column1).toBe("value, 0");
    expect(preview.isTruncated).toBe(true);
  });

  it("keeps the maximum preview projection bounded", () => {
    const header = Array.from({ length: 100 }, (_, index) => `c${index}`).join(
      ","
    );
    const dataRow = Array.from({ length: 100 }, () => "x").join(",");
    const csv = [header, ...Array.from({ length: 5000 }, () => dataRow)].join(
      "\n"
    );
    const startedAt = performance.now();

    const preview = parsePreview(csv);
    const elapsedMilliseconds = performance.now() - startedAt;

    expect(preview.totalRows).toBe(5000);
    expect(preview.totalColumns).toBe(100);
    expect(preview.rows).toHaveLength(10);
    expect(preview.columns).toHaveLength(21);
    expect(JSON.stringify(preview).length).toBeLessThan(10_000);
    expect(elapsedMilliseconds).toBeLessThan(2_000);
  });

  it("rejects duplicate and malformed headers", () => {
    expect(() => parsePreview("Name,name\nA,B")).toThrow(
      "BulkRecordUpload_CSV_Duplicate_Header"
    );
    expect(() => parsePreview("Name,\nA,B")).toThrow(
      "BulkRecordUpload_CSV_Blank_Header"
    );
  });

  it("strips a UTF-8 BOM from the first header", () => {
    const preview = parsePreview("\uFEFFName,Description\nAcme,Test");

    expect(preview.columns[1].label).toBe("Name");
    expect(preview.rows[0].column0).toBe("Acme");
  });

  it("rejects quote forms that the server rejects", () => {
    expect(() => parsePreview('Name\nAc"me')).toThrow();
    expect(() => parsePreview('Name\n"Acme"suffix')).toThrow();
  });

  it("creates a stable 64-character secure idempotency key", () => {
    const key = createIdempotencyKey((bytes) => {
      bytes.fill(10);
      return bytes;
    });
    expect(key).toBe("0a".repeat(32));
  });

  it("extracts asynchronous UTF-8 base64 without a synchronous byte loop", async () => {
    class Reader {
      readAsDataURL(blob) {
        expect(blob.type).toBe("text/csv;charset=utf-8");
        this.result = "data:text/csv;charset=utf-8;base64,TmFtZQpBY21lCg==";
        this.onload();
      }
    }

    await expect(encodeUtf8Base64("Name\nAcme\n", Reader)).resolves.toBe(
      "TmFtZQpBY21lCg=="
    );
  });

  it("rejects an unreadable asynchronous base64 conversion", async () => {
    class Reader {
      readAsDataURL() {
        this.onerror();
      }
    }

    await expect(encodeUtf8Base64("Name\nAcme\n", Reader)).rejects.toThrow(
      "BulkRecordUpload_CSV_Read_Error"
    );
  });

  it("normalizes Apex, JavaScript, and fallback errors", () => {
    expect(normalizeError({ body: { message: "Apex message" } })).toBe(
      "Apex message"
    );
    expect(normalizeError(new Error("JavaScript message"))).toBe(
      "JavaScript message"
    );
    expect(normalizeError({})).toContain("BulkRecordUpload_Request_Error");
  });
});
