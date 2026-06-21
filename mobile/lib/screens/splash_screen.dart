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
      backgroundColor: const Color(0xFFFFFBFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/app_icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            const Text(
              'Expense Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F2F2F),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Color(0xFFE97D7D),
            ),
            const SizedBox(height: 24),
            Text(
              _loadingText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6F6A6A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
