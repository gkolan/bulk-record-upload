import { LightningElement, api } from "lwc";
import { labels } from "c/bulkRecordUploadLabels";

const MAX_BYTES = 2_000_000;

export default class BulkRecordUploadFileInput extends LightningElement {
  @api disabled = false;
  label = labels;
  fileName;

  get displayIcon() {
    return this.fileName ? "utility:file" : "utility:upload";
  }

  get displayVariant() {
    return this.fileName ? "success" : "default";
  }

  get displayLabel() {
    return this.fileName || "Click to select a CSV file";
  }

  handleFileClick(event) {
    event.target.value = "";
  }

  handleFileChange(event) {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }
    this.fileName = file.name;
    if (file.size > MAX_BYTES) {
      this.dispatchEvent(
        new CustomEvent("fileerror", {
          detail: { message: labels.CsvTooLarge }
        })
      );
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      this.dispatchEvent(
        new CustomEvent("fileready", {
          detail: { fileName: file.name, text: reader.result }
        })
      );
    };
    reader.onerror = () => {
      this.dispatchEvent(
        new CustomEvent("fileerror", {
          detail: { message: labels.CsvReadError }
        })
      );
    };
    reader.readAsText(file, "UTF-8");
  }
}
