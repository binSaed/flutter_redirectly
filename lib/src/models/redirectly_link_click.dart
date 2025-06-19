import 'redirectly_error.dart';
import 'redirectly_link_resolution.dart';

/// Represents a click on a Redirectly link
class RedirectlyLinkClick {
  /// The original URL that was clicked
  final String originalUrl;

  /// The slug from the URL
  final String slug;

  /// The username from the URL
  final String username;

  /// When the link was received
  final DateTime receivedAt;

  /// Error that occurred while processing the link (if any)
  final RedirectlyError? error;

  /// Resolved link details (if resolution was successful)
  final RedirectlyLinkResolution? linkResolution;

  const RedirectlyLinkClick({
    required this.originalUrl,
    required this.slug,
    required this.username,
    required this.receivedAt,
    this.error,
    this.linkResolution,
  });

  /// Whether link resolution was successful
  bool get isResolved => linkResolution != null && error == null;

  /// Get the target URL if resolution was successful
  String? get targetUrl => linkResolution?.target;

  /// Get the link type if resolution was successful
  String? get linkType => linkResolution?.type;

  @override
  String toString() {
    return 'RedirectlyLinkClick(originalUrl: $originalUrl, slug: $slug, username: $username, resolved: $isResolved, receivedAt: $receivedAt, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectlyLinkClick &&
        other.originalUrl == originalUrl &&
        other.slug == slug &&
        other.username == username &&
        other.receivedAt == receivedAt &&
        other.error == error &&
        other.linkResolution == linkResolution;
  }

  @override
  int get hashCode {
    return originalUrl.hashCode ^
        slug.hashCode ^
        username.hashCode ^
        receivedAt.hashCode ^
        error.hashCode ^
        linkResolution.hashCode;
  }
}
