import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSelection from "@salesforce/apex/BulkRecordUploadController.getSelection";
import getProcessPresentation from "@salesforce/apex/BulkRecordUploadController.getProcessPresentation";
import getTemplate from "@salesforce/apex/BulkRecordUploadController.getTemplate";
import getHistory from "@salesforce/apex/BulkRecordUploadController.getHistory";
import getHistoryForProcess from "@salesforce/apex/BulkRecordUploadController.getHistoryForProcess";
import submit from "@salesforce/apex/BulkRecordUploadController.submit";
import { formatLabel, labels } from "c/bulkRecordUploadLabels";
import {
  createIdempotencyKey,
  normalizeError,
  parsePreview
} from "c/bulkRecordUploadUtils";

const TERMINAL = new Set(["COMPLETED", "COMPLETED_WITH_ERRORS", "FAILED"]);
const POLL_INTERVAL = 3000;

export default class BulkRecordUpload extends NavigationMixin(
  LightningElement
) {
  @api contextRecordId;
  @api contextObjectApiName;
  @api bundleDeveloperName;
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

  connectedCallback() {
    window.addEventListener("online", this.handleOnline);
    window.addEventListener("offline", this.handleOffline);
    if (!this.isBundleConfigured) {
      this.isLoading = false;
      this.announcement = labels.BundleNotConfigured;
      return;
    }
    this.initialize();
  }

  disconnectedCallback() {
    window.removeEventListener("online", this.handleOnline);
    window.removeEventListener("offline", this.handleOffline);
    this.clearPoll();
  }

  get isBusy() {
    return this.isLoading || this.isSubmitting;
  }

  get isBundleConfigured() {
    return Boolean(this.bundleDeveloperName?.trim());
  }

  get displaySubtitle() {
    return (
      this.subtitle ||
      "Upload approved CSV files and monitor processing results."
    );
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
    return this.isBusy || this.isOffline || !this.processKey || !this.fileText;
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
        bundleDeveloperName: this.bundleDeveloperName
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
    this.processKey = event.detail.value;
    this.errorMessage = undefined;
    await this.refreshPresentation();
  }

  async refreshPresentation() {
    this.subtitle = undefined;
    this.instructions = undefined;
    this.iconName = "utility:upload";
    if (!this.processKey) {
      return;
    }
    try {
      const presentation = await getProcessPresentation({
        processKey: this.processKey
      });
      this.subtitle = presentation.subtitle;
      this.instructions = presentation.instructions;
      this.iconName = presentation.iconName || "utility:upload";
    } catch (error) {
      this.errorMessage = normalizeError(error);
    }
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
      this.preview = undefined;
      this.fileText = undefined;
      this.errorMessage = normalizeError(error);
    }
  }

  handleFileError(event) {
    this.preview = undefined;
    this.fileText = undefined;
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
          contentBase64: toBase64(this.fileText),
          idempotencyKey: this.idempotencyKey,
          contextRecordId: this.contextRecordId
        }
      });
      this.currentUploadId = response.uploadId;
      this.currentStatus = response.status;
      this.announcement = response.isDuplicate
        ? labels.DuplicateReturned
        : labels.UploadQueued;
      this.dispatchEvent(
        new ShowToastEvent({
          title: response.isDuplicate
            ? labels.ExistingTitle
            : labels.QueuedTitle,
          message: this.announcement,
          variant: "success"
        })
      );
      this.schedulePoll();
    } catch (error) {
      this.errorMessage = normalizeError(error);
      this.announcement = this.errorMessage;
    } finally {
      this.isSubmitting = false;
    }
  }

  async refreshHistory() {
    this.historyLoading = true;
    this.historyError = undefined;
    try {
      const rows = this.usesFixedProcess
        ? await getHistoryForProcess({ processKey: this.processKey })
        : await getHistory();
      this.historyRows = rows.map((row) => ({
        ...row,
        downloadDisabled: !row.resultFileId
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
      this.currentStatus = current.status;
      this.announcement = formatLabel(
        labels.StatusAnnouncement,
        current.status
      );
      if (TERMINAL.has(current.status)) {
        this.clearPoll();
      }
    }
  }

  schedulePoll() {
    this.clearPoll();
    if (!TERMINAL.has(this.currentStatus) && !this.isOffline) {
      this.pollTimer = window.setTimeout(async () => {
        await this.refreshHistory();
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
    this.fileName = undefined;
    this.fileText = undefined;
    this.preview = undefined;
    this.idempotencyKey = undefined;
    this.errorMessage = undefined;
    this.announcement = labels.ReadyAgain;
    this.refreshHistory();
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

function toBase64(value) {
  const bytes = new TextEncoder().encode(value);
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}
