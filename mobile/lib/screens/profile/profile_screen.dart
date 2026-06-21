import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/auth_widgets.dart';
import '../dashboard/dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goTo(int index) async {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
    } else if (index == 2) {
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
      );
      if (added == true && mounted) {
        setState(() {});
      }
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      currentIndex: 4,
      onNavTap: _goTo,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: kAuthCoral.withValues(alpha: 0.14),
                  child: const Icon(Icons.person, color: kAuthCoral, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  'Account Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: kAuthDarkText,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your expense tracker account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F6A6A),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileActionTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of this device',
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kAuthCoral.withValues(alpha: 0.12),
          child: Icon(icon, color: kAuthCoral),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
