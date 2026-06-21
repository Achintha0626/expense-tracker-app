import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/transaction_service.dart';
import '../../models/transaction_item.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/transaction_card.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _service = TransactionService();
  final TextEditingController _searchController = TextEditingController();

  List<TransactionItem> _items = [];
  List<String> _categories = [];
  List<String> _subCategories = [];
  bool _isLoading = true;
  String? _error;
  String _filterType = ''; // '', 'income', 'expense'
  String? _selectedCategory;
  String? _selectedSubCategory;
  String _selectedDateFilter = 'all_time';
  DateTime? _startDate;
  DateTime? _endDate;

  static const List<Map<String, String>> _dateFilterOptions = [
    {'key': 'all_time', 'label': 'All Time'},
    {'key': 'today', 'label': 'Today'},
    {'key': 'this_week', 'label': 'This Week'},
    {'key': 'this_month', 'label': 'This Month'},
    {'key': 'last_month', 'label': 'Last Month'},
    {'key': 'custom_range', 'label': 'Custom Range'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFiltersAndTransactions();
  }

  Future<void> _loadFiltersAndTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _service.getCategories();
      final items = await _service.getTransactions(
        type: _filterType.isEmpty ? null : _filterType,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        page: 1,
        limit: 50,
      );
      setState(() {
        _categories = categories;
        _items = items;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.getTransactions(
        type: _filterType.isEmpty ? null : _filterType,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        search: search,
        startDate: _startDate,
        endDate: _endDate,
        page: 1,
        limit: 50,
      );
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async => _load(search: _searchController.text.trim());

  Future<void> _onCategoryChanged(String? newCategory) async {
    setState(() {
      _selectedCategory = newCategory;
      _selectedSubCategory = null;
      _subCategories = [];
      _isLoading = true;
      _error = null;
    });

    if (newCategory != null && newCategory.isNotEmpty) {
      try {
        final subCategories = await _service.getSubCategories(newCategory);
        setState(() => _subCategories = subCategories);
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }

    await _load(search: _searchController.text.trim());
  }

  Future<void> _onSubCategoryChanged(String? newSubCategory) async {
    setState(() {
      _selectedSubCategory = newSubCategory;
    });
    await _load(search: _searchController.text.trim());
  }

  String _getDateFilterLabel() {
    switch (_selectedDateFilter) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
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
        return 'All Time';
    }
  }

  Future<void> _setDateFilter(String key) async {
    final now = DateTime.now();

    if (key == 'custom_range') {
      final selectedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1),
        initialDateRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
      );

      if (selectedRange == null) {
        return;
      }

      setState(() {
        _selectedDateFilter = 'custom_range';
        _startDate = selectedRange.start;
        _endDate = selectedRange.end;
      });
    } else {
      DateTime start;
      DateTime end;

      if (key == 'today') {
        start = DateTime(now.year, now.month, now.day);
        end = start;
      } else if (key == 'this_week') {
        start = now.subtract(Duration(days: now.weekday - 1));
        end = DateTime(now.year, now.month, now.day);
      } else if (key == 'this_month') {
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month, now.day);
      } else if (key == 'last_month') {
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(lastMonthStart.year, lastMonthStart.month + 1, 0);
        start = lastMonthStart;
        end = lastMonthEnd;
      } else {
        start = DateTime(now.year - 100);
        end = DateTime(now.year + 100);
      }

      setState(() {
        _selectedDateFilter = key;
        _startDate = start;
        _endDate = end;
      });
    }

    await _load(search: _searchController.text.trim());
  }

  void _clearFilters() {
    setState(() {
      _filterType = '';
      _selectedCategory = null;
      _selectedSubCategory = null;
      _selectedDateFilter = 'all_time';
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
    _load();
  }

  Future<void> _onDelete(TransactionItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _isLoading = true);
    try {
      await _service.deleteTransaction(item.id);
      _showSnackbar('Transaction deleted');
      await _load(search: _searchController.text.trim());
    } catch (e) {
      _showSnackbar(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onEdit(TransactionItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: item)),
    );

    if (changed == true) {
      await _load(search: _searchController.text.trim());
    }
  }

  void _openDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  Future<void> _openAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );

    if (added == true) {
      await _load(search: _searchController.text.trim());
    }
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
    if (index == 0) {
      _openDashboard();
    } else if (index == 2) {
      await _openAdd();
    } else if (index == 3) {
      _openReports();
    } else if (index == 4) {
      _openProfile();
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildItem(TransactionItem t) {
    return TransactionCard(
      transaction: t,
      onEdit: () => _onEdit(t),
      onDelete: () => _onDelete(t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilters = [
      if (_filterType.isNotEmpty) 'Type: ${_filterType[0].toUpperCase()}${_filterType.substring(1)}',
      if (_selectedCategory != null) 'Category: $_selectedCategory',
      if (_selectedSubCategory != null) 'Sub Category: $_selectedSubCategory',
    ];

    return AppScaffold(
      title: 'Transactions',
      currentIndex: 1,
      onNavTap: _handleNavTap,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (v) => _load(search: v.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _load(search: _searchController.text.trim()),
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Category'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCategory,
                          hint: const Text('All categories'),
                          items: _categories
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: _onCategoryChanged,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Sub Category'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedSubCategory,
                          hint: const Text('All sub categories'),
                          items: _subCategories
                              .map((sub) => DropdownMenuItem(
                                    value: sub,
                                    child: Text(sub),
                                  ))
                              .toList(),
                          onChanged: _selectedCategory == null ? null : _onSubCategoryChanged,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filters (${selectedFilters.length + (_selectedDateFilter != 'all_time' ? 1 : 0)})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _dateFilterOptions.map((option) {
                        final isSelected = option['key'] == _selectedDateFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(option['label']!),
                            selected: isSelected,
                            onSelected: (_) => _setDateFilter(option['key']!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedDateFilter != 'all_time')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(_getDateFilterLabel()),
                      ),
                    ),
                ],
              ),
            ),
            if (selectedFilters.isNotEmpty || _selectedDateFilter != 'all_time')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...selectedFilters.map((filter) => Text(filter)),
                    if (_selectedDateFilter != 'all_time')
                      Text('Date: ${_getDateFilterLabel()}'),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _error!,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                            Center(
                              child: ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            )
                          ],
                        )
                      : _items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                                      const SizedBox(height: 12),
                                      Text('No transactions found', style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 8),
                                      const Text('Add transactions from the dashboard.'),
                                    ],
                                  ),
                                )
                              ],
                            )
                          : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (_, i) => _buildItem(_items[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
