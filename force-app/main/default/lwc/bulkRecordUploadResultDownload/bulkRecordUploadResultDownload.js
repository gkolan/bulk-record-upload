import { LightningElement, api } from "lwc";
import { labels } from "c/bulkRecordUploadLabels";

export default class BulkRecordUploadResultDownload extends LightningElement {
  @api documentId;
  @api expired = false;

  get disabled() {
    return this.expired || !this.documentId;
  }

  get label() {
    return this.expired ? labels.ResultExpired : labels.DownloadResult;
  }

  handleDownload() {
    if (!this.disabled) {
      this.dispatchEvent(
        new CustomEvent("download", {
          detail: { documentId: this.documentId }
        })
      );
    }
  }
}
