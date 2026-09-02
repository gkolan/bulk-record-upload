import { createElement } from "lwc";
import BulkRecordUploadProcessSelector from "c/bulkRecordUploadProcessSelector";

describe("c-bulk-record-upload-process-selector", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("maps keys and emits the selected process contract", async () => {
    const element = createElement("c-bulk-record-upload-process-selector", {
      is: BulkRecordUploadProcessSelector
    });
    element.helpText = "Choose the upload operation.";
    element.processOptions = [
      { label: "Contact Insert", value: "CONTACT_INSERT" }
    ];
    const listener = jest.fn();
    element.addEventListener("processchange", listener);
    document.body.appendChild(element);
    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox.options).toEqual([
      { label: "Contact Insert", value: "CONTACT_INSERT" }
    ]);
    expect(combobox.label).toContain("BulkRecordUpload_Upload_Process");
    expect(combobox.fieldLevelHelp).toBe("Choose the upload operation.");
    combobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "CONTACT_INSERT" } })
    );
    expect(listener.mock.calls[0][0].detail).toEqual({
      value: "CONTACT_INSERT"
    });
    await expect(element).toBeAccessible();
  });
});
