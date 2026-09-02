import { createElement } from "lwc";
import BulkRecordUpload from "c/bulkRecordUpload";
import getSelection from "@salesforce/apex/BulkRecordUploadController.getSelection";

import getProcessPresentation from "@salesforce/apex/BulkRecordUploadController.getProcessPresentation";
import validateContext from "@salesforce/apex/BulkRecordUploadController.validateContext";
import getTemplate from "@salesforce/apex/BulkRecordUploadController.getTemplate";
import getHistory from "@salesforce/apex/BulkRecordUploadController.getHistory";
import getUploadStatus from "@salesforce/apex/BulkRecordUploadController.getUploadStatus";
import submit from "@salesforce/apex/BulkRecordUploadController.submit";

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
  "@salesforce/apex/BulkRecordUploadController.validateContext",
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
  "@salesforce/apex/BulkRecordUploadController.getUploadStatus",
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
    validateContext.mockResolvedValue(true);
    getHistory.mockResolvedValue([]);
    getUploadStatus.mockResolvedValue({
      uploadId: "a00000000000001",
      status: "PROCESSING"
    });
    submit.mockResolvedValue({
      uploadId: "a00000000000001",
      status: "QUEUED",
      isDuplicate: false
    });
    Object.defineProperty(window.navigator, "onLine", {
      configurable: true,
      value: true
    });
    const getRandomValues = jest.fn((bytes) => bytes.fill(1));
    Object.defineProperty(globalThis, "crypto", {
      configurable: true,
      value: { getRandomValues }
    });
    global.FileReader = class FileReaderMock {
      readAsDataURL() {
        this.result = "data:text/csv;charset=utf-8;base64,TmFtZQpBY21lCg==";
        Promise.resolve().then(() => this.onload());
      }
    };
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
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    expect(selector.helpText).toContain("target object");
    expect(card.textContent).not.toContain("Account uploads");
    expect(element.shadowRoot.querySelector("[aria-live]")).not.toBeNull();
    expect(getHistory).toHaveBeenCalledWith({ processKey: null });
    await expect(element).toBeAccessible();
  });

  it("renders an App Builder instance heading", async () => {
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.componentLabel = "1. Selected Process";
    element.processSelectionMode = "SELECTED_PROCESS";
    element.selectedProcessDeveloperName = "ACCOUNT_INSERT";
    document.body.appendChild(element);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".bru-card-title").textContent
    ).toBe("1. Selected Process");
    await expect(element).toBeAccessible();
  });

  it("renders Custom Metadata subtitle and instructions separately", async () => {
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    element.processSelectionMode = "CONFIGURED_PROCESSES";
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(getSelection).toHaveBeenCalledWith({
      bundleDeveloperName: "ACCOUNT_OPERATIONS",
      objectApiName: undefined,
      selectedProcessDeveloperName: undefined,
      selectionMode: "CONFIGURED_PROCESSES"
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
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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

  it("distinguishes unavailable pending results from expired completed results", async () => {
    getHistory.mockResolvedValue([
      {
        uploadId: "a00000000000001",
        status: "PROCESSING",
        resultFileId: null
      },
      {
        uploadId: "a00000000000002",
        status: "COMPLETED",
        resultFileId: null
      }
    ]);
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
    element.bundleDeveloperName = "ACCOUNT_OPERATIONS";
    document.body.appendChild(element);
    await flushPromises();

    element.shadowRoot.querySelectorAll("lightning-button")[2].click();
    await flushPromises();
    const history = element.shadowRoot.querySelector(
      "c-bulk-record-upload-history"
    );

    expect(history.rows[0].resultExpired).toBe(false);
    expect(history.rows[1].resultExpired).toBe(true);
  });

  it("previews a valid file and enables confirmation", async () => {
    jest.useFakeTimers();
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    expect(submit.mock.calls[0][0].request.contentBase64).toBe(
      "TmFtZQpBY21lCg=="
    );
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

  it("sends the App Page record Id when the page has no current record", async () => {
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

  it("rotates the idempotency key when the server returns a failed upload", async () => {
    submit.mockResolvedValue({
      uploadId: "a00000000000001",
      status: "FAILED",
      isDuplicate: true
    });
    const element = await createReadyElement();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    expect(globalThis.crypto.getRandomValues).toHaveBeenCalledTimes(2);
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-progress").status
    ).toBe("FAILED");
  });

  it("polls the current upload directly instead of relying on the history window", async () => {
    jest.useFakeTimers();
    getUploadStatus.mockResolvedValue({
      uploadId: "a00000000000001",
      status: "COMPLETED",
      resultFileId: "069000000000001AAA"
    });
    const element = await createReadyElement();
    element.shadowRoot
      .querySelector("c-bulk-record-upload-confirmation")
      .dispatchEvent(new CustomEvent("uploadconfirm"));
    await flushPromises();

    jest.advanceTimersByTime(3000);
    await flushPromises();

    expect(getUploadStatus).toHaveBeenCalledWith({
      uploadId: "a00000000000001"
    });
    expect(getHistory).toHaveBeenCalledTimes(1);
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-progress").status
    ).toBe("COMPLETED");
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

  it("renders a working picker from HostObjectApiName alone, proving the zero-config default", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "DEFAULT_PARENT",
      recordContextSource: "USER_CHOICE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: null
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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

    const picker = element.shadowRoot.querySelector("lightning-record-picker");
    expect(picker).not.toBeNull();
    expect(picker.objectApiName).toBe("Account");
    expect(picker.matchingInfo).toEqual({
      primaryField: { fieldPath: "Name" },
      additionalFields: []
    });
    expect(picker.displayInfo).toEqual({
      primaryField: "Name",
      additionalFields: []
    });
    await expect(element).toBeAccessible();
  });

  it("blocks file selection with a stated reason when REQUIRE_PARENT has no chosen parent", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "REQUIRE_PARENT",
      recordContextSource: "USER_CHOICE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: null
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
      element.shadowRoot.querySelector("c-bulk-record-upload-file-input")
    ).toBeNull();
    expect(
      element.shadowRoot.querySelector('[role="alert"]').textContent
    ).toContain("BulkRecordUpload_Require_Parent_Blocked");

    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "001000000000009AAA" }
      })
    );
    await flushPromises();

    expect(validateContext).toHaveBeenCalledWith({
      processKey: "ACCOUNT_INSERT",
      contextRecordId: "001000000000009AAA"
    });

    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-file-input")
    ).not.toBeNull();
  });

  it("prevalidates page context and blocks upload controls when it is ineligible", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "REQUIRE_PARENT",
      recordContextSource: "PAGE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: JSON.stringify({
        criteria: [{ fieldPath: "Industry", operator: "eq", value: "Energy" }],
        filterLogic: "and"
      })
    });
    validateContext.mockRejectedValue({
      body: { message: "The parent record is unavailable." }
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.recordId = "001000000000006AAA";
    element.objectApiName = "Account";
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    await flushPromises();

    expect(validateContext).toHaveBeenCalledWith({
      processKey: "ACCOUNT_INSERT",
      contextRecordId: "001000000000006AAA"
    });
    expect(
      element.shadowRoot.querySelector('[role="alert"]').textContent
    ).toContain("The parent record is unavailable.");
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-file-input")
    ).toBeNull();
  });

  it("prevalidates matching page context before enabling file selection", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "REQUIRE_PARENT",
      recordContextSource: "PAGE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: null
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.contextRecordId = "001000000000007AAA";
    element.contextObjectApiName = "Account";
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    await flushPromises();

    expect(validateContext).toHaveBeenCalledWith({
      processKey: "ACCOUNT_INSERT",
      contextRecordId: "001000000000007AAA"
    });
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-file-input")
        .disabled
    ).toBe(false);
  });

  it("blocks a page whose object does not match the process host object", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "REQUIRE_PARENT",
      recordContextSource: "PAGE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: null
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.recordId = "001000000000008AAA";
    element.objectApiName = "Contact";
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    await flushPromises();

    expect(validateContext).toHaveBeenCalledWith({
      processKey: "ACCOUNT_INSERT",
      contextRecordId: "001000000000008AAA"
    });
    expect(
      element.shadowRoot.querySelector('[role="alert"]').textContent
    ).toContain("BulkRecordUpload_Request_Error");
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-file-input")
    ).toBeNull();
  });

  it("clears the chosen parent when the process changes", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "DEFAULT_PARENT",
      recordContextSource: "USER_CHOICE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: null
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "001000000000009AAA" }
      })
    );
    await flushPromises();
    expect(
      element.shadowRoot.querySelector("lightning-record-picker").value
    ).toBe("001000000000009AAA");

    element.shadowRoot
      .querySelector("c-bulk-record-upload-process-selector")
      .dispatchEvent(
        new CustomEvent("processchange", {
          detail: { value: "ACCOUNT_UPDATE" }
        })
      );
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("lightning-record-picker").value
    ).toBeUndefined();
  });

  it("clears the staged file and preview when the process changes", async () => {
    const element = await createReadyElement();
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-confirmation")
    ).not.toBeNull();

    element.shadowRoot
      .querySelector("c-bulk-record-upload-process-selector")
      .dispatchEvent(
        new CustomEvent("processchange", {
          detail: { value: "ACCOUNT_UPDATE" }
        })
      );
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-confirmation")
    ).toBeNull();
    expect(
      element.shadowRoot.querySelector("c-bulk-record-upload-preview")
    ).toBeNull();
  });

  it("locks the picker once a file is staged", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "DEFAULT_PARENT",
      recordContextSource: "USER_CHOICE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: null
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
      element.shadowRoot.querySelector("lightning-record-picker").disabled
    ).toBe(false);

    element.shadowRoot
      .querySelector("c-bulk-record-upload-file-input")
      .dispatchEvent(
        new CustomEvent("fileready", {
          detail: { fileName: "accounts.csv", text: "Name\nAcme\n" }
        })
      );
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("lightning-record-picker").disabled
    ).toBe(true);
  });

  it("lets the host record page win over the picker when both are available", async () => {
    getProcessPresentation.mockResolvedValue({
      processKey: "ACCOUNT_INSERT",
      recordContextAction: "DEFAULT_PARENT",
      recordContextSource: "USER_CHOICE",
      hostObjectApiName: "Account",
      primarySearchField: "Name",
      additionalSearchFields: [],
      primaryDisplayField: "Name",
      additionalDisplayFields: [],
      filterCriteriaJson: null
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.recordId = "001000000000009AAA";
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
      element.shadowRoot.querySelector("lightning-record-picker")
    ).toBeNull();
  });

  it("disables submission while offline and announces recovery", async () => {
    Object.defineProperty(window.navigator, "onLine", {
      configurable: true,
      value: false
    });
    const element = createElement("c-bulk-record-upload", {
      is: BulkRecordUpload
    });
    element.processSelectionMode = "CONFIGURED_PROCESSES";
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
  element.processSelectionMode = "CONFIGURED_PROCESSES";
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
