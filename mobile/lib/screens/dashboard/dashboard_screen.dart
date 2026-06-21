import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../models/analytics_models.dart';
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

  static const List<Map<String, String>> _dateFilterOptions = [
    {'key': 'this_month', 'label': 'This Month'},
    {'key': 'last_month', 'label': 'Last Month'},
    {'key': 'custom_range', 'label': 'Custom Range'},
  ];

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
    return NumberFormat.simpleCurrency(locale: 'en_US').format(value);
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

  Widget _buildDateFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dateFilterOptions.map((option) {
        final isSelected = option['key'] == _selectedDateFilter;
        return ChoiceChip(
          label: Text(option['label']!),
          selected: isSelected,
          onSelected: (_) => _setDateFilter(option['key']!),
        );
      }).toList(),
    );
  }

  Widget _buildPieChart() {
    if (_categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _categoryBreakdown.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0) {
      return const Center(child: Text('No expense data available for this period.'));
    }

    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sections: _categoryBreakdown.map((item) {
            final percentage = item.amount / total;
            return PieChartSectionData(
              value: item.amount,
              title: '${(percentage * 100).toStringAsFixed(0)}%',
              radius: 70,
              titleStyle: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_monthlySummary.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = _monthlySummary;
    final maxValue = items.isEmpty
        ? 1000.0
        : (items.map((e) => e.income > e.expense ? e.income : e.expense).reduce((a, b) => a > b ? a : b) * 1.2);

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue,
          barGroups: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(toY: item.income, color: Colors.green, width: 8),
                BarChartRodData(toY: item.expense, color: Colors.redAccent, width: 8),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildTopCategories() {
    if (_categoryBreakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No category breakdown available.'),
      );
    }

    final topCategories = List.of(_categoryBreakdown)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topCategories.take(3).map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(item.category)),
              Text(_formatCurrency(item.amount)),
            ],
          ),
        );
      }).toList(),
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
                        'Analytics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date Range',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              _buildDateFilterChips(),
                              const SizedBox(height: 12),
                              Text(
                                'Selected: ${_getDateFilterLabel()}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'Expense Breakdown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _categoryBreakdown.isEmpty
                              ? Text(
                                  'No expense breakdown available for this period.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              : _buildPieChart(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Monthly Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _monthlySummary.isEmpty
                              ? Text(
                                  'No monthly summary available for this period.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              : _buildBarChart(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Top Categories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildTopCategories(),
                        ),
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
