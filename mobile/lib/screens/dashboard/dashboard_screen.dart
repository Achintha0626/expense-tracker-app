import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../models/analytics_models.dart';
import '../../models/dashboard_summary.dart';
import '../../models/transaction_item.dart';
import '../auth/login_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/category_summary_tile.dart';
import '../../widgets/expense_donut_chart.dart';
import '../../widgets/monthly_bar_chart.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/recent_transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();

  DashboardSummary? _summary;
  List<TransactionItem> _transactions = [];
  List<CategoryBreakdownItem> _categoryBreakdown = [];
  List<MonthlySummaryItem> _monthlySummary = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedDateFilter = 'this_month';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _setDateFilter('this_month');
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _dashboardService.getSummary();
      final transactions = await _dashboardService.getRecentTransactions();
      final categoryBreakdown = await _analyticsService.getCategoryBreakdown(
        startDate: _startDate,
        endDate: _endDate,
      );
      final monthlySummary = await _analyticsService.getMonthlySummary(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _summary = summary;
        _transactions = transactions;
        _categoryBreakdown = categoryBreakdown;
        _monthlySummary = monthlySummary;
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
    return NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ').format(value);
  }

  String _getDateFilterLabel() {
    switch (_selectedDateFilter) {
      case 'last_month':
        return 'Last Month';
      case 'custom_range':
        if (_startDate != null && _endDate != null) {
          final start = DateFormat.yMMMd().format(_startDate!);
          final end = DateFormat.yMMMd().format(_endDate!);
          return '$start – $end';
        }
        return 'Custom Range';
      default:
        return 'This Month';
    }
  }

  Future<void> _setDateFilter(String key) async {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (key == 'custom_range') {
      final selectedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1),
        initialDateRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      );

      if (selectedRange == null) {
        return;
      }

      start = selectedRange.start;
      end = selectedRange.end;
    } else if (key == 'last_month') {
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(start.year, start.month + 1, 0);
    } else {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month, now.day);
    }

    setState(() {
      _selectedDateFilter = key;
      _startDate = start;
      _endDate = end;
    });

    await _loadDashboard();
  }

  Widget _buildCategoryList() {
    if (_categoryBreakdown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No categories yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final expenseItems = _categoryBreakdown.where((item) => item.amount > 0).toList();
    final maxAmount = expenseItems.isNotEmpty ? expenseItems.map((item) => item.amount).reduce((a, b) => a > b ? a : b) : 0.0;

    return Column(
      children: expenseItems.take(4).map((item) {
        return CategorySummaryTile(item: item, progressBase: maxAmount);
      }).toList(),
    );
  }

  Widget _buildRecentTransaction(TransactionItem transaction) {
    return RecentTransactionTile(
      transaction: transaction,
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(38),
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            _errorMessage ?? 'Unable to load dashboard.',
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        children: [
                          Text('Good morning', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 6),
                          Text('Here’s your financial snapshot', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 22),
                          BalanceCard(
                            title: 'Current Balance',
                            balance: _formatCurrency(_summary?.balance ?? 0),
                            income: _formatCurrency(_summary?.totalIncome ?? 0),
                            expense: _formatCurrency(_summary?.totalExpense ?? 0),
                          ),
                          const SizedBox(height: 20),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                QuickActionButton(
                                  icon: Icons.add_circle,
                                  label: 'Add',
                                  color: theme.colorScheme.primary,
                                  onTap: _openAddTransaction,
                                ),
                                const SizedBox(width: 12),
                                QuickActionButton(
                                  icon: Icons.list_alt,
                                  label: 'Transactions',
                                  color: theme.colorScheme.secondary,
                                  onTap: () async {
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                                    );
                                    if (changed == true) await _loadDashboard();
                                  },
                                ),
                                const SizedBox(width: 12),
                                QuickActionButton(
                                  icon: Icons.insights,
                                  label: 'Reports',
                                  color: Colors.deepPurpleAccent,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                                  },
                                ),
                                const SizedBox(width: 12),
                                QuickActionButton(
                                  icon: Icons.person,
                                  label: 'Profile',
                                  color: Colors.teal,
                                  onTap: _showProfileSheet,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Expense Summary', style: theme.textTheme.titleMedium),
                                      Text(_getDateFilterLabel(), style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ExpenseDonutChart(items: _categoryBreakdown),
                                  const SizedBox(height: 18),
                                  _buildCategoryList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Monthly Overview • LKR', style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 12),
                                  MonthlyBarChart(data: _monthlySummary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Recent Transactions', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          if (_transactions.isEmpty)
                            Text(
                              'No recent transactions. Add one to start tracking.',
                              style: theme.textTheme.bodyMedium,
                            )
                          else
                            ..._transactions.take(4).map(_buildRecentTransaction),
                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) async {
          if (index == 1) {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            );
            if (changed == true) await _loadDashboard();
          } else if (index == 2) {
            await _openAddTransaction();
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
          } else if (index == 4) {
            _showProfileSheet();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text('Member since 2026', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
