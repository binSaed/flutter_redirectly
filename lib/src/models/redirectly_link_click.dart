import 'redirectly_error.dart';

/// Represents data received when a Redirectly link is clicked and opened in the app
class RedirectlyLinkClick {
  /// The original clicked URL
  final String originalUrl;

  /// The slug extracted from the URL
  final String slug;

  /// The username extracted from the subdomain
  final String username;

  /// Full link details fetched from backend (null if fetch failed)
  final RedirectlyLinkDetails? linkDetails;

  /// Any error that occurred while processing the link
  final RedirectlyError? error;

  /// When the click was received by the app
  final DateTime receivedAt;

  const RedirectlyLinkClick({
    required this.originalUrl,
    required this.slug,
    required this.username,
    this.linkDetails,
    this.error,
    required this.receivedAt,
  });

  /// Whether link processing was successful
  bool get isSuccessful => error == null && linkDetails != null;

  @override
  String toString() {
    return 'RedirectlyLinkClick(url: $originalUrl, slug: $slug, user: $username, success: $isSuccessful)';
  }
}

/// Detailed information about a clicked link fetched from the backend
class RedirectlyLinkDetails {
  /// Target URL that the link redirects to
  final String target;

  /// Link metadata from backend
  final Map<String, dynamic>? metadata;

  /// Whether this was a permanent or temporary link
  final bool isPermanent;

  /// Expiration date for temporary links
  final DateTime? expiresAt;

  const RedirectlyLinkDetails({
    required this.target,
    this.metadata,
    required this.isPermanent,
    this.expiresAt,
  });

  /// Create from backend API response
  factory RedirectlyLinkDetails.fromJson(Map<String, dynamic> json) {
    return RedirectlyLinkDetails(
      target: json['target'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isPermanent: json['is_permanent'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'RedirectlyLinkDetails(target: $target, permanent: $isPermanent)';
  }
}
