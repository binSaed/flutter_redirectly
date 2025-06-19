import 'redirectly_error.dart';

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

  const RedirectlyLinkClick({
    required this.originalUrl,
    required this.slug,
    required this.username,
    required this.receivedAt,
    this.error,
  });

  @override
  String toString() {
    return 'RedirectlyLinkClick(originalUrl: $originalUrl, slug: $slug, username: $username, receivedAt: $receivedAt, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectlyLinkClick &&
        other.originalUrl == originalUrl &&
        other.slug == slug &&
        other.username == username &&
        other.receivedAt == receivedAt &&
        other.error == error;
  }

  @override
  int get hashCode {
    return originalUrl.hashCode ^
        slug.hashCode ^
        username.hashCode ^
        receivedAt.hashCode ^
        error.hashCode;
  }
}
