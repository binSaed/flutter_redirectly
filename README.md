# Flutter Redirectly

A Flutter package for creating and handling dynamic links using your own Redirectly backend. Pure Dart implementation - no native code required!

## Installation

```yaml
dependencies:
  flutter_redirectly: ^2.0.0
```

## Quick Setup

### 1. Get Your API Key

Get your free API key from [redirectly.app](https://redirectly.app) - sign up and create your subdomain to get started.

### 2. Configure Deep Links

**Android** - Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="YOUR_SUBDOMAIN.redirectly.app" />
</intent-filter>
```

**iOS** - Add Associated Domains to `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:YOUR_SUBDOMAIN.redirectly.app</string>
    </array>
</dict>
</plist>
```

If this file doesn't exist, create it. Also ensure your app is properly signed and the Associated Domains capability is enabled in your Apple Developer account.

### 3. Initialize

```dart
import 'package:flutter_redirectly/flutter_redirectly.dart';

final redirectly = FlutterRedirectly();

await redirectly.initialize(RedirectlyConfig(
  apiKey: 'your-api-key-here',
  debug: true,
));
```

### 4. Handle Links

```dart
// Listen for incoming links
redirectly.onLinkClick.listen((linkClick) {
  print('Link: ${linkClick.originalUrl}');
  print('Slug: ${linkClick.slug}');
  
});

// Handle app launch from link
final initialLink = await redirectly.getInitialLink();
if (initialLink != null) {
  // Handle same as above
}
```

### 5. Create Links

```dart
// Create a permanent link
final link = await redirectly.createLink(
  slug: 'my-link',
  target: 'https://example.com',
);
print('Created: ${link.url}');

// Create a temporary link (expires in 1 hour)
final tempLink = await redirectly.createTempLink(
  target: 'https://example.com',
  ttlSeconds: 3600,
);
print('Temp link: ${tempLink.url}');
```

## Error Handling

```dart
try {
  final link = await redirectly.createLink(slug: 'test', target: 'https://example.com');
} on RedirectlyError catch (e) {
  print('Error: ${e.message}');
}
```

## API Reference

### Configuration

```dart
RedirectlyConfig({
  required String apiKey,     // Your API key
  String? baseUrl,           // Optional: custom domain
  bool enableDebugLogging,   // Optional: debug mode
})
```

### Models

```dart
// Permanent link
RedirectlyLink({
  String id, slug, target, url,
  int clickCount,
  DateTime createdAt,
  Map<String, dynamic>? metadata,
})

// Temporary link  
RedirectlyTempLink({
  String id, slug, target, url,
  int ttlSeconds,
  DateTime expiresAt, createdAt,
})

// Link click event
RedirectlyLinkClick({
  String originalUrl, slug, username,
  DateTime receivedAt,
  RedirectlyError? error,
})
```

## Example

See the [example app](./example) for a complete implementation.

## Support

- 🐛 Issues: [GitHub Issues](https://github.com/redirectly-app/flutter_redirectly/issues)
- 📚 Docs: [redirectly.app/docs](https://redirectly.app/docs)

## License

MIT License - see [LICENSE](LICENSE) file.
