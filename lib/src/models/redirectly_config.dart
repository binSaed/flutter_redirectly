/// Configuration for initializing Flutter Redirectly
class RedirectlyConfig {
  /// API key for authentication with Redirectly backend
  final String apiKey;

  /// Whether to enable debug logging
  final bool enableDebugLogging;

  const RedirectlyConfig({
    required this.apiKey,
    this.enableDebugLogging = false,
  });

  /// Default base URL for Redirectly API
  static const String defaultBaseUrl = 'https://redirectly.app';

  /// Get the effective base URL
  String get effectiveBaseUrl => defaultBaseUrl;

  @override
  String toString() {
    return 'RedirectlyConfig(apiKey: ${apiKey.substring(0, 8)}..., baseUrl: $effectiveBaseUrl, debug: $enableDebugLogging)';
  }
}
