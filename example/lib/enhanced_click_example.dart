import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redirectly/flutter_redirectly.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Enhanced Flutter Redirectly example with comprehensive analytics
class EnhancedClickExample extends StatefulWidget {
  const EnhancedClickExample({super.key});

  @override
  State<EnhancedClickExample> createState() => _EnhancedClickExampleState();
}

class _EnhancedClickExampleState extends State<EnhancedClickExample> {
  final _redirectly = FlutterRedirectly();
  bool _initialized = false;
  String _status = 'Initializing...';
  List<RedirectlyLinkClick> _linkClicks = [];
  List<RedirectlyLink> _links = [];

  // Device info
  String _deviceInfo = 'Loading...';
  String _appInfo = 'Loading...';
  String _networkInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializePlugin();
    _loadDeviceInfo();
  }

  Future<void> _initializePlugin() async {
    try {
      // Initialize with enhanced configuration
      await _redirectly.initialize(
        RedirectlyConfig(
          apiKey: 'your-api-key-here',
          baseUrl: 'https://api.redirectly.app',
          enableDebugLogging: true,
        ),
      );

      // Listen to link clicks
      _redirectly.onLinkClick.listen((linkClick) {
        setState(() {
          _linkClicks.insert(0, linkClick);
          if (_linkClicks.length > 10) {
            _linkClicks.removeLast();
          }
        });

        // Handle the link click with enhanced logging
        if (linkClick.error == null) {
          _logEnhancedClick(linkClick);
        }
      });

      setState(() {
        _status = 'Initialized with enhanced analytics!';
        _initialized = true;
      });

      _loadLinks();
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  String _getFlutterVersion() {
    // Extract Flutter version from Platform.version
    // Platform.version format: "2.19.0 (stable) (Tue Jan 10 15:26:53 2023 +0000) on "macos_arm64""
    try {
      final version = Platform.version;
      final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(version);
      return match?.group(1) ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  String _formatConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return 'none';
    return results.map((result) => result.name).join(', ');
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final connectivity = Connectivity();

    String deviceDetails = '';
    String appDetails = '';
    String networkDetails = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceDetails = '''
Android Device Info:
• Model: ${androidInfo.model}
• Manufacturer: ${androidInfo.manufacturer}
• Android Version: ${androidInfo.version.release}
• API Level: ${androidInfo.version.sdkInt}
• Brand: ${androidInfo.brand}
• Device: ${androidInfo.device}
• Hardware: ${androidInfo.hardware}
• Supported ABIs: ${androidInfo.supportedAbis.join(', ')}
• Is Physical Device: ${androidInfo.isPhysicalDevice}
        ''';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceDetails = '''
iOS Device Info:
• Model: ${iosInfo.model}
• Name: ${iosInfo.name}
• iOS Version: ${iosInfo.systemVersion}
• Device Type: ${iosInfo.localizedModel}
• Identifier: ${iosInfo.identifierForVendor}
• Is Physical Device: ${iosInfo.isPhysicalDevice}
        ''';
      }

      appDetails = '''
App Info:
• App Name: ${packageInfo.appName}
• Package Name: ${packageInfo.packageName}
• Version: ${packageInfo.version}
• Build Number: ${packageInfo.buildNumber}
      ''';

      final connectivityResult = await connectivity.checkConnectivity();
      networkDetails = '''
Network Info:
• Connection Type: ${_formatConnectivityResult(connectivityResult)}
• Timestamp: ${DateTime.now().toIso8601String()}
      ''';
    } catch (e) {
      deviceDetails = 'Error loading device info: $e';
    }

    setState(() {
      _deviceInfo = deviceDetails;
      _appInfo = appDetails;
      _networkInfo = networkDetails;
    });
  }

  Future<void> _logEnhancedClick(RedirectlyLinkClick linkClick) async {
    if (!_initialized) return;

    try {
      // Collect comprehensive device and app information
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      Map<String, dynamic> enhancedData = {
        'slug': linkClick.slug,
        'username': linkClick.username,
        'app_version': packageInfo.version,
        'app_build_number': packageInfo.buildNumber,
        'app_platform': Platform.isAndroid ? 'android' : 'ios',
        'connectivity_type': _formatConnectivityResult(connectivityResult),
        'timezone': DateTime.now().timeZoneOffset.toString(),
        'language': Platform.localeName,
        'metadata': {
          'original_url': linkClick.originalUrl,
          'received_at': linkClick.receivedAt.toIso8601String(),
          'flutter_sdk_version': _getFlutterVersion(),
          'dart_version': Platform.version.split(' ').first,
        },
      };

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        enhancedData.addAll({
          'device_type': 'mobile',
          'os_name': 'Android',
          'os_version': androidInfo.version.release,
          'screen_resolution':
              'unknown', // displayMetrics not available in newer versions
          'metadata': {
            ...enhancedData['metadata'],
            'manufacturer': androidInfo.manufacturer,
            'model': androidInfo.model,
            'brand': androidInfo.brand,
            'api_level': androidInfo.version.sdkInt,
            'supported_abis': androidInfo.supportedAbis,
            'is_physical_device': androidInfo.isPhysicalDevice,
          },
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        enhancedData.addAll({
          'device_type': 'mobile',
          'os_name': 'iOS',
          'os_version': iosInfo.systemVersion,
          'metadata': {
            ...enhancedData['metadata'],
            'model': iosInfo.model,
            'name': iosInfo.name,
            'localized_model': iosInfo.localizedModel,
            'identifier_for_vendor': iosInfo.identifierForVendor,
            'is_physical_device': iosInfo.isPhysicalDevice,
          },
        });
      }

      // Here you would typically send this to your analytics API
      // For demonstration, we'll just log it
      debugPrint('Enhanced Click Data: $enhancedData');

      // Example of sending to custom analytics endpoint
      // await _sendToCustomAnalytics(enhancedData);
    } catch (e) {
      debugPrint('Failed to collect enhanced click analytics: $e');
    }
  }

  Future<void> _loadLinks() async {
    if (!_initialized) return;

    try {
      final links = await _redirectly.getLinks();
      setState(() {
        _links = links;
      });
    } catch (e) {
      debugPrint('Failed to load links: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Click Analytics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plugin Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_initialized) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadLinks,
                        child: const Text('Refresh Links'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Device Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      title: const Text('Device Details'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _deviceInfo,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('App Details'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _appInfo,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Network Details'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _networkInfo,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent Link Clicks
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Link Clicks (${_linkClicks.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_linkClicks.isEmpty)
                      const Text(
                          'No link clicks yet. Try opening a Redirectly link!')
                    else
                      ..._linkClicks.map((click) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                click.error == null
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: click.error == null
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text('${click.username}/${click.slug}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Received: ${click.receivedAt}'),
                                  if (click.targetUrl != null)
                                    Text('Target: ${click.targetUrl}'),
                                  if (click.error != null)
                                    Text('Error: ${click.error!.message}'),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Links List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Links (${_links.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_links.isEmpty)
                      const Text('No links found. Create some links first!')
                    else
                      ..._links.map((link) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(link.slug),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Target: ${link.target}'),
                                  Text('Clicks: ${link.clickCount}'),
                                  Text('Created: ${link.createdAt}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  // Copy link URL to clipboard
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Copied: ${link.url}'),
                                    ),
                                  );
                                },
                              ),
                              isThreeLine: true,
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _redirectly.dispose();
    super.dispose();
  }
}
