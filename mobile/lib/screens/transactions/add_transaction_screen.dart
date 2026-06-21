import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  String _transactionType = 'expense';
  String? _category;
  List<String> _subCategorySuggestions = [];
  bool _isLoadingSubCategories = false;
  bool _subCategorySuggestionsFailed = false;
  bool _isSaving = false;

  static const Map<String, List<String>> _categoryOptions = {
    'expense': [
      'Food',
      'Transport',
      'Bills',
      'Phone',
      'Shopping',
      'Health',
      'Education',
      'Other',
    ],
    'income': [
      'Salary',
      'Freelance',
      'Gift',
      'Investment',
      'Other',
    ],
  };

  @override
  void initState() {
    super.initState();
    _category = _categoryOptions[_transactionType]!.first;
    _loadSubCategorySuggestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSubCategorySuggestions() async {
    final category = _category;
    if (category == null || category.isEmpty) {
      setState(() {
        _subCategorySuggestions = [];
        _isLoadingSubCategories = false;
        _subCategorySuggestionsFailed = false;
      });
      return;
    }

    setState(() {
      _isLoadingSubCategories = true;
      _subCategorySuggestionsFailed = false;
      _subCategorySuggestions = [];
    });

    try {
      final suggestions = await _transactionService.getSubCategories(category);
      if (!mounted) return;
      setState(() {
        _subCategorySuggestions = suggestions;
        _isLoadingSubCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _subCategorySuggestions = [];
        _isLoadingSubCategories = false;
        _subCategorySuggestionsFailed = true;
      });
    }
  }

  void _setTransactionType(String value) {
    setState(() {
      _transactionType = value;
      _category = _categoryOptions[value]!.first;
      _subCategoryController.clear();
      _subCategorySuggestions = [];
      _subCategorySuggestionsFailed = false;
    });
    _loadSubCategorySuggestions();
  }

  void _setCategory(String value) {
    setState(() {
      _category = value;
      _subCategoryController.clear();
      _subCategorySuggestions = [];
      _subCategorySuggestionsFailed = false;
    });
    _loadSubCategorySuggestions();
  }

  Widget _buildSubCategorySuggestions() {
    if (_isLoadingSubCategories) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Loading sub categories...',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    if (_subCategorySuggestionsFailed) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Could not load suggestions. You can type manually.',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    if (_subCategorySuggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'No previous sub categories. Type a new one.',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _subCategorySuggestions.map((suggestion) {
          return ActionChip(
            label: Text(suggestion),
            onPressed: () {
              setState(() {
                _subCategoryController.text = suggestion;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnackbar('Please enter a valid amount greater than zero.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await _transactionService.createTransaction(
        title: _titleController.text.trim(),
        amount: amount,
        transactionType: _transactionType,
        category: _category!,
        subCategory: _subCategoryController.text.trim().isEmpty
            ? null
            : _subCategoryController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _showSnackbar('Transaction added successfully.');
        Navigator.pop(context, true);
        return;
      }

      final body = jsonDecode(response.body);
      final errorMessage = body is Map && body['detail'] != null
          ? body['detail'].toString()
          : 'Unable to save transaction. Please try again.';
      _showSnackbar(errorMessage);
    } catch (error) {
      _showSnackbar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryOptions[_transactionType]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required.';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter an amount greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Transaction Type'),
                initialValue: _transactionType,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _setTransactionType(value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                initialValue: _category,
                items: categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _setCategory(value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Sub Category (optional)',
                  hintText: 'e.g. Electricity, Phone bill, Freelance gig',
                ),
                maxLines: 1,
              ),
              _buildSubCategorySuggestions(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
