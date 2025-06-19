import 'package:flutter_redirectly/flutter_redirectly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterRedirectly', () {
    late FlutterRedirectly plugin;

    setUp(() {
      plugin = FlutterRedirectly();
    });

    group('Configuration', () {
      test('RedirectlyConfig creates correctly with required parameters', () {
        const config = RedirectlyConfig(
          apiKey: 'test-api-key',
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(config.effectiveBaseUrl, equals('https://redirectly.app'));
        expect(config.enableDebugLogging, isFalse);
      });

      test('RedirectlyConfig accepts optional parameters', () {
        const config = RedirectlyConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://custom.redirectly.app',
          enableDebugLogging: true,
        );

        expect(config.apiKey, equals('test-api-key'));
        expect(
            config.effectiveBaseUrl, equals('https://custom.redirectly.app'));
        expect(config.enableDebugLogging, isTrue);
      });
    });

    group('Models', () {
      test('RedirectlyLink.fromJson parses correctly', () {
        final json = {
          'slug': 'test-slug',
          'target': 'https://example.com',
          'url': 'https://user.redirectly.app/test-slug',
          'click_count': 42,
          'created_at': '2024-01-15T10:00:00Z',
          'updated_at': '2024-01-15T11:00:00Z',
        };

        final link = RedirectlyLink.fromJson(json);

        expect(link.slug, equals('test-slug'));
        expect(link.target, equals('https://example.com'));
        expect(link.url, equals('https://user.redirectly.app/test-slug'));
        expect(link.clickCount, equals(42));
        expect(link.createdAt, equals(DateTime.parse('2024-01-15T10:00:00Z')));
        expect(link.updatedAt, equals(DateTime.parse('2024-01-15T11:00:00Z')));
      });

      test('RedirectlyTempLink.fromJson parses correctly', () {
        final json = {
          'slug': 'temp-slug',
          'target': 'https://example.com/temp',
          'url': 'https://user.redirectly.app/temp-slug',
          'expires_at': '2024-01-15T12:00:00Z',
          'created_at': '2024-01-15T10:00:00Z',
          'ttl_seconds': 900,
        };

        final tempLink = RedirectlyTempLink.fromJson(json);

        expect(tempLink.slug, equals('temp-slug'));
        expect(tempLink.target, equals('https://example.com/temp'));
        expect(tempLink.url, equals('https://user.redirectly.app/temp-slug'));
        expect(
            tempLink.expiresAt, equals(DateTime.parse('2024-01-15T12:00:00Z')));
        expect(
            tempLink.createdAt, equals(DateTime.parse('2024-01-15T10:00:00Z')));
        expect(tempLink.ttlSeconds, equals(900));
      });

      test('RedirectlyTempLink.isExpired works correctly', () {
        // Create a link that expires in the future
        final futureDate = DateTime.now().add(const Duration(hours: 1));
        final futureTempLink = RedirectlyTempLink(
          slug: 'future-slug',
          target: 'https://example.com',
          url: 'https://user.redirectly.app/future-slug',
          expiresAt: futureDate,
          createdAt: DateTime.now(),
        );

        expect(futureTempLink.isExpired, isFalse);

        // Create a link that expired in the past
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));
        final pastTempLink = RedirectlyTempLink(
          slug: 'past-slug',
          target: 'https://example.com',
          url: 'https://user.redirectly.app/past-slug',
          expiresAt: pastDate,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        expect(pastTempLink.isExpired, isTrue);
      });

      test('RedirectlyError creates correctly', () {
        final error = RedirectlyError.apiError(
          message: 'Test error',
          statusCode: 404,
          details: {'key': 'value'},
        );

        expect(error.message, equals('Test error'));
        expect(error.statusCode, equals(404));
        expect(error.type, equals(RedirectlyErrorType.api));
        expect(error.details, equals({'key': 'value'}));
      });

      test('RedirectlyLinkClick identifies success correctly', () {
        final successfulClick = RedirectlyLinkClick(
          originalUrl: 'https://user.redirectly.app/test',
          slug: 'test',
          username: 'user',
          linkDetails: const RedirectlyLinkDetails(
            target: 'https://example.com',
            isPermanent: true,
          ),
          receivedAt: DateTime.now(),
        );

        expect(successfulClick.isSuccessful, isTrue);

        final failedClick = RedirectlyLinkClick(
          originalUrl: 'https://user.redirectly.app/test',
          slug: 'test',
          username: 'user',
          error: RedirectlyError.linkError('Test error'),
          receivedAt: DateTime.now(),
        );

        expect(failedClick.isSuccessful, isFalse);
      });
    });

    group('Error Types', () {
      test('RedirectlyError factory methods create correct types', () {
        final apiError = RedirectlyError.apiError(
          message: 'API error',
          statusCode: 400,
        );
        expect(apiError.type, equals(RedirectlyErrorType.api));

        final networkError = RedirectlyError.networkError('Network error');
        expect(networkError.type, equals(RedirectlyErrorType.network));

        final configError = RedirectlyError.configError('Config error');
        expect(configError.type, equals(RedirectlyErrorType.configuration));

        final linkError = RedirectlyError.linkError('Link error');
        expect(linkError.type, equals(RedirectlyErrorType.linkResolution));
      });
    });
  });
}
