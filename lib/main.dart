import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  const websiteUrl = String.fromEnvironment('WEB_URL', defaultValue: 'https://example.com');
  runApp(MyApp(websiteUrl: websiteUrl));
}

class MyApp extends StatelessWidget {
  final String websiteUrl;

  const MyApp({super.key, required this.websiteUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Custom App', // Nama aplikasi di task switcher
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
          child: Image.asset('assets/icon/app_icon.png', width: 150, height: 150),
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

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.websiteUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}
