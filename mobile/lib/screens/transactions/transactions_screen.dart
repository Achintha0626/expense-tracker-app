import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/transaction_service.dart';
import '../../models/transaction_item.dart';
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

  void _clearFilters() {
    setState(() {
      _filterType = '';
      _selectedCategory = null;
      _selectedSubCategory = null;
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

  String _formatCurrency(double value, bool isExpense) {
    final formatted = NumberFormat.simpleCurrency(locale: 'en_US').format(value);
    return isExpense ? '-$formatted' : '+$formatted';
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildItem(TransactionItem t) {
    final categoryText = t.subCategory != null && t.subCategory!.isNotEmpty
        ? '${t.category} • ${t.subCategory}'
        : t.category;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(t.title),
        subtitle: Text('$categoryText • ${DateFormat.yMMMd().format(t.transactionDate)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCurrency(t.amount, t.isExpense),
              style: TextStyle(
                color: t.isExpense ? Colors.redAccent : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _onEdit(t),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _onDelete(t),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilters = [
      if (_filterType.isNotEmpty) 'Type: ${_filterType[0].toUpperCase()}${_filterType.substring(1)}',
      if (_selectedCategory != null) 'Category: $_selectedCategory',
      if (_selectedSubCategory != null) 'Sub Category: $_selectedSubCategory',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters (${selectedFilters.length})',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),
            if (selectedFilters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedFilters.map((filter) => Text(filter)).toList(),
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
