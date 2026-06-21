import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    String message = 'Login failed. Please try again.';
    bool success = false;

    try {
      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _authService.saveToken(token);
          success = true;
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
          return;
        }
      }

      message = _parseError(response.body);
    } catch (error) {
      final errorMsg = error.toString();
      // Check for timeout or network errors
      if (errorMsg.contains('timed out') || 
          errorMsg.contains('Cannot connect') ||
          errorMsg.contains('network')) {
        message = 'Server is waking up. Please wait a few seconds and try again.';
      } else {
        message = errorMsg;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (!success) {
        _showSnackbar(message);
      }
    }
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {
      // ignore
    }
    return 'Login failed. Please try again.';
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isDesktopLike = media.width > 600;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: isDesktopLike ? 0 : 16,
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              color: kAuthLightBackground,
              child: Stack(
                children: [
                  const AuthHeaderBackground(
                    title: 'Welcome Back',
                    subtitle: 'Track your money with a clean, simple finance view.',
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: media.height * 0.23,
                        bottom: 20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Padding(
                            padding: contentPadding,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(40),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(0, 0, 0, 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, -8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Sign in',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: kAuthDarkText,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: 60,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: kAuthCoral,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    AuthTextField(
                                      controller: _emailController,
                                      labelText: 'Email',
                                      prefixIcon: LucideIcons.mail,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Email is required.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    AuthTextField(
                                      controller: _passwordController,
                                      labelText: 'Password',
                                      prefixIcon: LucideIcons.lock,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onSuffixPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      suffixIcon: Icon(
                                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                        color: Colors.grey.shade600,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Password is required.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          activeColor: kAuthCoral,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                        ),
                                        const Text('Remember Me'),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text('Forgot Password?'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    PrimaryAuthButton(
                                      text: _isLoading ? 'Signing in...' : 'Login',
                                      isLoading: _isLoading,
                                      onPressed: _login,
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an Account? ",
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey.shade700,
                                              ),
                                        ),
                                        TextButton(
                                          onPressed: _openRegister,
                                          child: const Text(
                                            'Sign up',
                                            style: TextStyle(
                                              color: kAuthCoral,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
