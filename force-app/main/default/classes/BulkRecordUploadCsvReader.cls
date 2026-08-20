/**
 * Parses the bounded comma-separated input contract without record access or logging input values.
 */
public class BulkRecordUploadCsvReader {
  private static final String UTF8_BOM = String.fromCharArray(
    new List<Integer>{ 65279 }
  );

  /**
   * Parses one UTF-8 CSV string using RFC 4180-style quoting.
   * @param csvText Decoded UTF-8 CSV content.
   * @return Parsed normalized headers and correlated rows.
   * @throws BulkRecordUploadException for malformed or out-of-bound input.
   */
  public BulkRecordUploadParsedCsv parse(String csvText) {
    if (String.isBlank(csvText)) {
      throw new BulkRecordUploadException('The CSV file is empty.');
    }
    if (
      Blob.valueOf(csvText).size() >
      BulkRecordUploadRuntimeContract.MAX_CSV_BYTES
    ) {
      throw new BulkRecordUploadException(
        'The CSV file exceeds the 2 MB limit.'
      );
    }
    if (csvText.contains(String.fromCharArray(new List<Integer>{ 0 }))) {
      throw new BulkRecordUploadException(
        'The CSV file contains a prohibited NUL character.'
      );
    }
    ParseState state = new ParseState();
    Integer indexValue = 0;
    while (indexValue < csvText.length()) {
      String character = csvText.substring(indexValue, indexValue + 1);
      if (character == '"') {
        indexValue = consumeQuote(csvText, indexValue, state);
      } else if (character == ',' && !state.insideQuotes) {
        state.finishCell();
      } else if (
        (character == '\r' || character == '\n') && !state.insideQuotes
      ) {
        indexValue = consumeRecordSeparator(
          csvText,
          indexValue,
          character,
          state
        );
      } else {
        state.append(character);
        if (character == '\n') {
          state.physicalLine++;
        }
      }
      indexValue++;
    }
    if (state.insideQuotes) {
      throw new BulkRecordUploadException(
        'The CSV contains an unterminated quoted value.'
      );
    }
    state.finishFinalRecord();
    return state.toParsedCsv();
  }

  private static Integer consumeQuote(
    String csvText,
    Integer indexValue,
    ParseState state
  ) {
    if (state.insideQuotes) {
      Boolean escaped =
        indexValue + 1 < csvText.length() &&
        csvText.substring(indexValue + 1, indexValue + 2) == '"';
      if (escaped) {
        state.append('"');
        return indexValue + 1;
      }
      state.insideQuotes = false;
      state.afterClosingQuote = true;
      return indexValue;
    }
    if (state.cellValue.length() > 0 || state.afterClosingQuote) {
      throw new BulkRecordUploadException('The CSV contains an invalid quote.');
    }
    state.insideQuotes = true;
    return indexValue;
  }

  private static Integer consumeRecordSeparator(
    String csvText,
    Integer indexValue,
    String character,
    ParseState state
  ) {
    state.finishCell();
    state.finishRecord();
    state.physicalLine++;
    if (
      character == '\r' &&
      indexValue + 1 < csvText.length() &&
      csvText.substring(indexValue + 1, indexValue + 2) == '\n'
    ) {
      return indexValue + 1;
    }
    return indexValue;
  }

  private class ParseState {
    private Boolean insideQuotes = false;
    private Boolean afterClosingQuote = false;
    private String cellValue = '';
    private List<String> recordValues = new List<String>();
    private List<List<String>> records = new List<List<String>>();
    private List<Integer> recordStartLines = new List<Integer>();
    private Integer physicalLine = 1;
    private Integer currentRecordStartLine = 1;

    private void append(String character) {
      if (afterClosingQuote && !insideQuotes) {
        throw new BulkRecordUploadException(
          'Unexpected text follows a closing quote.'
        );
      }
      cellValue += character;
      if (
        cellValue.length() >
        BulkRecordUploadRuntimeContract.MAX_CSV_CELL_CHARACTERS
      ) {
        throw new BulkRecordUploadException(
          'A CSV value exceeds the 32,000 character limit.'
        );
      }
    }

    private void finishCell() {
      recordValues.add(cellValue);
      if (
        recordValues.size() > BulkRecordUploadRuntimeContract.MAX_CSV_COLUMNS
      ) {
        throw new BulkRecordUploadException(
          'The CSV exceeds the 100 column limit.'
        );
      }
      cellValue = '';
      afterClosingQuote = false;
    }

    private void finishRecord() {
      records.add(new List<String>(recordValues));
      recordStartLines.add(currentRecordStartLine);
      if (records.size() > BulkRecordUploadRuntimeContract.MAX_CSV_ROWS + 1) {
        throw new BulkRecordUploadException(
          'The CSV exceeds the 5,000 row limit.'
        );
      }
      recordValues.clear();
      currentRecordStartLine = physicalLine + 1;
    }

    private void finishFinalRecord() {
      if (
        cellValue.length() > 0 ||
        !recordValues.isEmpty() ||
        afterClosingQuote
      ) {
        finishCell();
        finishRecord();
      }
      while (!records.isEmpty() && isBlankRecord(records[records.size() - 1])) {
        records.remove(records.size() - 1);
        recordStartLines.remove(recordStartLines.size() - 1);
      }
      if (records.isEmpty()) {
        throw new BulkRecordUploadException('The CSV file is empty.');
      }
    }

    private BulkRecordUploadParsedCsv toParsedCsv() {
      List<String> headers = normalizeHeaders(records[0]);
      List<BulkRecordUploadRow> rows = new List<BulkRecordUploadRow>();
      for (
        Integer recordIndex = 1; recordIndex < records.size(); recordIndex++
      ) {
        List<String> values = records[recordIndex];
        if (values.size() != headers.size()) {
          throw new BulkRecordUploadException(
            'A CSV row has a different column count than the header.'
          );
        }
        Map<String, String> valuesByColumn = new Map<String, String>();
        for (
          Integer columnIndex = 0; columnIndex < headers.size(); columnIndex++
        ) {
          valuesByColumn.put(headers[columnIndex], values[columnIndex]);
        }
        rows.add(
          new BulkRecordUploadRow(recordStartLines[recordIndex], valuesByColumn)
        );
      }
      return new BulkRecordUploadParsedCsv(headers, rows);
    }

    private List<String> normalizeHeaders(List<String> rawHeaders) {
      List<String> headers = new List<String>();
      Set<String> uniqueHeaders = new Set<String>();
      for (String rawHeader : rawHeaders) {
        if (
          headers.isEmpty() &&
          rawHeader != null &&
          rawHeader.startsWith(UTF8_BOM)
        ) {
          rawHeader = rawHeader.substring(1);
        }
        String header = rawHeader == null
          ? null
          : rawHeader.trim().toLowerCase();
        if (String.isBlank(header)) {
          throw new BulkRecordUploadException('CSV headers cannot be blank.');
        }
        if (uniqueHeaders.contains(header)) {
          throw new BulkRecordUploadException('CSV headers must be unique.');
        }
        uniqueHeaders.add(header);
        headers.add(header);
      }
      return headers;
    }

    private Boolean isBlankRecord(List<String> values) {
      for (String value : values) {
        if (!String.isBlank(value)) {
          return false;
        }
      }
      return true;
    }
  }
}
