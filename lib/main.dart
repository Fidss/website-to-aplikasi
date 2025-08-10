import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ambil nama aplikasi dari AndroidManifest.xml
  final packageInfo = await PackageInfo.fromPlatform();
  final appName = packageInfo.appName;

  const websiteUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://example.com',
  );

  runApp(MyApp(websiteUrl: websiteUrl, appName: appName));
}

class MyApp extends StatelessWidget {
  final String websiteUrl;
  final String appName;

  const MyApp({super.key, required this.websiteUrl, required this.appName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName, // Sinkron dengan AndroidManifest.xml
      debugShowCheckedModeBanner: false,
      home: SplashScreen(websiteUrl: websiteUrl),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final String websiteUrl;

  const SplashScreen({super.key, required this.websiteUrl});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WebViewScreen(websiteUrl: widget.websiteUrl),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('assets/icon/app_icon.png',
              width: 150, height: 150),
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String websiteUrl;

  const WebViewScreen({super.key, required this.websiteUrl});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with SingleTickerProviderStateMixin {
  WebViewController? _controller;
  bool _isOnline = true;
  bool _isLoading = true;
  StreamSubscription? _connectivitySub;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _listenConnectivity();
    _checkAndLoad();
  }

  void _listenConnectivity() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      // Versi terbaru connectivity_plus mengembalikan List<ConnectivityResult>
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;

      final online = await _hasInternet();
      if (online != _isOnline) {
        setState(() {
          _isOnline = online;
        });
        if (online && _controller == null) {
          _loadWebView();
        }
      }
    });
  }

  Future<void> _checkAndLoad() async {
    _isOnline = await _hasInternet();
    if (_isOnline) {
      _loadWebView();
    } else {
      setState(() {});
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final uri = Uri.parse(widget.websiteUrl);
      final host = uri.host;
      if (host.isEmpty) return false;
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _loadWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isOnline = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.websiteUrl));
    setState(() {});
  }

  Widget _offlinePage() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.1)
                    .animate(CurvedAnimation(
                        parent: _animController, curve: Curves.easeInOut)),
                child: Image.asset(
                  'assets/icon/offline.png', // Path sesuai permintaan
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Oops! Koneksi Hilang',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pastikan perangkatmu terhubung ke internet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _checkAndLoad,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return _offlinePage();
    }
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
