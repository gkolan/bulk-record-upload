import { createElement } from "lwc";
import BulkRecordUploadProgress from "c/bulkRecordUploadProgress";

describe("c-bulk-record-upload-progress", () => {
  it.each([
    ["QUEUED", 20],
    ["VALIDATING", 40],
    ["PROCESSING", 70],
    ["COMPLETED", 100],
    ["COMPLETED_WITH_ERRORS", 100],
    ["FAILED", 100]
  ])("renders status %s at progress %s", async (status, expected) => {
    const element = createElement("c-bulk-record-upload-progress", {
      is: BulkRecordUploadProgress
    });
    element.status = status;
    document.body.appendChild(element);
    await Promise.resolve();
    expect(
      element.shadowRoot.querySelector("lightning-progress-bar").value
    ).toBe(expected);
  });

  it("emits reset from a terminal state", async () => {
    const element = createElement("c-bulk-record-upload-progress", {
      is: BulkRecordUploadProgress
    });
    element.status = "FAILED";
    const listener = jest.fn();
    element.addEventListener("reset", listener);
    document.body.appendChild(element);
    await Promise.resolve();
    element.shadowRoot.querySelector("lightning-button").click();
    expect(listener).toHaveBeenCalledTimes(1);
  });
});
