import { createElement } from "lwc";
import BulkRecordUploadHistory from "c/bulkRecordUploadHistory";

describe("c-bulk-record-upload-history", () => {
  afterEach(() => {
    document.body.replaceChildren();
  });

  it("renders history and forwards result downloads", async () => {
    const element = createElement("c-bulk-record-upload-history", {
      is: BulkRecordUploadHistory
    });
    element.rows = [
      {
        uploadId: "a00",
        processKey: "ACCOUNT_INSERT",
        status: "COMPLETED",
        rowCount: 2,
        submittedAt: "2026-08-12T09:00:00.000Z",
        resultFileId: "069",
        downloadDisabled: false
      }
    ];
    const listener = jest.fn();
    element.addEventListener("download", listener);
    document.body.appendChild(element);
    await Promise.resolve();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-result-download")
      .dispatchEvent(
        new CustomEvent("download", { detail: { documentId: "069" } })
      );
    expect(listener.mock.calls[0][0].detail.documentId).toBe("069");
    expect(element.shadowRoot.querySelector("caption")).not.toBeNull();
  });

  it("emits refresh and exposes history errors", async () => {
    const element = createElement("c-bulk-record-upload-history", {
      is: BulkRecordUploadHistory
    });
    element.errorMessage = "History unavailable.";
    const listener = jest.fn();
    element.addEventListener("refresh", listener);
    document.body.appendChild(element);
    await Promise.resolve();
    element.shadowRoot.querySelector("lightning-button-icon").click();
    expect(listener).toHaveBeenCalledTimes(1);
    expect(
      element.shadowRoot.querySelector('[role="alert"]').textContent
    ).toContain("History unavailable.");
  });
});
