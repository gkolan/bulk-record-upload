import { LightningElement, api } from "lwc";
import { labels } from "c/bulkRecordUploadLabels";

export default class BulkRecordUploadProcessSelector extends LightningElement {
  @api value;
  @api disabled = false;
  @api processOptions = [];
  @api helpText;
  label = labels;

  get options() {
    return this.processOptions;
  }

  handleChange(event) {
    this.dispatchEvent(
      new CustomEvent("processchange", {
        detail: { value: event.detail.value }
      })
    );
  }
}
