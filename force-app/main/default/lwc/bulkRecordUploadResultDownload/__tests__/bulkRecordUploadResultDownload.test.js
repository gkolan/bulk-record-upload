import { createElement } from "lwc";
import BulkRecordUploadResultDownload from "c/bulkRecordUploadResultDownload";

describe("c-bulk-record-upload-result-download", () => {
  afterEach(() => {
    document.body.replaceChildren();
  });

  it("emits only the approved document identifier", async () => {
    const element = createElement("c-bulk-record-upload-result-download", {
      is: BulkRecordUploadResultDownload
    });
    element.documentId = "069000000000001";
    const listener = jest.fn();
    element.addEventListener("download", listener);
    document.body.appendChild(element);
    await Promise.resolve();
    element.shadowRoot.querySelector("lightning-button").click();

    expect(listener).toHaveBeenCalledTimes(1);
    expect(listener.mock.calls[0][0].detail).toEqual({
      documentId: "069000000000001"
    });
  });

  it("disables an expired result", async () => {
    const element = createElement("c-bulk-record-upload-result-download", {
      is: BulkRecordUploadResultDownload
    });
    element.documentId = "069000000000001";
    element.expired = true;
    document.body.appendChild(element);
    await Promise.resolve();
    const button = element.shadowRoot.querySelector("lightning-button");
    expect(button.disabled).toBe(true);
    expect(button.label).toBe("c.BulkRecordUpload_Result_Expired");
  });
});
