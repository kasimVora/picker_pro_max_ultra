/// Represents the different states of a loading process.
enum LoadStatus {
  /// Initial state before loading starts.
  initial,

  /// State when loading is in progress.
  loading,

  /// State when loading has completed successfully.
  success,

  /// State when loading has failed.
  failure,

  /// State when additional data is being loaded.
  loadingMore,
}
