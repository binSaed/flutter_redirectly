# Flutter Redirectly

🎉 **Pure Dart Implementation - No Native Code Required!**

A Flutter package that provides Firebase Dynamic Links-like functionality using your own Redirectly backend. This package allows you to create, manage, and handle dynamic links in your Flutter app - with **zero native code dependencies!**

More detailed information: [redirectly.app](https://redirectly.app?src=flutter_plugin)

## ✨ Why Pure Dart?

- **🚀 Zero Native Code**: No Android Kotlin or iOS Swift required
- **⚡ Faster Development**: Single codebase, faster builds, easier debugging
- **🔧 Simpler Setup**: No platform-specific configuration needed
- **📦 Smaller Bundle**: No native platform channels or implementations
- **🧪 Better Testing**: Pure Dart code is easier to unit test
- **🎯 Single Source of Truth**: All logic in one place

## Features

- 🔗 **Create permanent and temporary links** via API
- 📱 **Handle deep links** in all app states (cold start, background, foreground)
- 🚀 **Built on app_links** for reliable link handling
- 🔧 **Simple configuration** with just an API key
- 📊 **Real-time link click notifications** via streams
- 🛡️ **Comprehensive error handling** with typed errors
- 🌐 **Support for both Android and iOS**
- ✨ **Pure Dart**: Uses `app_links` + `http` packages only

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_redirectly: ^2.0.0
```

## Backend Setup

This plugin works with the Redirectly backend. Make sure you have:

1. A running Redirectly instance
2. A valid API key from your Redirectly dashboard
3. Your links follow the format: `https://username.redirectly.app/slug`

## Configuration

Since this is a **pure Dart package**, you only need to configure deep links using the `app_links` package (which is already included as a dependency).

### Android

Add the following to your `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- ... existing intent filters ... -->
    
    <!-- Add this intent filter for Redirectly links -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="YOUR_SUBDOMAIN.redirectly.app" />
    </intent-filter>
</activity>
```

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>redirectly.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
    </dict>
</array>
```

## Usage

### Initialize the plugin

```dart
import 'package:flutter_redirectly/flutter_redirectly.dart';

final redirectly = FlutterRedirectly();

await redirectly.initialize(RedirectlyConfig(
  apiKey: 'your-api-key-here',
  baseUrl: 'https://your-domain.com', // Optional, defaults to redirectly.app
  enableDebugLogging: true, // Optional, helpful for debugging
));
```

### Listen for incoming links

```dart
// Listen to link clicks when app is running
redirectly.onLinkClick.listen((linkClick) {
  print('Link clicked: ${linkClick.originalUrl}');
  print('Username: ${linkClick.username}');
  print('Slug: ${linkClick.slug}');
  print('Received at: ${linkClick.receivedAt}');
  
  if (linkClick.error == null) {
    // Handle successful link - use username/slug for navigation
    Navigator.of(context).pushNamed('/${linkClick.username}/${linkClick.slug}');
  } else {
    // Handle error
    print('Error: ${linkClick.error}');
  }
});

// Check for initial link (when app is opened via link)
final initialLink = await redirectly.getInitialLink();
if (initialLink != null) {
  // Handle initial link same way as above
}
```

### Create links

```dart
// Create a permanent link
final permanentLink = await redirectly.createLink(
  slug: 'my-awesome-link',
  target: 'https://example.com',
  metadata: {'campaign': 'summer2024'}, // Optional
);

print('Created link: ${permanentLink.url}');
print('Clicks: ${permanentLink.clickCount}');

// Create a temporary link (expires after 1 hour)
final tempLink = await redirectly.createTempLink(
  target: 'https://example.com/temp-content',
  slug: 'temp-link', // Optional
  ttlSeconds: 3600, // 1 hour
);

print('Temp link: ${tempLink.url}');
print('Expires at: ${tempLink.expiresAt}');
```

### Error handling

```dart
try {
  final link = await redirectly.createLink(
    slug: 'test-link',
    target: 'https://example.com',
  );
} on RedirectlyError catch (e) {
  switch (e.type) {
    case RedirectlyErrorType.api:
      print('API Error: ${e.message} (${e.statusCode})');
      break;
    case RedirectlyErrorType.network:
      print('Network Error: ${e.message}');
      break;
    case RedirectlyErrorType.configuration:
      print('Configuration Error: ${e.message}');
      break;
    case RedirectlyErrorType.linkResolution:
      print('Link Resolution Error: ${e.message}');
      break;
    default:
      print('Unknown Error: ${e.message}');
  }
}
```

## API Reference

### RedirectlyConfig

Configuration object for initializing the plugin.

```dart
RedirectlyConfig({
  required String apiKey,      // Your Redirectly API key
  String? baseUrl,            // Base URL (defaults to https://redirectly.app)
  bool enableDebugLogging,    // Enable debug logging (default: false)
})
```

### RedirectlyLink

Represents a permanent link.

```dart
RedirectlyLink({
  required String id,
  required String slug,
  required String target,
  required String url,
  required int clickCount,
  required DateTime createdAt,
  Map<String, dynamic>? metadata,
})
```

### RedirectlyTempLink

Represents a temporary link with expiration.

```dart
RedirectlyTempLink({
  required String id,
  required String slug,
  required String target,
  required String url,
  required int ttlSeconds,
  required DateTime expiresAt,
  required DateTime createdAt,
})
```

### RedirectlyLinkClick

Data received when a link is clicked.

```dart
RedirectlyLinkClick({
  required String originalUrl,
  required String slug,
  required String username,
  required DateTime receivedAt,
  RedirectlyError? error,
})
```

### RedirectlyError

Comprehensive error handling.

```dart
RedirectlyError({
  required RedirectlyErrorType type,
  required String message,
  int? statusCode,
  Map<String, dynamic>? details,
})
```

Error types:

- `RedirectlyErrorType.api` - API errors (4xx, 5xx responses)
- `RedirectlyErrorType.network` - Network connectivity issues
- `RedirectlyErrorType.configuration` - Setup/initialization errors
- `RedirectlyErrorType.linkResolution` - Link parsing/processing errors

## Architecture

This package uses a **pure Dart architecture** with no native code:

```
┌─────────────────────────────────────┐
│           Flutter App               │
├─────────────────────────────────────┤
│        flutter_redirectly           │
│         (Pure Dart)                 │
├─────────────────────────────────────┤
│   app_links    │      http          │
│  (Deep Links)  │   (API Calls)      │
├─────────────────────────────────────┤
│        Platform (Android/iOS)       │
└─────────────────────────────────────┘
```

## Migration from v1.x

If you're upgrading from v1.x, here are the key changes:

### Breaking Changes

- `RedirectlyLinkDetails` model removed
- `RedirectlyLinkClick.linkDetails` field removed
- No more platform-specific configuration needed

### Benefits

- **Faster builds** - No native compilation
- **Simpler debugging** - All code in Dart
- **Smaller bundle size** - No native libraries
- **Easier testing** - Pure Dart unit tests

### Migration Steps

1. Update to `flutter_redirectly: ^2.0.0`
2. Remove any platform-specific configurations (they're handled by `app_links`)
3. Update link click handling to use `username` and `slug` instead of `linkDetails`

## Example

Check out the [example app](./example) for a complete implementation showing all features.

## Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 **Email**: <support@redirectly.app>
- 🐛 **Issues**: [GitHub Issues](https://github.com/redirectly-app/flutter_redirectly/issues)
- 📚 **Documentation**: [redirectly.app/docs](https://redirectly.app/docs)
- 💬 **Community**: [Discord](https://discord.gg/redirectly)

---

Made with ❤️ by the Redirectly team
