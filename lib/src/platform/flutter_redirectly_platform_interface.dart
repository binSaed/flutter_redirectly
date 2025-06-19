import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/models.dart';
import 'flutter_redirectly_method_channel.dart';

/// The interface that platform implementations must implement.
///
/// Platform implementations should extend this class rather than implement it,
/// as [FlutterRedirectlyPlatform] is not implemented by the plugin_platform_interface.
abstract class FlutterRedirectlyPlatform extends PlatformInterface {
  /// Constructs a FlutterRedirectlyPlatform.
  FlutterRedirectlyPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterRedirectlyPlatform _instance = MethodChannelFlutterRedirectly();

  /// The default instance of [FlutterRedirectlyPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterRedirectly].
  static FlutterRedirectlyPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterRedirectlyPlatform] when
  /// they register themselves.
  static set instance(FlutterRedirectlyPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the plugin with configuration
  Future<void> initialize(RedirectlyConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Create a permanent link
  Future<RedirectlyLink> createLink({
    required String slug,
    required String target,
    Map<String, dynamic>? metadata,
  }) {
    throw UnimplementedError('createLink() has not been implemented.');
  }

  /// Create a temporary link
  Future<RedirectlyTempLink> createTempLink({
    required String target,
    String? slug,
    int ttlSeconds = 900,
  }) {
    throw UnimplementedError('createTempLink() has not been implemented.');
  }

  /// Get all permanent links
  Future<List<RedirectlyLink>> getLinks() {
    throw UnimplementedError('getLinks() has not been implemented.');
  }

  /// Update a link's target URL
  Future<RedirectlyLink> updateLink({
    required String slug,
    required String target,
  }) {
    throw UnimplementedError('updateLink() has not been implemented.');
  }

  /// Delete a link
  Future<void> deleteLink(String slug) {
    throw UnimplementedError('deleteLink() has not been implemented.');
  }

  /// Get the current app link stream
  Stream<RedirectlyLinkClick> getLinkClickStream() {
    throw UnimplementedError('getLinkClickStream() has not been implemented.');
  }

  /// Get the initial link if app was opened via a link
  Future<RedirectlyLinkClick?> getInitialLink() {
    throw UnimplementedError('getInitialLink() has not been implemented.');
  }
}
