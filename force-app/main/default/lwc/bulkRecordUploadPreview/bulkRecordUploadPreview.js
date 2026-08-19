import { LightningElement, api } from "lwc";
import { formatLabel, labels } from "c/bulkRecordUploadLabels";

export default class BulkRecordUploadPreview extends LightningElement {
  @api preview;
  label = labels;

  get summary() {
    return formatLabel(
      labels.PreviewSummary,
      this.preview.totalRows,
      this.preview.totalColumns
    );
  }
}
