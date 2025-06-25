import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'models/models.dart';

/// Pure Dart Flutter Redirectly plugin
///
/// This class provides functionality similar to Firebase Dynamic Links
/// but uses your own Redirectly backend. No native code required!
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

  /// Cached plugin version
  String? _pluginVersion;

  /// Initialize the plugin with configuration
  Future<void> initialize(RedirectlyConfig config) async {
    if (_initialized) {
      throw RedirectlyError.configError(
          'FlutterRedirectly is already initialized');
    }

    _config = config;

    try {
      // Set up app links listening
      await _setupAppLinks();

      _initialized = true;

      if (config.enableDebugLogging) {
        final version = await _getPluginVersion();
        print(
            'FlutterRedirectly v$version initialized successfully (Pure Dart - no native code!)');
      }
    } catch (e) {
      throw RedirectlyError.configError('Failed to initialize: $e');
    }
  }

  /// Get the plugin version from pubspec.yaml
  Future<String> _getPluginVersion() async {
    if (_pluginVersion != null) return _pluginVersion!;

    try {
      // Try to read the pubspec.yaml from the plugin package
      final pubspecString = await rootBundle
          .loadString('packages/flutter_redirectly/pubspec.yaml');
      final lines = pubspecString.split('\n');

      for (String line in lines) {
        if (line.trim().startsWith('version:')) {
          _pluginVersion = line.split(':')[1].trim();
          return _pluginVersion!;
        }
      }
    } catch (e) {
      // Fallback: try to read from the current package's pubspec.yaml
      try {
        final pubspecString = await rootBundle.loadString('pubspec.yaml');
        final lines = pubspecString.split('\n');

        // Check if this is the flutter_redirectly package itself
        bool isRedirectlyPackage = false;
        for (String line in lines) {
          if (line.trim().startsWith('name:') &&
              line.contains('flutter_redirectly')) {
            isRedirectlyPackage = true;
            break;
          }
        }

        if (isRedirectlyPackage) {
          for (String line in lines) {
            if (line.trim().startsWith('version:')) {
              _pluginVersion = line.split(':')[1].trim();
              return _pluginVersion!;
            }
          }
        }
      } catch (e2) {
        // Ignore and use fallback
      }
    }

    // Fallback version if we can't read from pubspec.yaml
    _pluginVersion = '2.0.1';
    return _pluginVersion!;
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

  /// Process a Redirectly link using pure Dart URL parsing
  Future<RedirectlyLinkClick> _processRedirectlyLink(Uri uri) async {
    final originalUrl = uri.toString();

    // Parse username and slug using pure Dart
    final parseResult = _parseRedirectlyUrl(uri);
    if (parseResult == null) {
      return RedirectlyLinkClick(
        originalUrl: originalUrl,
        slug: 'unknown',
        username: 'unknown',
        error: RedirectlyError.linkError('Invalid Redirectly URL format'),
        receivedAt: DateTime.now(),
      );
    }

    final username = parseResult['username']!;
    final slug = parseResult['slug']!;

    if (_config!.enableDebugLogging) {
      print('Processing Redirectly link: username=$username, slug=$slug');
    }

    // Try to resolve link details from backend
    RedirectlyLinkResolution? linkResolution;
    try {
      linkResolution = await resolveLink(username, slug);

      if (_config!.enableDebugLogging) {
        print(
            'Link resolved: ${linkResolution.type} link targeting ${linkResolution.target}');
      }

      // Log the click in background (fire-and-forget)
      _logMobileClick(username, slug, uri).catchError((error) {
        if (_config!.enableDebugLogging) {
          print('Failed to log mobile click: $error');
        }
      });
    } catch (e) {
      if (_config!.enableDebugLogging) {
        print('Failed to resolve link details: $e');
      }
      // Continue without link details - not a fatal error
    }

    return RedirectlyLinkClick(
      originalUrl: originalUrl,
      slug: slug,
      username: username,
      linkResolution: linkResolution,
      receivedAt: DateTime.now(),
    );
  }

  /// Parse Redirectly URL using pure Dart
  Map<String, String>? _parseRedirectlyUrl(Uri uri) {
    final host = uri.host;
    final pathSegments = uri.pathSegments;

    if (host.contains('redirectly.app')) {
      // Production URL: username.redirectly.app/slug
      final hostParts = host.split('.');
      if (hostParts.length < 3 || pathSegments.isEmpty) {
        return null;
      }
      return {
        'username': hostParts[0],
        'slug': pathSegments[0],
      };
    } else if (host.contains('localhost') &&
        uri.queryParameters.containsKey('user')) {
      // Development URL: localhost:3000?user=username/slug
      final userParam = uri.queryParameters['user']!;
      final parts = userParam.split('/');
      if (parts.length != 2) {
        return null;
      }
      return {
        'username': parts[0],
        'slug': parts[1],
      };
    }

    return null;
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

  /// Get all permanent links
  Future<List<RedirectlyLink>> getLinks() async {
    _ensureInitialized();

    try {
      final response = await _httpClient.get(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/links'),
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .cast<Map<String, dynamic>>()
            .map((json) => RedirectlyLink.fromJson(json))
            .toList();
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message: error['error'] as String? ?? 'Failed to fetch links',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Get a specific permanent link by slug
  Future<RedirectlyLink> getLink(String slug) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.get(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/links/$slug'),
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RedirectlyLink.fromJson(json);
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message: error['error'] as String? ?? 'Failed to fetch link',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Get a specific temporary link by slug
  Future<RedirectlyTempLink> getTempLink(String slug) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.get(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/temp-links/$slug'),
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RedirectlyTempLink.fromJson(json);
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message:
              error['error'] as String? ?? 'Failed to fetch temporary link',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Resolve a link by username and slug (public endpoint)
  Future<RedirectlyLinkResolution> resolveLink(
      String username, String slug) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.get(
        Uri.parse(
            '${_config!.effectiveBaseUrl}/api/v1/resolve/$username/$slug'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RedirectlyLinkResolution.fromJson(json);
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message: error['error'] as String? ?? 'Failed to resolve link',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Update a permanent link
  Future<RedirectlyLink> updateLink(
    String slug, {
    required String target,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.put(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/links/$slug'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
        body: jsonEncode({
          'target': target,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RedirectlyLink.fromJson(json);
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message: error['error'] as String? ?? 'Failed to update link',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Delete a permanent link
  Future<void> deleteLink(String slug) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.delete(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/links/$slug'),
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message: error['error'] as String? ?? 'Failed to delete link',
          statusCode: response.statusCode,
          details: error,
        );
      }
    } catch (e) {
      if (e is RedirectlyError) rethrow;
      throw RedirectlyError.networkError('Network error: $e');
    }
  }

  /// Delete a temporary link
  Future<void> deleteTempLink(String slug) async {
    _ensureInitialized();

    try {
      final response = await _httpClient.delete(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/temp-links/$slug'),
        headers: {
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw RedirectlyError.apiError(
          message:
              error['error'] as String? ?? 'Failed to delete temporary link',
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

  /// Log mobile app click to backend (fire-and-forget)
  Future<void> _logMobileClick(
      String username, String slug, Uri originalUri) async {
    if (_config == null) return;

    try {
      // Extract UTM parameters from original URI
      final utmParams = <String, String>{};
      originalUri.queryParameters.forEach((key, value) {
        if (key.startsWith('utm_')) {
          utmParams[key] = value;
        }
      });

      // Get plugin version dynamically
      final pluginVersion = await _getPluginVersion();

      // Collect device information
      final clickData = <String, dynamic>{
        'slug': slug,
        'username': username,
        'device_type':
            'mobile', // Could be enhanced with actual device detection
        'is_mobile_app': true,
        'app_platform': 'flutter',
        'session_id': _generateSessionId(),
        'timezone': DateTime.now().timeZoneOffset.toString(),
        'metadata': {
          'original_url': originalUri.toString(),
          'flutter_plugin_version': pluginVersion,
          'dart_version': _getDartVersion(),
        },
      };

      // Add UTM parameters if present
      utmParams.forEach((key, value) {
        clickData[key] = value;
      });

      // Enhanced device info could be added here
      // You might want to use packages like:
      // - device_info_plus for device details
      // - package_info_plus for app version
      // - connectivity_plus for network info

      final response = await _httpClient.post(
        Uri.parse('${_config!.effectiveBaseUrl}/api/v1/clicks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
        body: jsonEncode(clickData),
      );

      if (_config!.enableDebugLogging) {
        if (response.statusCode == 200) {
          print(
              'Mobile click logged successfully: $username/$slug (plugin v$pluginVersion)');
        } else {
          print(
              'Failed to log mobile click: ${response.statusCode} ${response.body}');
        }
      }
    } catch (e) {
      if (_config!.enableDebugLogging) {
        print('Error logging mobile click: $e');
      }
      // Fail silently - don't break user experience for analytics
    }
  }

  /// Get Dart version information
  String _getDartVersion() {
    try {
      // This will return something like "3.2.0 (stable)"
      return Platform.version.split(' ').first;
    } catch (e) {
      return 'unknown';
    }
  }

  /// Generate a session ID for tracking user sessions
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return '${timestamp}_$random';
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
