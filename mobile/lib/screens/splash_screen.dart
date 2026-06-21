import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  String _loadingText = 'Starting server...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // First, try to wake up the server with a health check
    await _performHealthCheck();
    
    // Then check authentication
    if (!mounted) return;
    await _checkAuthentication();
  }

  Future<void> _performHealthCheck() async {
    try {
      final isHealthy = await _authService.healthCheck();
      if (!mounted) return;
      if (!isHealthy) {
        setState(() {
          _loadingText = 'Server may still be waking up. First request may take a moment.';
        });
        // Wait briefly to show the message
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingText = 'Server may still be waking up. First request may take a moment.';
      });
      // Wait briefly to show the message
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _checkAuthentication() async {
    final token = await _authService.getToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_loadingText),
          ],
        ),
      ),
    );
  }
}
