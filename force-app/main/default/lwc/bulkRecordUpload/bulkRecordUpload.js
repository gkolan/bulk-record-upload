import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSelection from "@salesforce/apex/BulkRecordUploadController.getSelection";
import getProcessPresentation from "@salesforce/apex/BulkRecordUploadController.getProcessPresentation";
import validateContext from "@salesforce/apex/BulkRecordUploadController.validateContext";
import getTemplate from "@salesforce/apex/BulkRecordUploadController.getTemplate";
import getHistory from "@salesforce/apex/BulkRecordUploadController.getHistory";
import getUploadStatus from "@salesforce/apex/BulkRecordUploadController.getUploadStatus";
import submit from "@salesforce/apex/BulkRecordUploadController.submit";
import { formatLabel, labels } from "c/bulkRecordUploadLabels";
import {
  createIdempotencyKey,
  encodeUtf8Base64,
  normalizeError,
  parsePreview
} from "c/bulkRecordUploadUtils";

const TERMINAL = new Set(["COMPLETED", "COMPLETED_WITH_ERRORS", "FAILED"]);
const RESULT_STATUSES = new Set(["COMPLETED", "COMPLETED_WITH_ERRORS"]);
const POLL_INTERVAL = 3000;

export default class BulkRecordUpload extends NavigationMixin(
  LightningElement
) {
  @api componentLabel;
  @api processSelectionMode;
  @api selectedProcessDeveloperName;
  @api bundleDeveloperName;
  @api recordSelectionMode;
  _recordId;
  _objectApiName;
  _contextRecordId;
  _contextObjectApiName;
  isConnected = false;
  processOptions = [];
  processKey;
  fileName;
  fileText;
  preview;
  historyRows = [];
  currentUploadId;
  currentStatus;
  errorMessage;
  historyError;
  announcement = "";
  isLoading = true;
  isSubmitting = false;
  historyLoading = false;
  isOffline = !navigator.onLine;
  idempotencyKey;
  pollTimer;
  activeTab = "upload";
  subtitle;
  instructions;
  iconName = "utility:upload";
  label = labels;
  recordContextAction = "NONE";
  recordContextSource = "PAGE";
  hostObjectApiName;
  primarySearchField;
  additionalSearchFields = [];
  primaryDisplayField;
  additionalDisplayFields = [];
  filterCriteriaJson;
  pickedRecordId;
  isContextValidating = false;
  isContextEligible = false;
  contextErrorMessage;
  presentationRequestToken = 0;
  contextRequestToken = 0;

  @api
  get recordId() {
    return this._recordId;
  }

  set recordId(value) {
    this._recordId = value;
    this.handleContextPropertyChange();
  }

  @api
  get objectApiName() {
    return this._objectApiName;
  }

  set objectApiName(value) {
    this._objectApiName = value;
    this.handleContextPropertyChange();
  }

  @api
  get contextRecordId() {
    return this._contextRecordId;
  }

  set contextRecordId(value) {
    this._contextRecordId = value;
    this.handleContextPropertyChange();
  }

  @api
  get contextObjectApiName() {
    return this._contextObjectApiName;
  }

  set contextObjectApiName(value) {
    this._contextObjectApiName = value;
    this.handleContextPropertyChange();
  }

  connectedCallback() {
    this.isConnected = true;
    window.addEventListener("online", this.handleOnline);
    window.addEventListener("offline", this.handleOffline);
    if (!this.isComponentConfigured) {
      this.isLoading = false;
      this.announcement = labels.BundleNotConfigured;
      return;
    }
    this.initialize();
  }

  disconnectedCallback() {
    this.isConnected = false;
    this.presentationRequestToken += 1;
    this.contextRequestToken += 1;
    window.removeEventListener("online", this.handleOnline);
    window.removeEventListener("offline", this.handleOffline);
    this.clearPoll();
  }

  get isBusy() {
    return this.isLoading || this.isSubmitting || this.isContextValidating;
  }

  get isComponentConfigured() {
    if (this.processSelectionMode === "SELECTED_PROCESS") {
      return Boolean(this.selectedProcessDeveloperName?.trim());
    }
    if (this.processSelectionMode === "ALL_ACTIVE_FOR_OBJECT") {
      return Boolean(this.effectiveObjectApiName);
    }
    if (this.processSelectionMode === "CONFIGURED_PROCESSES") {
      return Boolean(this.bundleDeveloperName?.trim());
    }
    return false;
  }

  get pageRecordId() {
    return this.recordId ?? this.contextRecordId;
  }

  get effectiveObjectApiName() {
    return this.objectApiName ?? this.contextObjectApiName;
  }

  get effectiveRecordId() {
    if (this.recordSelectionMode === "MULTIPLE_RECORDS") {
      return undefined;
    }
    if (this.recordSelectionMode === "SELECT_RECORD") {
      return this.pickedRecordId;
    }
    return this.pageRecordId ?? this.pickedRecordId;
  }

  get showRecordPicker() {
    return (
      this.recordContextAction !== "NONE" &&
      (this.recordSelectionMode === "SELECT_RECORD" ||
        this.recordContextSource === "USER_CHOICE") &&
      (this.recordSelectionMode === "SELECT_RECORD" || !this.pageRecordId)
    );
  }

  get pickerDisabled() {
    return this.isBusy || Boolean(this.preview);
  }

  get requireParentBlocked() {
    return (
      this.recordContextAction === "REQUIRE_PARENT" && !this.effectiveRecordId
    );
  }

  get hasHostObjectMismatch() {
    return Boolean(
      this.pageRecordId &&
      this.effectiveObjectApiName &&
      this.hostObjectApiName &&
      this.effectiveObjectApiName.toLowerCase() !==
        this.hostObjectApiName.toLowerCase()
    );
  }

  get contextBlockMessage() {
    if (this.contextErrorMessage) {
      return this.contextErrorMessage;
    }
    return this.requireParentBlocked ? labels.RequireParentBlocked : undefined;
  }

  get fileInputDisabled() {
    return this.isBusy || !this.isContextEligible;
  }

  get processSelectorDisabled() {
    return this.isBusy || Boolean(this.currentUploadId);
  }

  get matchingInfo() {
    if (!this.primarySearchField) {
      return undefined;
    }
    return {
      primaryField: { fieldPath: this.primarySearchField },
      additionalFields: this.additionalSearchFields.map((fieldPath) => ({
        fieldPath
      }))
    };
  }

  get displayInfo() {
    if (!this.primaryDisplayField) {
      return undefined;
    }
    return {
      primaryField: this.primaryDisplayField,
      additionalFields: this.additionalDisplayFields
    };
  }

  get pickerFilter() {
    if (!this.filterCriteriaJson) {
      return undefined;
    }
    try {
      return JSON.parse(this.filterCriteriaJson);
    } catch {
      return undefined;
    }
  }

  get displaySubtitle() {
    return (
      this.subtitle ||
      "Upload approved CSV files and monitor processing results."
    );
  }

  get displayTitle() {
    return this.componentLabel?.trim() || labels.AppTitle;
  }

  get showInstructions() {
    return Boolean(this.instructions);
  }

  get showForm() {
    return this.activeTab === "upload" && !this.currentUploadId;
  }

  get showProgress() {
    return this.activeTab === "upload" && Boolean(this.currentUploadId);
  }

  get showHistory() {
    return this.activeTab === "status";
  }

  get uploadTabVariant() {
    return this.activeTab === "upload" ? "brand" : "neutral";
  }

  get statusTabVariant() {
    return this.activeTab === "status" ? "brand" : "neutral";
  }

  get templateDisabled() {
    return this.isBusy || !this.processKey;
  }

  get submitDisabled() {
    return (
      this.isBusy ||
      this.isOffline ||
      !this.processKey ||
      !this.fileText ||
      !this.isContextEligible
    );
  }

  get usesFixedProcess() {
    return this.processOptions.length === 1;
  }

  get showsProcessSelector() {
    return !this.usesFixedProcess;
  }

  get fileColumnClass() {
    return this.usesFixedProcess
      ? "slds-col slds-size_1-of-1 slds-m-bottom_medium"
      : "slds-col slds-size_1-of-1 slds-large-size_1-of-2 slds-m-bottom_medium";
  }

  async initialize() {
    this.isLoading = true;
    try {
      const selection = await getSelection({
        selectionMode: this.processSelectionMode,
        selectedProcessDeveloperName: this.selectedProcessDeveloperName,
        bundleDeveloperName: this.bundleDeveloperName,
        objectApiName: this.effectiveObjectApiName
      });
      this.processOptions = selection.processes;
      if (this.usesFixedProcess) {
        this.processKey = this.processOptions[0]?.value;
        await Promise.all([this.refreshHistory(), this.refreshPresentation()]);
      } else if (this.processOptions.length === 0) {
        this.errorMessage = labels.NoProcesses;
      } else {
        await this.refreshHistory();
      }
    } catch (error) {
      this.errorMessage = normalizeError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleProcessChange(event) {
    if (this.currentUploadId) {
      return;
    }
    this.clearStagedFile();
    this.processKey = event.detail.value;
    this.errorMessage = undefined;
    this.contextErrorMessage = undefined;
    this.pickedRecordId = undefined;
    await this.refreshPresentation();
  }

  async refreshPresentation() {
    const requestedProcessKey = this.processKey;
    const requestToken = this.presentationRequestToken + 1;
    this.presentationRequestToken = requestToken;
    this.contextRequestToken += 1;
    this.subtitle = undefined;
    this.instructions = undefined;
    this.iconName = "utility:upload";
    this.recordContextAction = "NONE";
    this.recordContextSource = "PAGE";
    this.hostObjectApiName = undefined;
    this.primarySearchField = undefined;
    this.additionalSearchFields = [];
    this.primaryDisplayField = undefined;
    this.additionalDisplayFields = [];
    this.filterCriteriaJson = undefined;
    this.isContextValidating = false;
    this.isContextEligible = false;
    this.contextErrorMessage = undefined;
    if (!requestedProcessKey) {
      return;
    }
    try {
      const presentation = await getProcessPresentation({
        processKey: requestedProcessKey
      });
      if (
        requestToken !== this.presentationRequestToken ||
        requestedProcessKey !== this.processKey
      ) {
        return;
      }
      this.subtitle = presentation.subtitle;
      this.instructions = presentation.instructions;
      this.iconName = presentation.iconName || "utility:upload";
      this.recordContextAction = presentation.recordContextAction || "NONE";
      this.recordContextSource = presentation.recordContextSource || "PAGE";
      this.hostObjectApiName = presentation.hostObjectApiName;
      this.primarySearchField = presentation.primarySearchField;
      this.additionalSearchFields = presentation.additionalSearchFields || [];
      this.primaryDisplayField = presentation.primaryDisplayField;
      this.additionalDisplayFields = presentation.additionalDisplayFields || [];
      this.filterCriteriaJson = presentation.filterCriteriaJson;
      await this.refreshContextEligibility();
    } catch (error) {
      if (
        requestToken === this.presentationRequestToken &&
        requestedProcessKey === this.processKey
      ) {
        this.errorMessage = normalizeError(error);
      }
    }
  }

  async handleParentChange(event) {
    this.pickedRecordId = event.detail.recordId;
    await this.refreshContextEligibility();
  }

  handleContextPropertyChange() {
    if (this.isConnected && this.processKey) {
      this.refreshContextEligibility();
    }
  }

  async refreshContextEligibility() {
    const requestedProcessKey = this.processKey;
    const requestedRecordId = this.effectiveRecordId;
    const requestToken = this.contextRequestToken + 1;
    this.contextRequestToken = requestToken;
    this.isContextValidating = false;
    this.isContextEligible = false;
    this.contextErrorMessage = undefined;

    if (this.recordContextAction === "NONE") {
      this.isContextEligible = true;
      return;
    }
    if (!requestedRecordId) {
      this.isContextEligible = this.recordContextAction !== "REQUIRE_PARENT";
      return;
    }

    this.isContextValidating = true;
    try {
      const eligible = await validateContext({
        processKey: requestedProcessKey,
        contextRecordId: requestedRecordId
      });
      if (
        !this.isCurrentContextRequest(
          requestToken,
          requestedProcessKey,
          requestedRecordId
        )
      ) {
        return;
      }
      this.isContextEligible = eligible === true && !this.hasHostObjectMismatch;
      if (!this.isContextEligible) {
        this.contextErrorMessage = labels.RequestError;
      }
    } catch (error) {
      if (
        !this.isCurrentContextRequest(
          requestToken,
          requestedProcessKey,
          requestedRecordId
        )
      ) {
        return;
      }
      this.contextErrorMessage = normalizeError(error);
    } finally {
      if (requestToken === this.contextRequestToken) {
        this.isContextValidating = false;
      }
    }
  }

  isCurrentContextRequest(requestToken, processKey, recordId) {
    return (
      this.isConnected &&
      requestToken === this.contextRequestToken &&
      processKey === this.processKey &&
      recordId === this.effectiveRecordId
    );
  }

  handleUploadTab() {
    this.activeTab = "upload";
  }

  handleStatusTab() {
    this.activeTab = "status";
    this.refreshHistory();
  }

  async handleDownloadTemplate() {
    if (this.templateDisabled) {
      return;
    }
    try {
      const csv = await getTemplate({ processKey: this.processKey });
      const anchor = document.createElement("a");
      anchor.href = URL.createObjectURL(
        new Blob([csv], { type: "text/csv;charset=utf-8" })
      );
      anchor.download = `${this.processKey}-template.csv`;
      anchor.click();
      URL.revokeObjectURL(anchor.href);
    } catch (error) {
      this.errorMessage = normalizeError(error);
    }
  }

  handleFileReady(event) {
    try {
      this.fileName = event.detail.fileName;
      this.fileText = event.detail.text;
      this.preview = parsePreview(this.fileText);
      this.idempotencyKey = createIdempotencyKey();
      this.errorMessage = undefined;
      this.announcement = formatLabel(labels.RowsReady, this.preview.totalRows);
    } catch (error) {
      this.clearStagedFile();
      this.errorMessage = normalizeError(error);
    }
  }

  handleFileError(event) {
    this.clearStagedFile();
    this.errorMessage = event.detail.message;
  }

  async handleSubmit() {
    if (this.submitDisabled) {
      return;
    }
    this.isSubmitting = true;
    this.errorMessage = undefined;
    this.announcement = labels.Submitting;
    try {
      const response = await submit({
        request: {
          processKey: this.processKey,
          fileName: this.fileName,
          contentBase64: await encodeUtf8Base64(this.fileText),
          idempotencyKey: this.idempotencyKey,
          contextRecordId: this.effectiveRecordId,
          bundleDeveloperName:
            this.processSelectionMode === "CONFIGURED_PROCESSES"
              ? this.bundleDeveloperName
              : undefined
        }
      });
      this.currentUploadId = response.uploadId;
      this.currentStatus = response.status;
      const failed = response.status === "FAILED";
      if (failed) {
        this.rotateIdempotencyKey();
      }
      this.announcement = failed
        ? labels.StateFailed
        : response.isDuplicate
          ? labels.DuplicateReturned
          : labels.UploadQueued;
      this.dispatchEvent(
        new ShowToastEvent({
          title: failed
            ? labels.ErrorLabel
            : response.isDuplicate
              ? labels.ExistingTitle
              : labels.QueuedTitle,
          message: this.announcement,
          variant: failed ? "error" : response.isDuplicate ? "info" : "success"
        })
      );
      this.schedulePoll();
    } catch (error) {
      this.errorMessage = normalizeError(error);
      this.announcement = this.errorMessage;
      this.rotateIdempotencyKey();
    } finally {
      this.isSubmitting = false;
    }
  }

  async refreshHistory() {
    this.historyLoading = true;
    this.historyError = undefined;
    try {
      const rows = await getHistory({
        processKey: this.usesFixedProcess ? this.processKey : null
      });
      this.historyRows = rows.map((row) => ({
        ...row,
        resultExpired: !row.resultFileId && RESULT_STATUSES.has(row.status)
      }));
      this.syncCurrentStatus();
    } catch (error) {
      this.historyError = normalizeError(error);
    } finally {
      this.historyLoading = false;
    }
  }

  syncCurrentStatus() {
    if (!this.currentUploadId) {
      return;
    }
    const current = this.historyRows.find(
      (row) => row.uploadId === this.currentUploadId
    );
    if (current) {
      this.applyCurrentStatus(current);
    }
  }

  applyCurrentStatus(current) {
    const wasFailed = this.currentStatus === "FAILED";
    this.currentStatus = current.status;
    this.announcement = formatLabel(labels.StatusAnnouncement, current.status);
    if (TERMINAL.has(current.status)) {
      this.clearPoll();
    }
    if (current.status === "FAILED" && !wasFailed) {
      this.rotateIdempotencyKey();
    }
  }

  async refreshCurrentUploadStatus() {
    const requestedUploadId = this.currentUploadId;
    if (!requestedUploadId) {
      return;
    }
    try {
      const current = await getUploadStatus({ uploadId: requestedUploadId });
      if (
        this.isConnected &&
        requestedUploadId === this.currentUploadId &&
        current
      ) {
        this.errorMessage = undefined;
        this.applyCurrentStatus(current);
      }
    } catch (error) {
      if (this.isConnected && requestedUploadId === this.currentUploadId) {
        this.errorMessage = normalizeError(error);
        this.announcement = this.errorMessage;
      }
    }
  }

  schedulePoll() {
    this.clearPoll();
    if (
      this.isConnected &&
      !TERMINAL.has(this.currentStatus) &&
      !this.isOffline
    ) {
      this.pollTimer = window.setTimeout(async () => {
        await this.refreshCurrentUploadStatus();
        this.schedulePoll();
      }, POLL_INTERVAL);
    }
  }

  clearPoll() {
    if (this.pollTimer) {
      window.clearTimeout(this.pollTimer);
      this.pollTimer = undefined;
    }
  }

  handleReset() {
    this.clearPoll();
    this.currentUploadId = undefined;
    this.currentStatus = undefined;
    this.clearStagedFile();
    this.errorMessage = undefined;
    this.announcement = labels.ReadyAgain;
    this.refreshHistory();
  }

  clearStagedFile() {
    this.fileName = undefined;
    this.fileText = undefined;
    this.preview = undefined;
    this.idempotencyKey = undefined;
    this.template.querySelector("c-bulk-record-upload-file-input")?.reset?.();
  }

  rotateIdempotencyKey() {
    if (this.fileText) {
      this.idempotencyKey = createIdempotencyKey();
    }
  }

  handleDownload(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: `/sfc/servlet.shepherd/document/download/${event.detail.documentId}`
      }
    });
  }

  handleOnline = () => {
    this.isOffline = false;
    this.announcement = labels.NetworkRestored;
    if (this.currentUploadId) {
      this.schedulePoll();
    }
  };

  handleOffline = () => {
    this.isOffline = true;
    this.announcement = labels.NetworkLost;
    this.clearPoll();
  };
}
