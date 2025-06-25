import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redirectly/flutter_redirectly.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Simple example showing dynamic version tracking
class SimpleVersionExample extends StatefulWidget {
  const SimpleVersionExample({super.key});

  @override
  State<SimpleVersionExample> createState() => _SimpleVersionExampleState();
}

class _SimpleVersionExampleState extends State<SimpleVersionExample> {
  final _redirectly = FlutterRedirectly();
  bool _initialized = false;
  String _status = 'Initializing...';
  List<RedirectlyLinkClick> _linkClicks = [];

  // Version info
  String _appVersion = 'Loading...';
  String _dartVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializePlugin();
    _loadVersionInfo();
  }

  Future<void> _initializePlugin() async {
    try {
      await _redirectly.initialize(
        RedirectlyConfig(
          apiKey: 'your-api-key-here',
          baseUrl: 'https://api.redirectly.app',
          enableDebugLogging: true,
        ),
      );

      // Listen to link clicks with automatic version tracking
      _redirectly.onLinkClick.listen((linkClick) {
        setState(() {
          _linkClicks.insert(0, linkClick);
          if (_linkClicks.length > 5) {
            _linkClicks.removeLast();
          }
        });

        if (linkClick.error == null) {
          _showLinkClickDialog(linkClick);
        }
      });

      setState(() {
        _status = 'Initialized with dynamic version tracking!';
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _dartVersion = Platform.version.split(' ').first;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Error loading version';
        _dartVersion = 'Error loading version';
      });
    }
  }

  void _showLinkClickDialog(RedirectlyLinkClick linkClick) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Link Clicked: ${linkClick.username}/${linkClick.slug}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${linkClick.targetUrl ?? 'Unknown'}'),
            Text('Type: ${linkClick.linkType ?? 'Unknown'}'),
            Text('Received: ${linkClick.receivedAt}'),
            const SizedBox(height: 16),
            const Text('Version Info Logged:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Plugin version: Dynamically loaded from pubspec.yaml'),
            Text('• App version: $_appVersion'),
            Text('• Dart version: $_dartVersion'),
            Text('• Platform: ${Platform.operatingSystem}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Version Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
                    const SizedBox(height: 16),
                    const Text(
                      'Features Demonstrated:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('✅ Dynamic plugin version from pubspec.yaml'),
                    const Text('✅ Automatic click logging with version info'),
                    const Text('✅ App version tracking'),
                    const Text('✅ Dart runtime version'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Version Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('App Version: $_appVersion'),
                    Text('Dart Version: $_dartVersion'),
                    Text('Platform: ${Platform.operatingSystem}'),
                    const Text('Plugin Version: Loaded dynamically'),
                    const SizedBox(height: 8),
                    const Text(
                      'All this information is automatically included in click logs!',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
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
                      const Column(
                        children: [
                          Text('No link clicks yet.'),
                          SizedBox(height: 8),
                          Text(
                            'To test: Create a link in your dashboard and open it in this app. The click will be logged with dynamic version information!',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      )
                    else
                      ...(_linkClicks.map((click) => Card(
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
                              subtitle: Text('Received: ${click.receivedAt}'),
                              trailing: const Icon(Icons.info),
                              onTap: () => _showLinkClickDialog(click),
                            ),
                          ))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How It Works',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '1. Plugin reads version from pubspec.yaml at runtime'),
                    Text(
                        '2. When you click a Redirectly link, version info is logged'),
                    Text(
                        '3. Analytics include plugin version, app version, Dart version'),
                    Text('4. No more hardcoded version numbers!'),
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
