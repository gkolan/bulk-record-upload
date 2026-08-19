import { createElement } from "lwc";
import BulkRecordUploadFileInput from "c/bulkRecordUploadFileInput";

describe("c-bulk-record-upload-file-input", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("clears retained chooser state before every click", () => {
    const element = createElement("c-bulk-record-upload-file-input", {
      is: BulkRecordUploadFileInput
    });
    document.body.appendChild(element);
    const input = element.shadowRoot.querySelector('input[type="file"]');
    Object.defineProperty(input, "value", {
      configurable: true,
      value: "retained.csv",
      writable: true
    });

    input.dispatchEvent(new MouseEvent("click"));

    expect(input.value).toBe("");
  });
});
