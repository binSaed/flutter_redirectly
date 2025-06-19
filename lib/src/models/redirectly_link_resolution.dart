import 'redirectly_link.dart';
import 'redirectly_temp_link.dart';

/// Represents the resolution of a Redirectly link (permanent or temporary)
class RedirectlyLinkResolution {
  /// Unique identifier
  final String id;

  /// Link slug
  final String slug;

  /// Target URL that the link redirects to
  final String target;

  /// Full clickable URL
  final String url;

  /// Type of link: 'permanent' or 'temporary'
  final String type;

  /// Whether the link is expired (always false for permanent links)
  final bool isExpired;

  /// When the link was created
  final DateTime createdAt;

  /// Click count (only available for permanent links)
  final int? clickCount;

  /// Expiration date (only for temporary links)
  final DateTime? expiresAt;

  /// TTL in seconds (only for temporary links)
  final int? ttlSeconds;

  /// Link metadata (only for permanent links)
  final Map<String, dynamic>? metadata;

  const RedirectlyLinkResolution({
    required this.id,
    required this.slug,
    required this.target,
    required this.url,
    required this.type,
    required this.isExpired,
    required this.createdAt,
    this.clickCount,
    this.expiresAt,
    this.ttlSeconds,
    this.metadata,
  });

  /// Create from JSON response
  factory RedirectlyLinkResolution.fromJson(Map<String, dynamic> json) {
    return RedirectlyLinkResolution(
      id: json['id'] as String,
      slug: json['slug'] as String,
      target: json['target'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      isExpired: json['is_expired'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      clickCount: json['click_count'] as int?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      ttlSeconds: json['ttl_seconds'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Whether this is a permanent link
  bool get isPermanent => type == 'permanent';

  /// Whether this is a temporary link
  bool get isTemporary => type == 'temporary';

  /// Get remaining time until expiration (for temporary links)
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;

    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) {
      return Duration.zero;
    }
    return expiresAt!.difference(now);
  }

  /// Convert to RedirectlyLink (for permanent links)
  RedirectlyLink? toRedirectlyLink() {
    if (!isPermanent) return null;

    return RedirectlyLink(
      slug: slug,
      target: target,
      url: url,
      clickCount: clickCount ?? 0,
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  /// Convert to RedirectlyTempLink (for temporary links)
  RedirectlyTempLink? toRedirectlyTempLink() {
    if (!isTemporary || expiresAt == null) return null;

    return RedirectlyTempLink(
      slug: slug,
      target: target,
      url: url,
      expiresAt: expiresAt!,
      createdAt: createdAt,
      ttlSeconds: ttlSeconds,
    );
  }

  @override
  String toString() {
    return 'RedirectlyLinkResolution(slug: $slug, type: $type, target: $target, expired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectlyLinkResolution &&
        other.id == id &&
        other.slug == slug &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ slug.hashCode ^ type.hashCode;
}
