# Changelog

All notable changes to the Flutter Redirectly plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-15

### 🎉 MAJOR: Pure Dart Implementation - No Native Code Required

This is a **BREAKING CHANGE** that completely removes all native platform code in favor of a pure Dart implementation.

#### ✅ What's New

- **Pure Dart**: Completely eliminated Android and iOS native code - now 100% Dart!
- **Simplified Architecture**: Uses `app_links` for deep link handling and `http` for API calls
- **Zero Native Dependencies**: No more method channels, platform interfaces, or native implementations
- **Faster Development**: No need to deal with Android Kotlin or iOS Swift code
- **Easier Debugging**: All logic runs in Dart, making debugging much simpler
- **Single Source of Truth**: All HTTP requests, JSON parsing, and error handling in one place

#### 🔧 Technical Changes

- Removed all Android Kotlin code (`FlutterRedirectlyPlugin.kt`)
- Removed all iOS Swift code (`FlutterRedirectlyPlugin.swift`)
- Removed method channels and platform interfaces
- Removed Android `build.gradle` and iOS `.podspec` files
- Simplified plugin structure - no longer requires platform-specific configuration
- Direct HTTP API calls using Dart's `http` package
- Pure Dart URL parsing using `Uri` class
- Streamlined link click handling with app_links

#### ⚠️ Breaking Changes

- No longer a Flutter plugin - now a pure Dart package
- Removed `RedirectlyLinkDetails` model (links redirect directly, details not fetched)
- Simplified `RedirectlyLinkClick` model (removed `linkDetails` field)
- No platform-specific configuration required

#### 📈 Benefits

- **Smaller Bundle Size**: No native code means smaller app size
- **Faster Builds**: No native compilation step
- **Easier Testing**: Pure Dart code is easier to unit test
- **Better Error Messages**: Consistent error handling across all platforms
- **Simpler Maintenance**: Single codebase instead of 3 (Dart + Android + iOS)

## [1.0.1] - 2025-01-15

### Fixed

- **iOS Integration**: Fixed CocoaPods discovery issue by moving `flutter_redirectly.podspec` to `ios/` directory
- **Platform Configuration**: Updated `pubspec.yaml` to explicitly specify podspec path for iOS
- This resolves the error: `[!] No podspec found for flutter_redirectly in .symlinks/plugins/flutter_redirectly/ios`

## [1.0.0] - 2024-01-15

### Added

- Initial release of Flutter Redirectly plugin
- **Core Features:**
  - Create permanent and temporary links via Redirectly API
  - Handle deep links in all app states (cold start, background, foreground)
  - Stream-based link click handling
  - Comprehensive error handling with typed errors
  - Support for link metadata
  - Built on `app_links` for reliable cross-platform link handling

- **API Integration:**
  - Full integration with Redirectly backend API
  - Support for `/api/v1/links` (permanent links)
  - Support for `/api/v1/temp-links` (temporary links)
  - Bearer token authentication
  - Automatic URL parsing for subdomain format (`username.redirectly.app/slug`)

- **Platform Support:**
  - Android implementation with native Kotlin
  - iOS implementation with native Swift
  - Support for both production and development URL formats

- **Developer Experience:**
  - Simple initialization with API key only
  - Type-safe models for all data structures
  - Comprehensive documentation and examples
  - Debug logging support
  - Complete example app demonstrating all features

- **Models:**
  - `RedirectlyConfig` - Plugin configuration
  - `RedirectlyLink` - Permanent link representation
  - `RedirectlyTempLink` - Temporary link with expiration
  - `RedirectlyLinkClick` - Incoming link click data
  - `RedirectlyError` - Typed error handling
  - `RedirectlyLinkDetails` - Link metadata and details

- **Error Handling:**
  - `RedirectlyErrorType.api` - API-related errors
  - `RedirectlyErrorType.network` - Network connectivity errors
  - `RedirectlyErrorType.configuration` - Setup/config errors
  - `RedirectlyErrorType.linkResolution` - Link processing errors

### Technical Details

- Minimum Flutter SDK: 3.0.0
- Minimum Dart SDK: 3.0.0
- Dependencies: `app_links ^6.3.2`, `http ^1.2.2`, `plugin_platform_interface ^2.1.8`
- Platform channels for native communication
- Event streams for real-time link handling
- HTTP client for direct API communication

### Documentation

- Complete API reference
- Setup instructions for Android and iOS
- Usage examples for all features
- Error handling patterns
- Example app with full implementation
