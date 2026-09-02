import { createElement } from "lwc";
import BulkRecordUploadConfirmation from "c/bulkRecordUploadConfirmation";

describe("c-bulk-record-upload-confirmation", () => {
  it("emits one confirm event when enabled", () => {
    const element = createElement("c-bulk-record-upload-confirmation", {
      is: BulkRecordUploadConfirmation
    });
    const listener = jest.fn();
    element.addEventListener("uploadconfirm", listener);
    document.body.appendChild(element);
    element.shadowRoot.querySelector("lightning-button").click();
    expect(listener).toHaveBeenCalledTimes(1);
  });
});
