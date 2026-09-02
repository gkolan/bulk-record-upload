import { createElement } from "lwc";
import BulkRecordUploadFileInput from "c/bulkRecordUploadFileInput";

const originalFileReader = global.FileReader;

describe("c-bulk-record-upload-file-input", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    global.FileReader = originalFileReader;
    jest.clearAllMocks();
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

  it("exposes a reset contract for parent state invalidation", () => {
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

    element.reset();

    expect(input.value).toBe("");
  });

  it("accepts a file within the server's two MiB boundary", () => {
    const readAsText = jest.fn();
    global.FileReader = jest.fn(() => ({ readAsText }));
    const element = createElement("c-bulk-record-upload-file-input", {
      is: BulkRecordUploadFileInput
    });
    document.body.appendChild(element);
    const input = element.shadowRoot.querySelector('input[type="file"]');
    const file = { name: "large.csv", size: 2_050_000 };
    Object.defineProperty(input, "files", {
      configurable: true,
      value: [file]
    });

    input.dispatchEvent(new CustomEvent("change"));

    expect(readAsText).toHaveBeenCalledWith(file, "UTF-8");
  });
});
