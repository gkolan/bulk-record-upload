/** Parses and composes {columnKey} source templates for derived columns. */
public class BulkRecordUploadSourceTemplate {
  /** @return The normalized {token} column keys referenced by the template. */
  public static Set<String> tokens(String template) {
    Set<String> tokens = new Set<String>();
    Integer index = 0;
    while (index < template.length()) {
      Integer openBrace = template.indexOf('{', index);
      if (openBrace == -1) {
        break;
      }
      Integer closeBrace = template.indexOf('}', openBrace);
      if (closeBrace == -1) {
        break;
      }
      tokens.add(
        template.substring(openBrace + 1, closeBrace).trim().toLowerCase()
      );
      index = closeBrace + 1;
    }
    return tokens;
  }

  /**
   * Substitutes each {token} with its raw value, using an empty string for a
   * missing or blank referenced column.
   */
  public static String compose(String template, Map<String, String> rawValues) {
    String result = '';
    Integer index = 0;
    while (index < template.length()) {
      Integer openBrace = template.indexOf('{', index);
      if (openBrace == -1) {
        result += template.substring(index);
        break;
      }
      result += template.substring(index, openBrace);
      Integer closeBrace = template.indexOf('}', openBrace);
      if (closeBrace == -1) {
        result += template.substring(openBrace);
        break;
      }
      String token = template
        .substring(openBrace + 1, closeBrace)
        .trim()
        .toLowerCase();
      String tokenValue = rawValues.get(token);
      result += tokenValue == null ? '' : tokenValue;
      index = closeBrace + 1;
    }
    return result;
  }
}
