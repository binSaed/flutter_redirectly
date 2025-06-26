import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redirectly/flutter_redirectly.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Redirectly Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RedirectlyExample(),
    );
  }
}

class RedirectlyExample extends StatefulWidget {
  const RedirectlyExample({super.key});

  @override
  State<RedirectlyExample> createState() => _RedirectlyExampleState();
}

class _RedirectlyExampleState extends State<RedirectlyExample> {
  final FlutterRedirectly _redirectly = FlutterRedirectly();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isInitialized = false;
  bool _isLoading = false;
  String _status = 'Not initialized';
  final List<String> _linkHistory = [];
  RedirectlyLinkClick? _lastLinkClick;
  RedirectlyLink? _lastCreatedLink;
  RedirectlyTempLink? _lastCreatedTempLink;

  @override
  void initState() {
    super.initState();
    _targetController.text = 'https://example.com';
  }

  @override
  void dispose() {
    _slugController.dispose();
    _targetController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _initializeRedirectly() async {
    if (_apiKeyController.text.isEmpty) {
      _showSnackBar('Please enter your API key', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Initializing...';
    });

    try {
      await _redirectly.initialize(RedirectlyConfig(
        apiKey: _apiKeyController.text,
        enableDebugLogging: true,
      ));

      // Listen for incoming links when app is running
      _redirectly.onLinkClick.listen((linkClick) {
        setState(() {
          _lastLinkClick = linkClick;
          _linkHistory.insert(0, 'App Running: ${linkClick.originalUrl}');
        });
        _showSnackBar('Link received: ${linkClick.slug}');
      });

      // Check for initial link (when app was opened via link)
      final initialLink = await _redirectly.getInitialLink();
      if (initialLink != null) {
        setState(() {
          _lastLinkClick = initialLink;
          _linkHistory.insert(0, 'App Launch: ${initialLink.originalUrl}');
        });
        _showSnackBar('Initial link detected: ${initialLink.slug}');
      }

      setState(() {
        _isInitialized = true;
        _status = 'Ready! Listening for links...';
      });

      _showSnackBar('Redirectly initialized successfully!');
    } on RedirectlyError catch (e) {
      setState(() {
        _status = 'Error: ${e.message}';
      });
      _showSnackBar('Initialization failed: ${e.message}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPermanentLink() async {
    if (_slugController.text.isEmpty || _targetController.text.isEmpty) {
      _showSnackBar('Please enter both slug and target URL', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final link = await _redirectly.createLink(
        slug: _slugController.text,
        target: _targetController.text,
        metadata: {'created_from': 'flutter_example'},
      );

      setState(() {
        _lastCreatedLink = link;
      });

      await Clipboard.setData(ClipboardData(text: link.url));
      _showSnackBar('Permanent link created and copied to clipboard!');
      _slugController.clear();
    } on RedirectlyError catch (e) {
      _showSnackBar('Failed to create link: ${e.message}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTempLink() async {
    if (_targetController.text.isEmpty) {
      _showSnackBar('Please enter target URL', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tempLink = await _redirectly.createTempLink(
        target: _targetController.text,
        slug: _slugController.text.isNotEmpty ? _slugController.text : null,
        ttlSeconds: 3600, // 1 hour
      );

      setState(() {
        _lastCreatedTempLink = tempLink;
      });

      await Clipboard.setData(ClipboardData(text: tempLink.url));
      _showSnackBar('Temporary link created and copied to clipboard!');
      _slugController.clear();
    } on RedirectlyError catch (e) {
      _showSnackBar('Failed to create temp link: ${e.message}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Redirectly Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Initialization Section
            if (!_isInitialized) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Initialize Redirectly',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'API Key',
                          hintText: 'Enter your Redirectly API key',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _initializeRedirectly,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Initialize'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Link Creation Section
            if (_isInitialized) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Links',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug (optional for temp links)',
                          hintText: 'my-awesome-link',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _createPermanentLink,
                              child: const Text('Create Permanent Link'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createTempLink,
                              child: const Text('Create Temp Link (1h)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Last Created Links
              if (_lastCreatedLink != null || _lastCreatedTempLink != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created Links',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_lastCreatedLink != null) ...[
                          Text('Permanent Link:',
                              style: Theme.of(context).textTheme.bodySmall),
                          SelectableText(_lastCreatedLink!.url),
                          Text('Clicks: ${_lastCreatedLink!.clickCount}'),
                          const SizedBox(height: 8),
                        ],
                        if (_lastCreatedTempLink != null) ...[
                          Text('Temporary Link:',
                              style: Theme.of(context).textTheme.bodySmall),
                          SelectableText(_lastCreatedTempLink!.url),
                          Text('Expires: ${_lastCreatedTempLink!.expiresAt}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Last Received Link
              if (_lastLinkClick != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Received Link',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('URL: ${_lastLinkClick!.originalUrl}'),
                        Text('Username: ${_lastLinkClick!.username}'),
                        Text('Slug: ${_lastLinkClick!.slug}'),
                        Text('Received: ${_lastLinkClick!.receivedAt}'),
                        if (_lastLinkClick!.error != null)
                          Text(
                            'Error: ${_lastLinkClick!.error!.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Link History
              if (_linkHistory.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Link History',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ..._linkHistory.take(5).map((link) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                link,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
