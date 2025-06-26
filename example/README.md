# Flutter Redirectly Example

A comprehensive example demonstrating all features of the Flutter Redirectly package.

## Setup Instructions

### 1. Configure Your Subdomain

Replace `YOUR_SUBDOMAIN` in the following files with your actual Redirectly subdomain:

**Android** - `android/app/src/main/AndroidManifest.xml`:

```xml
<data android:scheme="https" android:host="YOUR_SUBDOMAIN.redirectly.app" />
```

**iOS** - `ios/Runner/Runner.entitlements`:

```xml
<string>applinks:YOUR_SUBDOMAIN.redirectly.app</string>
```

### 2. iOS Additional Setup

For iOS, you also need to:

1. **Enable Associated Domains** capability in your Apple Developer account
2. **Add the domain** `applinks:YOUR_SUBDOMAIN.redirectly.app` to your app's Associated Domains
3. **Ensure proper code signing** is configured

### 3. Get Your API Key

1. Go to your Redirectly dashboard
2. Generate an API key
3. Enter it in the app when prompted

## Running the Example

```bash
flutter run
```

## Testing Deep Links

1. **Create a link** using the app
2. **Copy the generated URL**
3. **Test scenarios**:
   - **Cold start**: Close app → Open link in browser → App launches
   - **Warm start**: App in background → Open link → App comes to foreground
   - **Hot reception**: App open → Open link → Link handled immediately

## Features Demonstrated

- ✅ **Initialization** with API key validation
- ✅ **Initial link detection** (app opened via link)
- ✅ **Runtime link listening** (app already running)
- ✅ **Permanent link creation** with metadata
- ✅ **Temporary link creation** with expiration
- ✅ **Error handling** with user-friendly messages
- ✅ **Link history** tracking
- ✅ **Auto-copy to clipboard** for created links

## Troubleshooting

- **Android**: Check that `android:autoVerify="true"` is set
- **iOS**: Ensure Associated Domains are properly configured in both the entitlements file and Apple Developer Console
- **Both**: Make sure your subdomain matches exactly (no typos!)
