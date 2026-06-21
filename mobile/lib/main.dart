import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'widgets/auth_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kAuthLightBackground,
        colorScheme: const ColorScheme.light(
          primary: kAuthCoral,
          secondary: kAuthSoftCoral,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: kAuthDarkText,
          onSurfaceVariant: kAuthMutedText,
          outline: Color(0xFFE7DCDC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kAuthLightBackground,
          surfaceTintColor: kAuthLightBackground,
          foregroundColor: kAuthDarkText,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: kAuthCoral,
          unselectedItemColor: kAuthMutedText,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE7DCDC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE7DCDC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kAuthCoral, width: 1.4),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
