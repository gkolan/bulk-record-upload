import { createElement } from "lwc";
import BulkRecordUploadValidation from "c/bulkRecordUploadValidation";

describe("c-bulk-record-upload-validation", () => {
  afterEach(() => {
    document.body.replaceChildren();
  });

  it("announces the bounded mapping summary", async () => {
    const element = createElement("c-bulk-record-upload-validation", {
      is: BulkRecordUploadValidation
    });
    element.processKey = "ACCOUNT_INSERT";
    element.fileName = "accounts.csv";
    element.rowCount = 10;
    document.body.appendChild(element);
    await Promise.resolve();

    expect(
      element.shadowRoot.querySelector('[role="status"]').textContent
    ).toContain("BulkRecordUpload_Validation_Summary");
    expect(element.shadowRoot.querySelector("dl").textContent).toContain(
      "accounts.csv"
    );
  });

  it("renders guidance before a selection exists", async () => {
    const element = createElement("c-bulk-record-upload-validation", {
      is: BulkRecordUploadValidation
    });
    document.body.appendChild(element);
    await Promise.resolve();
    expect(element.shadowRoot.querySelector("dl")).toBeNull();
    expect(element.shadowRoot.textContent).toContain(
      "BulkRecordUpload_Validation_Guidance"
    );
  });
});
