/**
 * The one trusted extension point a subscriber may implement. An
 * implementation may transform rows and observe results. The package never
 * delegates mapped target-row persistence to an extension; that persistence
 * stays package-owned and user-mode, per ADR-0007. An extension is subscriber
 * Apex and must be reviewed like any other Apex because the platform does not
 * sandbox it from performing its own work.
 */
public interface BulkRecordUploadExtension {
  /**
   * Runs before row mapping and package-owned target-row persistence.
   * @param projection Immutable approved process projection.
   * @param rows Bounded parsed rows for one chunk.
   * @return Transformed rows preserving physical row correlation.
   */
  List<BulkRecordUploadRow> beforeMap(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows
  );

  /**
   * Runs after one bounded package-owned persistence invocation completes.
   * @param uploadId Authorized upload identifier.
   * @param projection Immutable approved process projection.
   * @param outcomes Safe row results; never raw CSV content.
   */
  void afterProcess(
    Id uploadId,
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRowResult> outcomes
  );
}
