/**
 * Bounded transaction cache for immutable compact projections. Correctness never depends on a cache hit.
 */
public class BulkRecordUploadProjectionCache {
  private static final Integer MAX_ENTRIES = 50;
  private static Map<String, String> serializedByKey = new Map<String, String>();
  private static List<String> insertionOrder = new List<String>();

  /**
   * Finds and safely deserializes a projection.
   * @param key Versioned non-sensitive cache key.
   * @return Cached projection or null on miss/corruption.
   */
  public BulkRecordUploadProjectionV1 find(String key) {
    if (String.isBlank(key) || !serializedByKey.containsKey(key)) {
      return null;
    }
    try {
      return (BulkRecordUploadProjectionV1) JSON.deserialize(
        serializedByKey.get(key),
        BulkRecordUploadProjectionV1.class
      );
    } catch (JSONException exceptionValue) {
      remove(key);
      return null;
    }
  }

  /**
   * Stores a complete projection and evicts the oldest key at the size boundary.
   * @param key Versioned non-sensitive cache key.
   * @param projection Complete immutable projection.
   */
  public void put(String key, BulkRecordUploadProjectionV1 projection) {
    if (String.isBlank(key) || projection == null) {
      return;
    }
    if (
      !serializedByKey.containsKey(key) && serializedByKey.size() >= MAX_ENTRIES
    ) {
      remove(insertionOrder[0]);
    }
    if (!serializedByKey.containsKey(key)) {
      insertionOrder.add(key);
    }
    serializedByKey.put(key, JSON.serialize(projection));
  }

  /** Clears transaction state for deterministic tests. */
  @TestVisible
  private static void clear() {
    serializedByKey.clear();
    insertionOrder.clear();
  }

  /** Injects a corrupt value to prove miss-path recovery. */
  @TestVisible
  private static void putCorrupt(String key) {
    serializedByKey.put(key, '{not-json');
    insertionOrder.add(key);
  }

  private static void remove(String key) {
    serializedByKey.remove(key);
    insertionOrder.remove(insertionOrder.indexOf(key));
  }
}
