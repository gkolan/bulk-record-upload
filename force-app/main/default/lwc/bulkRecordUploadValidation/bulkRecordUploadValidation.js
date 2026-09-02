import { LightningElement, api } from "lwc";
import { formatLabel, labels } from "c/bulkRecordUploadLabels";

export default class BulkRecordUploadValidation extends LightningElement {
  @api processKey;
  @api fileName;
  @api rowCount = 0;
  label = labels;

  get hasSelection() {
    return Boolean(this.processKey && this.fileName);
  }

  get summary() {
    return formatLabel(labels.ValidationSummary, this.rowCount);
  }
}
