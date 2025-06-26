# Changelog

All notable changes to the Flutter Redirectly plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.4] - 2025-01-15

### Fixed

- Minor bug fixes and stability improvements

## [2.0.3] - 2025-01-15

### Fixed

- Minor bug fixes and stability improvements

## [2.0.2] - 2025-01-15

### Fixed

- Minor bug fixes and stability improvements

## [2.0.1] - 2025-01-15

### Fixed

- Minor bug fixes and stability improvements

## [2.0.0] - 2025-01-15

### 🎉 Initial Release

Flutter package for creating and handling dynamic links using your own Redirectly backend. **Pure Dart implementation - no native code required!**

#### ✅ Core Features

- **Create Links**: Generate permanent and temporary links via Redirectly API
- **Handle Deep Links**: Process links in all app states (cold start, background, foreground)
- **Stream-based Events**: Real-time link click notifications
- **Error Handling**: Comprehensive error handling with typed errors
- **Pure Dart**: Zero native dependencies - uses `app_links` + `http` packages only

#### ✅ API Integration

- Full integration with Redirectly backend API
- Support for permanent links (`/api/v1/links`)
- Support for temporary links (`/api/v1/temp-links`)
- Bearer token authentication
- Custom metadata support for links

#### ✅ Platform Support

- **Android**: Deep link handling via intent filters
- **iOS**: Universal Links with Associated Domains
- **Cross-platform**: Single Dart codebase works everywhere

#### ✅ Developer Experience

- Simple configuration with just an API key
- Type-safe models for all data structures
- Comprehensive example app
- Debug logging support
- Easy setup with minimal configuration

#### ✅ Models & API

- `RedirectlyConfig` - Plugin configuration
- `RedirectlyLink` - Permanent link representation  
- `RedirectlyTempLink` - Temporary link with expiration
- `RedirectlyLinkClick` - Incoming link click data
- `RedirectlyError` - Typed error handling

#### ✅ Error Types

- `RedirectlyErrorType.api` - API-related errors (4xx, 5xx)
- `RedirectlyErrorType.network` - Network connectivity issues
- `RedirectlyErrorType.configuration` - Setup/initialization errors
- `RedirectlyErrorType.linkResolution` - Link parsing/processing errors

#### 📦 Dependencies

- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- `app_links: ^6.3.2` - Cross-platform deep link handling
- `http: ^1.2.2` - HTTP client for API calls

#### 📚 Documentation

- Complete setup instructions for Android and iOS
- Comprehensive API reference
- Working example app with all features
- Step-by-step integration guide
