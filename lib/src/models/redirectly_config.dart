/// Configuration for initializing Flutter Redirectly
class RedirectlyConfig {
  /// API key for authentication with Redirectly backend
  final String apiKey;

  /// Base URL for the Redirectly API (defaults to redirectly.app)
  final String? baseUrl;

  /// Whether to enable debug logging
  final bool enableDebugLogging;

  const RedirectlyConfig({
    required this.apiKey,
    this.baseUrl,
    this.enableDebugLogging = false,
  });

  /// Default base URL for Redirectly API
  static const String defaultBaseUrl = 'https://redirectly.app';

  /// Get the effective base URL
  String get effectiveBaseUrl => baseUrl ?? defaultBaseUrl;

  @override
  String toString() {
    return 'RedirectlyConfig(apiKey: ${apiKey.substring(0, 8)}..., baseUrl: $effectiveBaseUrl, debug: $enableDebugLogging)';
  }
}
