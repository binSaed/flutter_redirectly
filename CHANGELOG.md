# Changelog

All notable changes to the Flutter Redirectly plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
