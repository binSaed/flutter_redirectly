/// Represents errors that can occur in Flutter Redirectly operations
class RedirectlyError implements Exception {
  /// Error message
  final String message;

  /// HTTP status code if this is an API error
  final int? statusCode;

  /// Error type for categorization
  final RedirectlyErrorType type;

  /// Additional error details
  final Map<String, dynamic>? details;

  const RedirectlyError({
    required this.message,
    this.statusCode,
    required this.type,
    this.details,
  });

  /// Create an API error from HTTP response
  factory RedirectlyError.apiError({
    required String message,
    required int statusCode,
    Map<String, dynamic>? details,
  }) {
    return RedirectlyError(
      message: message,
      statusCode: statusCode,
      type: RedirectlyErrorType.api,
      details: details,
    );
  }

  /// Create a network error
  factory RedirectlyError.networkError(String message) {
    return RedirectlyError(
      message: message,
      type: RedirectlyErrorType.network,
    );
  }

  /// Create a configuration error
  factory RedirectlyError.configError(String message) {
    return RedirectlyError(
      message: message,
      type: RedirectlyErrorType.configuration,
    );
  }

  /// Create a link resolution error
  factory RedirectlyError.linkError(String message) {
    return RedirectlyError(
      message: message,
      type: RedirectlyErrorType.linkResolution,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('RedirectlyError: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (details != null) {
      buffer.write(' Details: $details');
    }
    return buffer.toString();
  }
}

/// Types of errors that can occur
enum RedirectlyErrorType {
  /// API-related errors (HTTP errors, server errors)
  api,

  /// Network connectivity errors
  network,

  /// Configuration or initialization errors
  configuration,

  /// Link resolution errors
  linkResolution,

  /// Unknown errors
  unknown,
}
