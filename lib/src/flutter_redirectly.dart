import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;

import 'models/models.dart';
import 'platform/flutter_redirectly_platform_interface.dart';

/// Main Flutter Redirectly plugin class
///
/// This class provides functionality similar to Firebase Dynamic Links
/// but uses your own Redirectly backend.
class FlutterRedirectly {
  static final FlutterRedirectly _instance = FlutterRedirectly._internal();

  /// Singleton instance
  factory FlutterRedirectly() => _instance;

  FlutterRedirectly._internal();

  /// App links instance for handling deep links
  final _appLinks = AppLinks();

  /// Configuration
  RedirectlyConfig? _config;

  /// Stream controller for link clicks
  final _linkClickController =
      StreamController<RedirectlyLinkClick>.broadcast();

  /// HTTP client
  final _httpClient = http.Client();

  bool _initialized = false;
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize the plugin with configuration
  Future<void> initialize(RedirectlyConfig config) async {
    if (_initialized) {
      throw RedirectlyError.configError(
          'FlutterRedirectly is already initialized');
    }

    _config = config;

    try {
      // Initialize platform-specific implementation
      await FlutterRedirectlyPlatform.instance.initialize(config);

      // Set up app links listening
      await _setupAppLinks();

      _initialized = true;

      if (config.enableDebugLogging) {
        print('FlutterRedirectly initialized successfully');
      }
    } catch (e) {
      throw RedirectlyError.configError('Failed to initialize: $e');
    }
  }

  /// Set up app links for handling deep links
  Future<void> _setupAppLinks() async {
    // Listen to incoming links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (error) {
        final linkClick = RedirectlyLinkClick(
          originalUrl: 'unknown',
          slug: 'unknown',
          username: 'unknown',
          error: RedirectlyError.linkError('Failed to process link: $error'),
          receivedAt: DateTime.now(),
        );
        _linkClickController.add(linkClick);
      },
    );

    // Handle initial link if app was opened via a link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleIncomingLink(initialUri);
      }
    } catch (e) {
      if (_config?.enableDebugLogging == true) {
        print('No initial link found: $e');
      }
    }
  }

  /// Handle incoming link
  Future<void> _handleIncomingLink(Uri uri) async {
    if (!_initialized || _config == null) {
      _linkClickController.add(
        RedirectlyLinkClick(
          originalUrl: uri.toString(),
          slug: 'unknown',
          username: 'unknown',
          error: RedirectlyError.configError('Plugin not initialized'),
          receivedAt: DateTime.now(),
        ),
      );
      return;
    }

    try {
      final linkClick = await _processRedirectlyLink(uri);
      _linkClickController.add(linkClick);
    } catch (e) {
      _linkClickController.add(
        RedirectlyLinkClick(
          originalUrl: uri.toString(),
          slug: 'unknown',
          username: 'unknown',
          error: RedirectlyError.linkError('Failed to process link: $e'),
          receivedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Process a Redirectly link and fetch details from backend
  Future<RedirectlyLinkClick> _processRedirectlyLink(Uri uri) async {
    final originalUrl = uri.toString();

    // Extract username and slug from URL
    // Format: https://username.redirectly.app/slug
    final host = uri.host;
    final pathSegments = uri.pathSegments;

    String username;
    String slug;

    if (host.contains('redirectly.app')) {
      // Production URL: username.redirectly.app/slug
      final hostParts = host.split('.');
      if (hostParts.length < 3) {
        throw RedirectlyError.linkError('Invalid URL format: $originalUrl');
      }
      username = hostParts[0];

      if (pathSegments.isEmpty) {
        throw RedirectlyError.linkError('No slug found in URL: $originalUrl');
      }
      slug = pathSegments[0];
    } else if (host.contains('localhost') &&
        uri.queryParameters.containsKey('user')) {
      // Development URL: localhost:3000?user=username/slug
      final userParam = uri.queryParameters['user']!;
      final parts = userParam.split('/');
      if (parts.length != 2) {
        throw RedirectlyError.linkError(
            'Invalid development URL format: $originalUrl');
      }
      username = parts[0];
      slug = parts[1];
    } else {
      throw RedirectlyError.linkError('Unrecognized URL format: $originalUrl');
    }

    if (_config!.enableDebugLogging) {
      print('Processing Redirectly link: username=$username, slug=$slug');
    }

    // Create link click with basic info
    final linkClick = RedirectlyLinkClick(
      originalUrl: originalUrl,
      slug: slug,
      username: username,
      receivedAt: DateTime.now(),
    );

    // Try to fetch link details from backend
    try {
      final linkDetails = await _fetchLinkDetails(username, slug);
      return linkClick.copyWith(linkDetails: linkDetails);
    } catch (e) {
      // Return link click with error but still include basic info
      return linkClick.copyWith(
        error:
            e is RedirectlyError ? e : RedirectlyError.linkError(e.toString()),
      );
    }
  }

  /// Fetch link details from backend
  Future<RedirectlyLinkDetails> _fetchLinkDetails(
      String username, String slug) async {
    // For now, we'll simulate the link resolution since the backend
    // redirects directly. In a real implementation, you might want to
    // add an API endpoint that returns link details without redirecting.

    // This is a placeholder - you may want to add a dedicated API endpoint
    // like GET /api/v1/resolve/{username}/{slug} that returns link details
    throw RedirectlyError.linkError(
        'Link resolution not implemented - backend redirects directly');
  }

  /// Create a permanent link
  Future<RedirectlyLink> createLink({
    required String slug,
    required String target,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.post(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/links'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
        body: jsonEncode({
          'slug': slug,
          'target': target,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RedirectlyLink.fromJson(json);
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message: error['error'] as String? ?? 'Failed to create link',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Create a temporary link
  Future<RedirectlyTempLink> createTempLink({
    required String target,
    String? slug,
    int ttlSeconds = 900,
  }) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.post(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/temp-links'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
        body: jsonEncode({
          'target': target,
          if (slug != null) 'slug': slug,
          'ttlSeconds': ttlSeconds,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RedirectlyTempLink.fromJson(json);
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message:
              error['error'] as String? ?? 'Failed to create temporary link',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Stream of incoming link clicks
  Stream<RedirectlyLinkClick> get onLinkClick => _linkClickController.stream;

  /// Get the initial link if app was opened via a link
  Future<RedirectlyLinkClick?> getInitialLink() async {
    _ensureInitialized();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        return await _processRedirectlyLink(initialUri);
      }
      return null;
    } catch (e) {
      return RedirectlyLinkClick(
        originalUrl: 'unknown',
        slug: 'unknown',
        username: 'unknown',
        error: RedirectlyError.linkError('Failed to get initial link: $e'),
        receivedAt: DateTime.now(),
      );
    }
  }

  /// Ensure the plugin is initialized
  void _ensureInitialized() {
    if (!_initialized || _config == null) {
      throw RedirectlyError.configError(
        'FlutterRedirectly not initialized. Call initialize() first.',
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    await _linkClickController.close();
    _httpClient.close();
    _initialized = false;
    _config = null;
  }
}

/// Extension to add copyWith method to RedirectlyLinkClick
extension RedirectlyLinkClickCopyWith on RedirectlyLinkClick {
  RedirectlyLinkClick copyWith({
    String? originalUrl,
    String? slug,
    String? username,
    RedirectlyLinkDetails? linkDetails,
    RedirectlyError? error,
    DateTime? receivedAt,
  }) {
    return RedirectlyLinkClick(
      originalUrl: originalUrl ?? this.originalUrl,
      slug: slug ?? this.slug,
      username: username ?? this.username,
      linkDetails: linkDetails ?? this.linkDetails,
      error: error ?? this.error,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}
