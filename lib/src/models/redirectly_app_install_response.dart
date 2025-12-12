/// App install response model for Redirectly
class RedirectlyAppInstallResponse {
  /// Whether the install was matched to a deferred click
  final bool matched;

  /// Install type - 'organic' or 'non-organic'
  final String type;

  /// Username if matched
  final String? username;

  /// Slug if matched
  final String? slug;

  /// Link details if matched and available
  final RedirectlyAppInstallLink? link;

  /// Metadata
  final Map<String, dynamic>? customParameters;

  const RedirectlyAppInstallResponse({
    required this.matched,
    required this.type,
    this.username,
    this.slug,
    this.link,
    this.customParameters,
  });

  /// Create from JSON response
  factory RedirectlyAppInstallResponse.fromJson(Map<String, dynamic> json) {
    return RedirectlyAppInstallResponse(
      matched: json['matched'] as bool,
      type: json['type'] as String,
      username: json['username'] as String?,
      slug: json['slug'] as String?,
      customParameters: json['custom_params'] as Map<String, dynamic>?,
      link: json['link'] != null
          ? RedirectlyAppInstallLink.fromJson(
              json['link'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'matched': matched,
      'type': type,
      if (username != null) 'username': username,
      if (slug != null) 'slug': slug,
      if (link != null) 'link': link!.toJson(),
    };
  }

  @override
  String toString() {
    return 'RedirectlyAppInstallResponse{matched: $matched, type: $type, username: $username, slug: $slug, link: $link}';
  }
}

/// Link details in app install response
class RedirectlyAppInstallLink {
  /// Link slug
  final String slug;

  /// Target URL
  final String? target;

  /// Full clickable URL
  final String url;

  /// Creation timestamp
  final DateTime createdAt;

  /// Link metadata
  final Map<String, dynamic>? metadata;

  const RedirectlyAppInstallLink({
    required this.slug,
    required this.target,
    required this.url,
    required this.createdAt,
    this.metadata,
  });

  /// Create from JSON
  factory RedirectlyAppInstallLink.fromJson(Map<String, dynamic> json) {
    return RedirectlyAppInstallLink(
      slug: json['slug'] as String,
      target: json['target'] as String?,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'target': target,
      'url': url,
      'created_at': createdAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'RedirectlyAppInstallLink{slug: $slug, target: $target, url: $url, createdAt: $createdAt, metadata: $metadata }';
  }
}
