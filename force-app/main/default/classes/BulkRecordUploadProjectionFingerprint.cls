/** Builds deterministic configuration and current-user cache fingerprints. */
public with sharing class BulkRecordUploadProjectionFingerprint {
  /** Hashes every process and field setting that changes runtime behavior. */
  public static String configHash(
    BulkRecordUploadConfigRepository.Configuration configuration,
    List<String> extensionClassNames,
    BulkRecordUploadContextProjection contextProjection
  ) {
    JSONGenerator json = JSON.createGenerator(false);
    json.writeStartObject();
    writeString(json, 'processKey', configuration.process.processKey);
    writeString(json, 'objectApiName', configuration.process.objectApiName);
    writeString(json, 'operation', configuration.process.operation);
    writeString(
      json,
      'previewPermission',
      configuration.process.previewPermission
    );
    writeString(json, 'processorKey', configuration.process.processorKey);
    writeString(json, 'processingMode', configuration.process.processingMode);
    json.writeNumberField(
      'contractVersion',
      configuration.process.contractVersion
    );
    writeString(
      json,
      'recordContextAction',
      configuration.process.recordContextAction
    );
    writeString(
      json,
      'hostObjectApiName',
      configuration.process.hostObjectApiName
    );
    writeString(
      json,
      'recordContextFieldApiName',
      configuration.process.recordContextFieldApiName
    );
    json.writeNumberField('batchSize', configuration.process.batchSize);
    json.writeNumberField('retentionDays', configuration.process.retentionDays);
    writeStrings(json, 'extensionClassNames', extensionClassNames);
    writeContext(json, contextProjection);
    json.writeFieldName('fields');
    json.writeStartArray();
    for (BulkRecordUploadFieldConfig field : configuration.getFields()) {
      writeField(json, field);
    }
    json.writeEndArray();
    json.writeEndObject();
    return digest(json.getAsString());
  }

  /** Creates a versioned key scoped to configuration and authorization state. */
  public static String cacheKey(
    BulkRecordUploadProcessConfig process,
    String configHash,
    Schema.DescribeSObjectResult objectDescribe
  ) {
    String accessFingerprint = digest(
      String.join(
        new List<String>{
          String.valueOf(objectDescribe.isCreateable()),
          String.valueOf(objectDescribe.isUpdateable()),
          String.valueOf(objectDescribe.isDeletable()),
          String.valueOf(
            FeatureManagement.checkPermission('Bulk_Record_Upload_Run')
          ),
          String.valueOf(
            FeatureManagement.checkPermission('Bulk_Record_Upload_Delete')
          ),
          String.valueOf(
            FeatureManagement.checkPermission('Bulk_Record_Upload_Preview')
          ),
          UserInfo.getLocale()
        },
        ':'
      )
    );
    return 'bru:projection:3:0.1:' +
      process.processKey +
      ':' +
      configHash +
      ':' +
      accessFingerprint;
  }

  private static void writeField(
    JSONGenerator json,
    BulkRecordUploadFieldConfig field
  ) {
    json.writeStartObject();
    writeString(json, 'columnKey', field.columnKey);
    writeString(json, 'displayLabel', field.displayLabel);
    writeString(json, 'fieldApiName', field.fieldApiName);
    writeString(json, 'existingValueAction', field.existingValueAction);
    writeString(json, 'blankValueAction', field.blankValueAction);
    writeString(json, 'textSeparator', field.textSeparator);
    writeString(json, 'customSeparator', field.customSeparator);
    writeString(json, 'duplicateTextAction', field.duplicateTextAction);
    writeString(json, 'overflowAction', field.overflowAction);
    writeString(json, 'defaultValue', field.defaultValue);
    json.writeBooleanField('trimValue', field.trimValue);
    writeString(json, 'caseAction', field.caseAction);
    List<String> blankTokens = new List<String>(field.blankTokens);
    blankTokens.sort();
    writeStrings(json, 'blankTokens', blankTokens);
    writeString(
      json,
      'customMergeStrategyClass',
      field.customMergeStrategyClass
    );
    writeString(json, 'validationPattern', field.validationPattern);
    writeDecimal(json, 'minValue', field.minValue);
    writeDecimal(json, 'maxValue', field.maxValue);
    writeString(json, 'sourceTemplate', field.sourceTemplate);
    writeString(json, 'lookupMatchField', field.lookupMatchField);
    json.writeNumberField('sequence', field.sequence);
    json.writeBooleanField('isRequired', field.isRequired);
    json.writeBooleanField('isMatchKey', field.isMatchKey);
    json.writeBooleanField('isUpsertKey', field.isUpsertKey);
    json.writeBooleanField('includeInResult', field.includeInResult);
    json.writeEndObject();
  }

  private static void writeContext(
    JSONGenerator json,
    BulkRecordUploadContextProjection context
  ) {
    json.writeFieldName('context');
    if (context == null) {
      json.writeNull();
      return;
    }
    json.writeStartObject();
    writeString(json, 'recordContextSource', context.recordContextSource);
    writeString(json, 'primarySearchField', context.primarySearchField);
    writeStrings(
      json,
      'additionalSearchFields',
      context.additionalSearchFields
    );
    writeString(json, 'primaryDisplayField', context.primaryDisplayField);
    writeStrings(
      json,
      'additionalDisplayFields',
      context.additionalDisplayFields
    );
    json.writeFieldName('filterConditions');
    json.writeStartArray();
    for (
      BulkRecordUploadContextFilterCondition condition : context.filterConditions
    ) {
      json.writeStartObject();
      writeString(json, 'fieldApiName', condition.fieldApiName);
      writeString(json, 'operatorCode', condition.operatorCode);
      writeString(json, 'fieldType', condition.fieldType);
      writeStrings(json, 'values', condition.values);
      json.writeEndObject();
    }
    json.writeEndArray();
    json.writeEndObject();
  }

  private static void writeString(
    JSONGenerator json,
    String name,
    String value
  ) {
    json.writeStringField(name, value == null ? '' : value);
  }

  private static void writeStrings(
    JSONGenerator json,
    String name,
    List<String> values
  ) {
    json.writeFieldName(name);
    json.writeStartArray();
    for (String value : values) {
      json.writeString(value == null ? '' : value);
    }
    json.writeEndArray();
  }

  private static void writeDecimal(
    JSONGenerator json,
    String name,
    Decimal value
  ) {
    if (value == null) {
      json.writeNullField(name);
    } else {
      json.writeNumberField(name, value);
    }
  }

  private static String digest(String value) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(value))
    );
  }
}
