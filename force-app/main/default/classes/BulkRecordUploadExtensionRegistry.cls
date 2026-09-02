/**
 * The package's one open extension point. Resolves subscriber-registered
 * extension class names into validated, ordered instances. A class name is
 * never trusted as-is: it must resolve through Type.forName, instantiate,
 * and be assignable to BulkRecordUploadExtension. Any failure is a
 * configuration error naming the class, never a silent skip. Called both at
 * configuration load and at every run, so a class removed or broken after
 * configuration is caught before it can run.
 */
public with sharing class BulkRecordUploadExtensionRegistry {
  /**
   * Resolves ordered, validated extension instances.
   * @param orderedClassNames Extension class names in run order.
   * @return Fresh, validated extension instances in the same order.
   * @throws BulkRecordUploadException naming the class when a name does not
   *   resolve, does not instantiate, or does not implement the required
   *   interface, or when the count exceeds the bounded maximum.
   */
  public List<BulkRecordUploadExtension> resolve(
    List<String> orderedClassNames
  ) {
    List<String> classNames = orderedClassNames == null
      ? new List<String>()
      : orderedClassNames;
    if (
      classNames.size() >
      BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS
    ) {
      throw new BulkRecordUploadException(
        'Too many extensions are registered for this process.'
      );
    }
    List<BulkRecordUploadExtension> extensions = new List<BulkRecordUploadExtension>();
    for (String className : classNames) {
      extensions.add(resolveOne(className));
    }
    return extensions;
  }

  private static BulkRecordUploadExtension resolveOne(String className) {
    String trimmedName = String.isBlank(className) ? null : className.trim();
    Object instance;
    try {
      Type extensionType = trimmedName == null
        ? null
        : Type.forName(trimmedName);
      instance = extensionType == null ? null : extensionType.newInstance();
    } catch (Exception error) {
      instance = null;
    }
    if (!(instance instanceof BulkRecordUploadExtension)) {
      throw new BulkRecordUploadException(
        'The configured upload extension "' +
          String.valueOf(trimmedName) +
          '" is not registered.'
      );
    }
    return (BulkRecordUploadExtension) instance;
  }
}
