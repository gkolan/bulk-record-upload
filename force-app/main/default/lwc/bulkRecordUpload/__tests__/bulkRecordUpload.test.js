import { createElement } from "lwc";
import BulkRecordUpload from "c/bulkRecordUpload";
import getSelection from "@salesforce/apex/BulkRecordUploadController.getSelection";

import getProcessPresentation from "@salesforce/apex/BulkRecordUploadController.getProcessPresentation";
import getTemplate from "@salesforce/apex/BulkRecordUploadController.getTemplate";
import getHistory from "@salesforce/apex/BulkRecordUploadController.getHistory";
import submit from "@salesforce/apex/BulkRecordUploadController.submit";
import { TextEncoder } from "util";

global.TextEncoder = TextEncoder;

jest.mock(
  "@salesforce/apex/BulkRecordUploadController.getProcessPresentation",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/BulkRecordUploadController.getTemplate",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/BulkRecordUploadController.getSelection",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/BulkRecordUploadController.getHistory",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/BulkRecordUploadController.submit",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = async () => {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
};

describe("c-bulk-record-upload", () => {
  beforeEach(() => {
    getSelection.mockResolvedValue({
      selectionType: "BUNDLE",
      selectionLabel: "Account uploads",
      processes: [
        { label: "Account Insert", value: "ACCOUNT_INSERT" },
        { label: "Account Update", value: "ACCOUNT_UPDATE" }
      ]
    });

    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      subtitle: "Upload account records.",
      iconName: "standard:account",
      instructions:
        "<p>Before uploading:</p><ul><li>Use the template.</li></ul>"
    });
    getTemplate.mockResolvedValue('"name"\r\n');
    getHistory.mockResolvedValue([]);
    submit.mockResolvedValue({
      uploadId: "a00000000000001",
      status: "QUEUED",
      isDuplicate: false
    });
    Object.defineProperty(window.navigator, "onLine", {
      configurable: true,
      value: true
    });
    Object.defineProperty(globalThis, "crypto", {
      configurable: true,
      value: { getRandomValues: (bytes) => bytes.fill(1) }
    });
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.useRealTimers();
  });

  it("loads processes and exposes composable form controls", async () => {
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();
    const selector = element.shadowRoot.querySelector(
      "c-bulk-record-upload-process-selector"
    );
    expect(selector.processOptions).toEqual([
      { label: "Account Insert", value: "ACCOUNT_INSERT" },
      { label: "Account Update", value: "ACCOUNT_UPDATE" }
    ]);
    const card = element.shadowRoot.querySelector("article");
    expect(card.firstElementChild.classList.contains("bru-selection")).toBe(
      true
    );
    expect(
      element.shadowRoot.querySelector(".bru-process-heading").textContent
    ).toContain("BulkRecordUpload_Upload_Process");
    expect(card.textContent).not.toContain("Account uploads");
    expect(element.shadowRoot.querySelector("[aria-live]")).not.toBeNull();
    expect(getHistory).toHaveBeenCalledWith({ processKey: null });
    await expect(element).toBeAccessible();
  });

  it("renders Custom Metadata subtitle and instructions separately", async () => {
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-process-selector")
      .dispatchEvent(
        new CustomEvent("processchange", {
          detail: { value: "ACCOUNT_INSERT" }
        })
      );
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".bru-subtitle").textContent
    ).toContain("Upload account records.");
    expect(
      element.shadowRoot.querySelector("lightning-formatted-rich-text").value
    ).toContain("<li>Use the template.</li>");
    expect(getProcessPresentation).toHaveBeenCalledWith({
      processKey: "ACCOUNT_INSERT"
    });
    expect(element.shadowRoot.querySelector("lightning-icon").iconName).toBe(
      "standard:account"
    );
    await expect(element).toBeAccessible();
  });

  it("selects the only available process automatically", async () => {
    getSelection.mockResolvedValue({
      selectionType: "BUNDLE",
      selectionLabel: "Account uploads",
      processes: [{ label: "Account Insert", value: "ACCOUNT_INSERT" }]
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(getSelection).toHaveBeenCalledWith({
      bundleDeveloperName: "ACCOUNT_OPERATIONS"
    });
    expect(getHistory).toHaveBeenCalledWith({
      processKey: "ACCOUNT_INSERT"
    });
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-process-selector")
    ).toBeNull();
    expect(getProcessPresentation).toHaveBeenCalledWith({
      processKey: "ACCOUNT_INSERT"
    });
  });

  it("surfaces permission or network initialization failures", async () => {
    getSelection.mockRejectedValue({
      body: { message: "Permission denied." }
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();
    expect(
      element.shadowRoot.querySelector('[role="alert"]').textContent
    ).toContain("Permission denied.");
  });

  it("switches between the preserved upload and status tabs", async () => {
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    buttons[2].click();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-history")
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-file-input")
    ).toBeNull();
  });

  it("previews a valid file and enables confirmation", async () => {
    jest.useFakeTimers();
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-process-selector")
      .dispatchEvent(
        new CustomEvent("processchange", {
          detail: { value: "ACCOUNT_INSERT" }
        })
      );
    await flushPromises();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-file-input")
      .dispatchEvent(
        new CustomEvent("fileready", {
          detail: { fileName: "accounts.csv", text: "Name\nAcme\n" }
        })
      );
    await flushPromises();
    const confirmation = element.shadowRoot.querySelector(
      "c-bulk-record-upload-confirmation"
    );
    expect(confirmation.disabled).toBe(false);
    expect(submit).not.toHaveBeenCalled();
  });

  it("submits once and preserves the generated idempotency key", async () => {
    const element = await createReadyElement();
    element.contextRecordId = "001000000000001AAA";
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    expect(submit).toHaveBeenCalledTimes(1);
    expect(submit.mock.calls[0][0].request.idempotencyKey).toHaveLength(64);
    expect(submit.mock.calls[0][0].request.contextRecordId).toBe(
      "001000000000001AAA"
    );
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-progress").status
    ).toBe("QUEUED");
  });

  it("sends the platform-injected recordId on a record page", async () => {
    const element = await createReadyElement();
    element.recordId = "001000000000002AAA";
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    expect(submit.mock.calls[0][0].request.contextRecordId).toBe(
      "001000000000002AAA"
    );
  });

  it("sends the Experience Cloud contextRecordId when recordId is absent", async () => {
    const element = await createReadyElement();
    element.contextRecordId = "001000000000003AAA";
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    expect(submit.mock.calls[0][0].request.contextRecordId).toBe(
      "001000000000003AAA"
    );
  });

  it("prefers the platform recordId over contextRecordId when both are set", async () => {
    const element = await createReadyElement();
    element.recordId = "001000000000004AAA";
    element.contextRecordId = "001000000000005AAA";
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    expect(submit.mock.calls[0][0].request.contextRecordId).toBe(
      "001000000000004AAA"
    );
  });

  it("submits a null context when neither recordId nor contextRecordId is set", async () => {
    const element = await createReadyElement();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    expect(submit).toHaveBeenCalledTimes(1);
    expect(submit.mock.calls[0][0].request.contextRecordId).toBeUndefined();
    expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
  });

  it("surfaces an Apex submission failure without losing retry state", async () => {
    submit.mockRejectedValue({ body: { message: "Request rejected." } });
    const element = await createReadyElement();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    expect(
      element.shadowRoot.querySelector('[role="alert"]').textContent
    ).toContain("Request rejected.");
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-confirmation")
        .disabled
    ).toBe(false);
  });

  it("cleans network listeners and the polling timer when disconnected", async () => {
    jest.useFakeTimers();
    const clearTimer = jest.spyOn(window, "clearTimeout");
    const removeListener = jest.spyOn(window, "removeEventListener");
    const element = await createReadyElement();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();
    document.body.removeChild(element);

    expect(clearTimer).toHaveBeenCalled();
    expect(removeListener).toHaveBeenCalledWith("online", expect.any(Function));
    expect(removeListener).toHaveBeenCalledWith(
      "offline",
      expect.any(Function)
    );
  });

  it("disables submission while offline and announces recovery", async () => {
    Object.defineProperty(window.navigator, "onLine", {
      configurable: true,
      value: false
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();
    expect(
      element.shadowRoot.querySelector('[role="alert"]').textContent
    ).toContain("BulkRecordUpload_Offline");
    window.dispatchEvent(new CustomEvent("online"));
    await flushPromises();
    expect(
      element.shadowRoot.querySelector("[aria-live]").textContent
    ).toContain("BulkRecordUpload_Network_Restored");
  });
});

async function createReadyElement() {
  const element = createElement("c-bulk-record-upload", {
    is: BulkRecordUpload
  });
  element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
  document.body.appendChild(element);
  await flushPromises();
  await flushPromises();
  element.shadowRoot
    .querySelector("c-bulk-record-upload-process-selector")
    .dispatchEvent(
      new CustomEvent("processchange", {
        detail: { value: "ACCOUNT_INSERT" }
      })
    );
  element.shadowRoot
    .querySelector("c-bulk-record-upload-file-input")
    .dispatchEvent(
      new CustomEvent("fileready", {
        detail: { fileName: "accounts.csv", text: "Name\nAcme\n" }
      })
    );
  await flushPromises();
  return element;
}
