import { LightningElement, api } from "lwc";
import { labels } from "c/bulkRecordUploadLabels";

export default class BulkRecordUploadHistory extends LightningElement {
  @api rows = [];
  @api isLoading = false;
  @api errorMessage;
  label = labels;

  get hasRows() {
    return this.rows.length > 0;
  }

  handleRefresh() {
    this.dispatchEvent(new CustomEvent("refresh"));
  }

  handleDownload(event) {
    this.dispatchEvent(new CustomEvent("download", { detail: event.detail }));
  }
}
