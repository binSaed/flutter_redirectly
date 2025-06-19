# Flutter Redirectly

A Flutter plugin that provides Firebase Dynamic Links-like functionality using your own Redirectly backend. This plugin allows you to create, manage, and handle dynamic links in your Flutter app.

## Features

- 🔗 **Create permanent and temporary links** via API
- 📱 **Handle deep links** in all app states (cold start, background, foreground)
- 🚀 **Built on app_links** for reliable link handling
- 🔧 **Simple configuration** with just an API key
- 📊 **Full link details** when links are clicked
- 🛡️ **Comprehensive error handling**
- 🔄 **No caching** - always fresh data
- 🌐 **Support for both Android and iOS**

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_redirectly: ^1.0.0
```

## Backend Setup

This plugin works with the Redirectly backend. Make sure you have:

1. A running Redirectly instance
2. A valid API key from your Redirectly dashboard
3. Your links follow the format: `https://username.redirectly.app/slug`

## Configuration

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
        <data android:scheme="https" android:host="*.redirectly.app" />
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
  enableDebugLogging: true, // Optional
));
```

### Listen for incoming links

```dart
// Listen to link clicks when app is running
redirectly.onLinkClick.listen((linkClick) {
  print('Link clicked: ${linkClick.originalUrl}');
  print('Username: ${linkClick.username}');
  print('Slug: ${linkClick.slug}');
  
  if (linkClick.isSuccessful) {
    // Handle successful link
    print('Target: ${linkClick.linkDetails?.target}');
  } else {
    // Handle error
    print('Error: ${linkClick.error}');
  }
});

// Check for initial link (when app is opened via link)
final initialLink = await redirectly.getInitialLink();
if (initialLink != null) {
  // Handle initial link
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

// Create a temporary link (expires after 15 minutes)
final tempLink = await redirectly.createTempLink(
  target: 'https://example.com/temp-content',
  ttlSeconds: 900, // 15 minutes
);

print('Temp link: ${tempLink.url}');
print('Expires at: ${tempLink.expiresAt}');
```

### Manage links

```dart
// Get all your permanent links
final links = await redirectly.getLinks();
for (final link in links) {
  print('${link.slug} -> ${link.target} (${link.clickCount} clicks)');
}
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
class RedirectlyLink {
  final String slug;           // Link slug
  final String target;         // Target URL
  final String url;           // Full clickable URL
  final int clickCount;       // Number of clicks
  final DateTime createdAt;   // Creation timestamp
  final DateTime? updatedAt;  // Last update timestamp
  final Map<String, dynamic>? metadata; // Optional metadata
}
```

### RedirectlyTempLink

Represents a temporary link.

```dart
class RedirectlyTempLink {
  final String slug;          // Link slug
  final String target;        // Target URL
  final String url;          // Full clickable URL
  final DateTime expiresAt;  // Expiration timestamp
  final DateTime createdAt;  // Creation timestamp
  final int? ttlSeconds;     // TTL in seconds
  
  bool get isExpired;        // Check if expired
  Duration get timeUntilExpiration; // Time until expiration
}
```

### RedirectlyLinkClick

Represents a clicked link received by the app.

```dart
class RedirectlyLinkClick {
  final String originalUrl;           // Original clicked URL
  final String slug;                  // Extracted slug
  final String username;              // Extracted username
  final RedirectlyLinkDetails? linkDetails; // Link details (if available)
  final RedirectlyError? error;       // Error (if any)
  final DateTime receivedAt;          // When received
  
  bool get isSuccessful;              // Whether processing was successful
}
```

## Example

Check out the [example app](example/) for a complete implementation showing:

- Plugin initialization
- Creating permanent and temporary links
- Handling incoming link clicks
- Error handling
- UI for managing links

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅       |
| iOS      | ✅       |
| Web      | ❌       |
| macOS    | ❌       |
| Windows  | ❌       |
| Linux    | ❌       |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please file an issue on the [GitHub repository](https://github.com/yourname/flutter_redirectly).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.
