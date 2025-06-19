/// Represents a permanent Redirectly link
class RedirectlyLink {
  /// Unique slug identifier for the link
  final String slug;

  /// Target URL that the link redirects to
  final String target;

  /// Full clickable URL (e.g., https://username.redirectly.app/slug)
  final String url;

  /// Number of times this link has been clicked
  final int clickCount;

  /// When the link was created
  final DateTime createdAt;

  /// When the link was last updated
  final DateTime? updatedAt;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const RedirectlyLink({
    required this.slug,
    required this.target,
    required this.url,
    required this.clickCount,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Create from JSON response
  factory RedirectlyLink.fromJson(Map<String, dynamic> json) {
    return RedirectlyLink(
      slug: json['slug'] as String,
      target: json['target'] as String,
      url: json['url'] as String,
      clickCount: (json['click_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'target': target,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  RedirectlyLink copyWith({
    String? slug,
    String? target,
    String? url,
    int? clickCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RedirectlyLink(
      slug: slug ?? this.slug,
      target: target ?? this.target,
      url: url ?? this.url,
      clickCount: clickCount ?? this.clickCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'RedirectlyLink(slug: $slug, target: $target, url: $url, clicks: $clickCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectlyLink &&
        other.slug == slug &&
        other.target == target &&
        other.url == url;
  }

  @override
  int get hashCode => slug.hashCode ^ target.hashCode ^ url.hashCode;
}
