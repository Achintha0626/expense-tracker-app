import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    String message = 'Registration failed. Please try again.';
    bool success = false;

    try {
      final response = await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        success = true;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      message = _parseError(response.body);
    } catch (error) {
      message = error.toString();
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
    return 'Registration failed. Please try again.';
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
        child: Container(
          color: kAuthLightBackground,
          child: Stack(
            children: [
              const AuthHeaderBackground(
                title: 'Welcome',
                subtitle: 'Create your account and start tracking spending today.',
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: media.height * 0.22,
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
                                  'Sign up',
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
                                  controller: _nameController,
                                  labelText: 'Name',
                                  prefixIcon: LucideIcons.user,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Name is required.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
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
                                const SizedBox(height: 24),
                                PrimaryAuthButton(
                                  text: 'Create Account',
                                  isLoading: _isLoading,
                                  onPressed: _register,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an Account? ',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                    ),
                                    TextButton(
                                      onPressed: _openLogin,
                                      child: const Text(
                                        'Sign in',
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
        ),
      ),
    );
  }
}
