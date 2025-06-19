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
      title: 'Flutter Redirectly Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  final FlutterRedirectly _redirectly = FlutterRedirectly();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  List<RedirectlyLinkClick> _linkClicks = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupRedirectly();
  }

  Future<void> _setupRedirectly() async {
    // Listen to incoming link clicks
    _redirectly.onLinkClick.listen((linkClick) {
      setState(() {
        _linkClicks.insert(0, linkClick);
      });

      // Show a dialog when link is clicked
      if (mounted) {
        _showLinkClickDialog(linkClick);
      }
    });

    // Check for initial link
    final initialLink = await _redirectly.getInitialLink();
    if (initialLink != null) {
      setState(() {
        _linkClicks.insert(0, initialLink);
      });
      if (mounted) {
        _showLinkClickDialog(initialLink);
      }
    }
  }

  Future<void> _initialize() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your API key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _redirectly.initialize(RedirectlyConfig(
        apiKey: _apiKeyController.text.trim(),
        enableDebugLogging: true,
      ));

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createLink() async {
    if (!_isInitialized) return;

    if (_slugController.text.trim().isEmpty ||
        _targetController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both slug and target URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _redirectly.createLink(
        slug: _slugController.text.trim(),
        target: _targetController.text.trim(),
      );

      _slugController.clear();
      _targetController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create link: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTempLink() async {
    if (!_isInitialized) return;

    if (_targetController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter target URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tempLink = await _redirectly.createTempLink(
        target: _targetController.text.trim(),
        ttlSeconds: 900, // 15 minutes
      );

      _targetController.clear();

      if (mounted) {
        _showTempLinkDialog(tempLink);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create temp link: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLinkClickDialog(RedirectlyLinkClick linkClick) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Clicked'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL: ${linkClick.originalUrl}'),
            Text('Username: ${linkClick.username}'),
            Text('Slug: ${linkClick.slug}'),
            if (linkClick.error != null)
              Text('Error: ${linkClick.error}',
                  style: const TextStyle(color: Colors.red)),
            if (linkClick.linkDetails != null)
              Text('Target: ${linkClick.linkDetails!.target}'),
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

  void _showTempLinkDialog(RedirectlyTempLink tempLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporary Link Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL: ${tempLink.url}'),
            Text('Target: ${tempLink.target}'),
            Text('Expires: ${tempLink.expiresAt}'),
            const SizedBox(height: 8),
            const Text('This link will expire in 15 minutes.'),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Key Section
            if (!_isInitialized) ...[
              const Text(
                'Initialize Flutter Redirectly',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
              ElevatedButton(
                onPressed: _isLoading ? null : _initialize,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Initialize'),
              ),
            ],

            // Main Features Section
            if (_isInitialized) ...[
              const Text(
                'Create Link',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createLink,
                      child: const Text('Create Permanent Link'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createTempLink,
                      child: const Text('Create Temp Link'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Link Clicks
              const Text(
                'Recent Link Clicks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_linkClicks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No link clicks received yet.'),
                  ),
                )
              else
                ...(_linkClicks.take(5).map((click) => Card(
                      child: ListTile(
                        title: Text('${click.username}/${click.slug}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('URL: ${click.originalUrl}'),
                            if (click.error != null)
                              Text('Error: ${click.error}',
                                  style: const TextStyle(color: Colors.red)),
                            if (click.linkDetails != null)
                              Text('Target: ${click.linkDetails!.target}'),
                            Text('Received: ${click.receivedAt}'),
                          ],
                        ),
                        isThreeLine: true,
                        leading: Icon(
                          click.isSuccessful ? Icons.check_circle : Icons.error,
                          color: click.isSuccessful ? Colors.green : Colors.red,
                        ),
                      ),
                    ))),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
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
    _apiKeyController.dispose();
    _redirectly.dispose();
    super.dispose();
  }
}
