import { LightningElement, api } from "lwc";
import { labels } from "c/bulkRecordUploadLabels";

export default class BulkRecordUploadConfirmation extends LightningElement {
  @api disabled = false;
  label = labels;

  handleConfirm() {
    if (!this.disabled) {
      this.dispatchEvent(new CustomEvent("uploadconfirm"));
    }
  }
}
