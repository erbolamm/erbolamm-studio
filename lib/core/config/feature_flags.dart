/// Central feature switches for capabilities that are not part of the
/// local-first Studio experience yet.
abstract final class FeatureFlags {
  /// Enables Firebase authentication, publishing, and cloud pipeline steps.
  ///
  /// Keep disabled until cloud workflows are intentionally reintroduced.
  static const bool cloudEnabled = bool.fromEnvironment(
    'CLOUD_ENABLED',
    defaultValue: false,
  );
}
