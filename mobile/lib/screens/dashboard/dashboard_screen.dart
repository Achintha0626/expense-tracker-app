import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../models/analytics_models.dart';
import '../../models/dashboard_summary.dart';
import '../../models/transaction_item.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/category_summary_tile.dart';
import '../../widgets/expense_donut_chart.dart';
import '../../widgets/monthly_bar_chart.dart';
import '../../widgets/recent_transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AnalyticsService _analyticsService = AnalyticsService();

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

  void _openTransactions() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
    );
  }

  void _openReports() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ReportsScreen()),
    );
  }

  void _openProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _handleNavTap(int index) async {
    if (index == 1) {
      _openTransactions();
    } else if (index == 2) {
      await _openAddTransaction();
    } else if (index == 3) {
      _openReports();
    } else if (index == 4) {
      _openProfile();
    }
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
    return NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ').format(value);
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
    final body = RefreshIndicator(
      onRefresh: _loadDashboard,
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
                            Text('Monthly Overview • Rs.', style: theme.textTheme.titleMedium),
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
    );

    return AppScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      onNavTap: _handleNavTap,
      body: body,
    );
  }
}
