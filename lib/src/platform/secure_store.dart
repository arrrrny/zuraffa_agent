// SecureStore — key validation + platform rejection mapping
// (spec 115 FR-003). Pure Dart: runs before any platform call.

/// A platform-side rejection mapped to a named engine type.
final class SecureStoreException implements Exception {
  /// The key the failed operation targeted.
  final String key;

  /// The operation that failed: read / write / delete.
  final String operation;

  /// The underlying platform error.
  final Object cause;

  const SecureStoreException({
    required this.key,
    required this.operation,
    required this.cause,
  });

  @override
  String toString() =>
      'SecureStoreException(key: $key, operation: $operation, cause: $cause)';
}

/// Key validation for the secure store seam.
abstract final class SecureStore {
  /// Throws [ArgumentError] when [key] is empty, whitespace-only, or
  /// contains a NUL — before any platform call is attempted.
  static void validate(String key) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'must be non-empty');
    }
    if (key.contains('\x00')) {
      throw ArgumentError.value(key, 'key', 'must not contain NUL bytes');
    }
  }

  /// Maps a platform rejection into [SecureStoreException].
  static SecureStoreException map(
    String key, {
    required String operation,
    required Object cause,
  }) {
    return SecureStoreException(key: key, operation: operation, cause: cause);
  }
}
