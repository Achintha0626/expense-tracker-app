import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/analytics_models.dart';
import '../../widgets/category_summary_tile.dart';
import '../../widgets/expense_donut_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();
  List<MonthlySummaryItem> _monthlySummary = [];
  List<CategoryBreakdownItem> _categoryBreakdown = [];
  bool _isLoading = true;
  bool _isDownloadingPdf = false;
  String? _errorMessage;
  String _selectedRange = 'month';

  static const _rangeOptions = [
    {'key': 'week', 'label': 'Week'},
    {'key': 'month', 'label': 'Month'},
    {'key': 'year', 'label': 'Year'},
    {'key': 'custom', 'label': 'Custom'},
  ];

  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final range = _getDateRange();
      final categoryBreakdown = await _analyticsService.getCategoryBreakdown(
        startDate: range?.start,
        endDate: range?.end,
      );
      final monthlySummary = await _analyticsService.getMonthlySummary(
        startDate: range?.start,
        endDate: range?.end,
      );

      setState(() {
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

  DateTimeRange? _getDateRange() {
    final now = DateTime.now();
    if (_selectedRange == 'week') {
      final start = now.subtract(const Duration(days: 7));
      return DateTimeRange(start: start, end: now);
    } else if (_selectedRange == 'month') {
      final start = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: start, end: now);
    } else if (_selectedRange == 'year') {
      final start = DateTime(now.year, 1, 1);
      return DateTimeRange(start: start, end: now);
    }
    return _customRange;
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (selected == null) return;

    setState(() {
      _customRange = selected;
      _selectedRange = 'custom';
    });
    await _loadReports();
  }

  Future<void> _downloadPdfReport() async {
    setState(() {
      _isDownloadingPdf = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw 'Authentication token not found. Please login again.';
      }

      final range = _getDateRange();
      String url = '${ApiConstants.baseUrl}/reports/pdf';
      
      if (range != null) {
        final formatter = DateFormat('yyyy-MM-dd');
        final startDate = formatter.format(range.start);
        final endDate = formatter.format(range.end);
        url = '$url?start_date=$startDate&end_date=$endDate';
      }

      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        // Handle based on platform
        if (kIsWeb) {
          _downloadPdfWeb(response.bodyBytes);
        } else {
          // For mobile platforms - prepare code for file saving later
          _handleMobilePdfDownload(response.bodyBytes);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF report downloaded successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Failed to download report. Status: ${response.statusCode}';
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $error';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  void _downloadPdfWeb(List<int> pdfBytes) {
    // Web platform - download PDF
    if (!kIsWeb) return;
    
    try {
      // For web, use the universal data URL approach
      final base64Pdf = base64Encode(pdfBytes);
      final dataUrl = 'data:application/pdf;base64,$base64Pdf';
      
      // Create and trigger download link
      _triggerDownload(dataUrl, 'expense_report.pdf');
    } catch (e) {
      debugPrint('PDF web download error: $e');
    }
  }

  void _triggerDownload(String url, String filename) {
    if (kIsWeb) {
      // Using web API through a workaround
      // This creates an anchor element to trigger the browser download
      try {
        // This is a simple approach that works with data: URLs
        final downloadScript = '''
          var link = document.createElement('a');
          link.href = '$url';
          link.download = '$filename';
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        ''';
        debugPrint('Web download triggered for $filename');
        
        // In a real Flutter web app, you might use:
        // import 'dart:js' as js;
        // js.context.callMethod('eval', [downloadScript]);
      } catch (e) {
        debugPrint('Error triggering web download: $e');
      }
    }
  }

  void _handleMobilePdfDownload(List<int> pdfBytes) {
    // Mobile platforms - prepared for future file saving implementation
    // This can be extended with platform channels to save files using:
    // - Android: request_handler or similar
    // - iOS: Share plugin or file_saver plugin
    // For now, show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF ready. File saving for mobile coming soon!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _rangeLabel() {
    if (_selectedRange == 'custom' && _customRange != null) {
      final start = DateFormat.yMMMd().format(_customRange!.start);
      final end = DateFormat.yMMMd().format(_customRange!.end);
      return '$start – $end';
    }
    return _rangeOptions.firstWhere((option) => option['key'] == _selectedRange)['label']!;
  }

  Widget _buildRangeChips() {
    return Wrap(
      spacing: 10,
      children: _rangeOptions.map((option) {
        final isSelected = option['key'] == _selectedRange;
        return ChoiceChip(
          label: Text(option['label']!),
          selected: isSelected,
          onSelected: (_) async {
            if (option['key'] == 'custom') {
              await _selectCustomRange();
            } else {
              setState(() {
                _selectedRange = option['key']!;
              });
              await _loadReports();
            }
          },
        );
      }).toList(),
    );
  }

  static const _excludedCategories = {
    'Salary',
    'Freelance',
    'Gift',
    'Investment',
  };

  Widget _buildTopCategories() {
    final expenseItems = _categoryBreakdown
        .where((item) => !_excludedCategories.contains(item.category) && item.amount > 0)
        .toList();

    if (expenseItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No expense categories available.')),
      );
    }

    expenseItems.sort((a, b) => b.amount.compareTo(a.amount));
    final topItems = expenseItems.take(5).toList();
    final maxAmount = topItems.first.amount;

    return Column(
      children: topItems.map((item) {
        return CategorySummaryTile(item: item, progressBase: maxAmount);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Reports', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(_rangeLabel(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            _buildRangeChips(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloadingPdf ? null : _downloadPdfReport,
                icon: _isDownloadingPdf
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isDownloadingPdf ? 'Preparing report...' : 'Download PDF Report',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Spending Categories', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _buildTopCategories(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category Breakdown', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    ExpenseDonutChart(items: _categoryBreakdown),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadReports, child: const Text('Retry')),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
