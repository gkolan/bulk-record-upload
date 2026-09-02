import { LightningElement, api } from "lwc";
import { labels } from "c/bulkRecordUploadLabels";

const STATUS = {
  QUEUED: { progress: 20, message: labels.StateQueued },
  VALIDATING: { progress: 40, message: labels.StateValidating },
  PROCESSING: { progress: 70, message: labels.StateProcessing },
  COMPLETED: { progress: 100, message: labels.StateCompleted },
  COMPLETED_WITH_ERRORS: {
    progress: 100,
    message: labels.StatePartial
  },
  FAILED: {
    progress: 100,
    message: labels.StateFailed
  }
};

export default class BulkRecordUploadProgress extends LightningElement {
  @api status = "QUEUED";
  label = labels;

  get state() {
    return STATUS[this.status] || STATUS.QUEUED;
  }

  get progress() {
    return this.state.progress;
  }

  get message() {
    return this.state.message;
  }

  get isTerminal() {
    return ["COMPLETED", "COMPLETED_WITH_ERRORS", "FAILED"].includes(
      this.status
    );
  }

  handleReset() {
    this.dispatchEvent(new CustomEvent("reset"));
  }
}
