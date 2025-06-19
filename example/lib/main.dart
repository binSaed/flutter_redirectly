import 'package:flutter/material.dart';
import 'package:flutter_redirectly/flutter_redirectly.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Redirectly Demo (Pure Dart)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Redirectly Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _redirectly = FlutterRedirectly();
  final _slugController = TextEditingController();
  final _targetController = TextEditingController();
  final _usernameController = TextEditingController();
  final _resolveSlugController = TextEditingController();

  String _status = 'Not initialized';
  List<RedirectlyLink> _links = [];
  List<RedirectlyLinkClick> _linkClicks = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    try {
      // Replace with your actual API key and base URL
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

        // Handle the link click
        if (linkClick.error == null) {
          _showLinkClickDialog(linkClick);
        } else {
          _showErrorDialog('Link Error', linkClick.error!.message);
        }
      });

      // Check for initial link
      final initialLink = await _redirectly.getInitialLink();
      if (initialLink != null) {
        setState(() {
          _linkClicks.insert(0, initialLink);
        });
        if (initialLink.error == null) {
          _showLinkClickDialog(initialLink);
        }
      }

      setState(() {
        _status = 'Initialized successfully (Pure Dart - no native code!)';
        _initialized = true;
      });

      _loadLinks();
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
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
      _showErrorDialog('Load Links Error', e.toString());
    }
  }

  Future<void> _createLink() async {
    if (!_initialized ||
        _slugController.text.isEmpty ||
        _targetController.text.isEmpty) {
      return;
    }

    try {
      final link = await _redirectly.createLink(
        slug: _slugController.text,
        target: _targetController.text,
        metadata: {
          'created_from': 'flutter_example',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _links.insert(0, link);
        _slugController.clear();
        _targetController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link created: ${link.url}')),
      );
    } catch (e) {
      _showErrorDialog('Create Link Error', e.toString());
    }
  }

  Future<void> _createTempLink() async {
    if (!_initialized || _targetController.text.isEmpty) {
      return;
    }

    try {
      final tempLink = await _redirectly.createTempLink(
        target: _targetController.text,
        slug: _slugController.text.isNotEmpty ? _slugController.text : null,
        ttlSeconds: 3600, // 1 hour
      );

      setState(() {
        _targetController.clear();
        _slugController.clear();
      });

      _showTempLinkDialog(tempLink);
    } catch (e) {
      _showErrorDialog('Create Temp Link Error', e.toString());
    }
  }

  Future<void> _resolveLink() async {
    if (!_initialized ||
        _usernameController.text.isEmpty ||
        _resolveSlugController.text.isEmpty) {
      return;
    }

    try {
      final resolution = await _redirectly.resolveLink(
        _usernameController.text,
        _resolveSlugController.text,
      );

      _showLinkResolutionDialog(resolution);
    } catch (e) {
      _showErrorDialog('Resolve Link Error', e.toString());
    }
  }

  void _showLinkClickDialog(RedirectlyLinkClick linkClick) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Clicked! 🎉'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Original URL', linkClick.originalUrl),
              _buildInfoRow('Username', linkClick.username),
              _buildInfoRow('Slug', linkClick.slug),
              _buildInfoRow('Received At', linkClick.receivedAt.toString()),
              if (linkClick.isResolved) ...[
                const SizedBox(height: 16),
                const Text(
                  '🔗 Link Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Type', linkClick.linkType ?? 'Unknown'),
                _buildInfoRow('Target', linkClick.targetUrl ?? 'Unknown'),
                if (linkClick.linkResolution?.isPermanent == true)
                  _buildInfoRow(
                      'Clicks', '${linkClick.linkResolution?.clickCount ?? 0}'),
                if (linkClick.linkResolution?.isTemporary == true &&
                    linkClick.linkResolution?.timeUntilExpiration != null)
                  _buildInfoRow('Expires In',
                      '${linkClick.linkResolution!.timeUntilExpiration!.inMinutes} minutes'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Pure Dart Implementation ✨',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                'No native code required!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
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

  void _showTempLinkDialog(RedirectlyTempLink tempLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporary Link Created'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Short URL', tempLink.url),
              _buildInfoRow('Target', tempLink.target),
              _buildInfoRow('Expires At', tempLink.expiresAt.toString()),
              const SizedBox(height: 8),
              Text(
                'TTL: ${tempLink.ttlSeconds} seconds',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
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

  void _showLinkResolutionDialog(RedirectlyLinkResolution resolution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Link Resolution - ${resolution.type.toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Slug', resolution.slug),
              _buildInfoRow('Target', resolution.target),
              _buildInfoRow('URL', resolution.url),
              _buildInfoRow('Type', resolution.type),
              _buildInfoRow('Created', resolution.createdAt.toString()),
              if (resolution.isPermanent) ...[
                _buildInfoRow('Clicks', '${resolution.clickCount ?? 0}'),
                if (resolution.metadata != null)
                  _buildInfoRow('Metadata', resolution.metadata.toString()),
              ],
              if (resolution.isTemporary) ...[
                _buildInfoRow('Expires At', resolution.expiresAt.toString()),
                if (resolution.timeUntilExpiration != null)
                  _buildInfoRow('Time Left',
                      '${resolution.timeUntilExpiration!.inMinutes} minutes'),
              ],
            ],
          ),
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plugin Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_initialized) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '✨ Pure Dart Implementation',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'No native code required! Uses app_links + http packages',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_initialized) ...[
              const SizedBox(height: 16),

              // Create Link Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Link',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug',
                          hintText: 'my-awesome-link',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _targetController,
                        decoration: const InputDecoration(
                          labelText: 'Target URL',
                          hintText: 'https://example.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _createLink,
                            child: const Text('Create Permanent Link'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _createTempLink,
                            child: const Text('Create Temp Link'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Link Resolution Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolve Link',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'john',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _resolveSlugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug',
                          hintText: 'my-link',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _resolveLink,
                        icon: const Icon(Icons.search),
                        label: const Text('Resolve Link'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Links List
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Links',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _loadLinks,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_links.isEmpty)
                        const Text('No links created yet')
                      else
                        ...(_links.map((link) => ListTile(
                              title: Text(link.slug),
                              subtitle: Text(link.target),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${link.clickCount} clicks',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    link.url,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Link Clicks
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Link Clicks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_linkClicks.isEmpty)
                        const Text('No link clicks yet')
                      else
                        ...(_linkClicks.take(5).map((click) => ListTile(
                              title: Text('${click.username}/${click.slug}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(click.originalUrl),
                                  if (click.isResolved)
                                    Text(
                                      '→ ${click.targetUrl} (${click.linkType})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                click.receivedAt.toString().substring(11, 19),
                                style: const TextStyle(fontSize: 12),
                              ),
                              leading: Icon(
                                click.error != null
                                    ? Icons.error
                                    : click.isResolved
                                        ? Icons.link_rounded
                                        : Icons.link,
                                color: click.error != null
                                    ? Colors.red
                                    : click.isResolved
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            ))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slugController.dispose();
    _targetController.dispose();
    _usernameController.dispose();
    _resolveSlugController.dispose();
    _redirectly.dispose();
    super.dispose();
  }
}
