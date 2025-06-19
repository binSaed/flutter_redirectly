/// Represents a temporary Redirectly link with expiration
class RedirectlyTempLink {
  /// Unique slug identifier for the temporary link
  final String slug;

  /// Target URL that the link redirects to
  final String target;

  /// Full clickable URL (e.g., https://username.redirectly.app/slug)
  final String url;

  /// When the link expires
  final DateTime expiresAt;

  /// When the link was created
  final DateTime createdAt;

  /// TTL in seconds from creation
  final int? ttlSeconds;

  const RedirectlyTempLink({
    required this.slug,
    required this.target,
    required this.url,
    required this.expiresAt,
    required this.createdAt,
    this.ttlSeconds,
  });

  /// Create from JSON response
  factory RedirectlyTempLink.fromJson(Map<String, dynamic> json) {
    return RedirectlyTempLink(
      slug: json['slug'] as String,
      target: json['target'] as String,
      url: json['url'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      ttlSeconds: json['ttl_seconds'] as int?,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'target': target,
      if (ttlSeconds != null) 'ttlSeconds': ttlSeconds,
    };
  }

  /// Check if the link is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get remaining time until expiration
  Duration get timeUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  /// Create a copy with updated fields
  RedirectlyTempLink copyWith({
    String? slug,
    String? target,
    String? url,
    DateTime? expiresAt,
    DateTime? createdAt,
    int? ttlSeconds,
  }) {
    return RedirectlyTempLink(
      slug: slug ?? this.slug,
      target: target ?? this.target,
      url: url ?? this.url,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
    );
  }

  @override
  String toString() {
    return 'RedirectlyTempLink(slug: $slug, target: $target, url: $url, expires: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectlyTempLink &&
        other.slug == slug &&
        other.target == target &&
        other.url == url;
  }

  @override
  int get hashCode => slug.hashCode ^ target.hashCode ^ url.hashCode;
}
