import { createElement } from "lwc";
import BulkRecordUploadProcessSelector from "c/bulkRecordUploadProcessSelector";

describe("c-bulk-record-upload-process-selector", () => {
  it("maps keys and emits the selected process contract", () => {
    const element = createElement("c-bulk-record-upload-process-selector", {
      is: BulkRecordUploadProcessSelector
    });
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
    combobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "CONTACT_INSERT" } })
    );
    expect(listener.mock.calls[0][0].detail).toEqual({
      value: "CONTACT_INSERT"
    });
  });
});
