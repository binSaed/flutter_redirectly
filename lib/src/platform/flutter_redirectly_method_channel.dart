import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import 'flutter_redirectly_platform_interface.dart';

/// An implementation of [FlutterRedirectlyPlatform] that uses the Flutter Method Channel.
class MethodChannelFlutterRedirectly extends FlutterRedirectlyPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_redirectly');

  @override
  Future<void> initialize(RedirectlyConfig config) async {
    await methodChannel.invokeMethod<void>('initialize', {
      'apiKey': config.apiKey,
      'baseUrl': config.effectiveBaseUrl,
      'enableDebugLogging': config.enableDebugLogging,
    });
  }

  @override
  Future<RedirectlyLink> createLink({
    required String slug,
    required String target,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'createLink',
      {
        'slug': slug,
        'target': target,
        if (metadata != null) 'metadata': metadata,
      },
    );

    if (result == null) {
      throw RedirectlyError.apiError(
        message: 'Failed to create link',
        statusCode: 500,
      );
    }

    return RedirectlyLink.fromJson(Map<String, dynamic>.from(result));
  }

  @override
  Future<RedirectlyTempLink> createTempLink({
    required String target,
    String? slug,
    int ttlSeconds = 900,
  }) async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'createTempLink',
      {
        'target': target,
        if (slug != null) 'slug': slug,
        'ttlSeconds': ttlSeconds,
      },
    );

    if (result == null) {
      throw RedirectlyError.apiError(
        message: 'Failed to create temporary link',
        statusCode: 500,
      );
    }

    return RedirectlyTempLink.fromJson(Map<String, dynamic>.from(result));
  }

  @override
  Future<List<RedirectlyLink>> getLinks() async {
    final result = await methodChannel.invokeMethod<List<Object?>>(
      'getLinks',
    );

    if (result == null) {
      throw RedirectlyError.apiError(
        message: 'Failed to fetch links',
        statusCode: 500,
      );
    }

    return result
        .cast<Map<Object?, Object?>>()
        .map((json) => RedirectlyLink.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<RedirectlyLink> updateLink({
    required String slug,
    required String target,
  }) async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'updateLink',
      {
        'slug': slug,
        'target': target,
      },
    );

    if (result == null) {
      throw RedirectlyError.apiError(
        message: 'Failed to update link',
        statusCode: 500,
      );
    }

    return RedirectlyLink.fromJson(Map<String, dynamic>.from(result));
  }

  @override
  Future<void> deleteLink(String slug) async {
    await methodChannel.invokeMethod<void>('deleteLink', {
      'slug': slug,
    });
  }

  @override
  Stream<RedirectlyLinkClick> getLinkClickStream() {
    return const EventChannel('flutter_redirectly/link_clicks')
        .receiveBroadcastStream()
        .map((data) {
      final map = Map<String, dynamic>.from(data as Map);
      return RedirectlyLinkClick(
        originalUrl: map['originalUrl'] as String,
        slug: map['slug'] as String,
        username: map['username'] as String,
        linkDetails: map['linkDetails'] != null
            ? RedirectlyLinkDetails.fromJson(
                Map<String, dynamic>.from(map['linkDetails'] as Map),
              )
            : null,
        error: map['error'] != null
            ? RedirectlyError(
                message: map['error']['message'] as String,
                type: RedirectlyErrorType.values[map['error']['type'] as int],
                statusCode: map['error']['statusCode'] as int?,
              )
            : null,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          map['receivedAt'] as int,
        ),
      );
    });
  }

  @override
  Future<RedirectlyLinkClick?> getInitialLink() async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'getInitialLink',
    );

    if (result == null) return null;

    final map = Map<String, dynamic>.from(result);
    return RedirectlyLinkClick(
      originalUrl: map['originalUrl'] as String,
      slug: map['slug'] as String,
      username: map['username'] as String,
      linkDetails: map['linkDetails'] != null
          ? RedirectlyLinkDetails.fromJson(
              Map<String, dynamic>.from(map['linkDetails'] as Map),
            )
          : null,
      error: map['error'] != null
          ? RedirectlyError(
              message: map['error']['message'] as String,
              type: RedirectlyErrorType.values[map['error']['type'] as int],
              statusCode: map['error']['statusCode'] as int?,
            )
          : null,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        map['receivedAt'] as int,
      ),
    );
  }
}
