import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../models/dashboard_summary.dart';
import '../../models/transaction_item.dart';
import '../auth/login_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();

  DashboardSummary? _summary;
  List<TransactionItem> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _dashboardService.getSummary();
      final transactions = await _dashboardService.getRecentTransactions();

      setState(() {
        _summary = summary;
        _transactions = transactions;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _openAddTransaction() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );

    if (added == true) {
      await _loadDashboard();
    }
  }

  String _formatCurrency(double value) {
    return NumberFormat.simpleCurrency(locale: 'en_US').format(value);
  }

  Widget _buildSummaryCard(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionItem transaction) {
    final categoryText = transaction.subCategory != null && transaction.subCategory!.isNotEmpty
        ? '${transaction.category} • ${transaction.subCategory}'
        : transaction.category;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(transaction.title),
        subtitle: Text('$categoryText • ${DateFormat.yMMMd().format(transaction.transactionDate)}'),
        trailing: Text(
          _formatCurrency(transaction.amount),
          style: TextStyle(
            color: transaction.isExpense ? Colors.redAccent : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              );
              if (changed == true) await _loadDashboard();
            },
            tooltip: 'View All Transactions',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        _errorMessage ?? 'Unable to load dashboard.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(
                            'Income',
                            _formatCurrency(_summary?.totalIncome ?? 0),
                            valueColor: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            'Expenses',
                            _formatCurrency(_summary?.totalExpense ?? 0),
                            valueColor: Colors.redAccent,
                          ),
                        ],
                      ),
                      _buildSummaryCard(
                        'Balance',
                        _formatCurrency(_summary?.balance ?? 0),
                        valueColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Transactions: ${_summary?.transactionCount ?? 0}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'No transactions found. Pull down to refresh after adding transactions.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      else
                        ..._transactions.map(_buildTransactionTile),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
