import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/transaction_service.dart';
import '../../models/transaction_item.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionItem transaction;
  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _subCategoryController;
  late TextEditingController _descriptionController;
  final TransactionService _service = TransactionService();

  String _transactionType = 'expense';
  String? _category;
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
    final t = widget.transaction;
    _titleController = TextEditingController(text: t.title);
    _amountController = TextEditingController(text: t.amount.toString());
    _subCategoryController = TextEditingController(text: t.subCategory ?? '');
    _descriptionController = TextEditingController(text: t.description ?? '');
    _transactionType = t.transactionType;
    _category = _categoryOptions[_transactionType]!.contains(t.category) ? t.category : _categoryOptions[_transactionType]!.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _subCategoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnackbar('Please enter a valid amount greater than zero.');
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'title': _titleController.text.trim(),
      'amount': amount,
      'transaction_type': _transactionType,
      'category': _category,
      'sub_category': _subCategoryController.text.trim().isEmpty ? null : _subCategoryController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    };

    try {
      final response = await _service.updateTransaction(widget.transaction.id, payload);
      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSnackbar('Transaction updated');
        Navigator.pop(context, true);
        return;
      }

      final body = jsonDecode(response.body);
      final errorMessage = body is Map && body['detail'] != null ? body['detail'].toString() : 'Unable to update transaction.';
      _showSnackbar(errorMessage);
    } catch (e) {
      _showSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryOptions[_transactionType]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount is required.';
                  final p = double.tryParse(v.trim());
                  if (p == null || p <= 0) return 'Enter an amount greater than zero.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Transaction Type'),
                initialValue: _transactionType,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _transactionType = value;
                    _category = _categoryOptions[value]!.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                initialValue: _category,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Category is required.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subCategoryController,
                decoration: const InputDecoration(labelText: 'Sub Category (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
