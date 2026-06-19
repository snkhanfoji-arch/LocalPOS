import 'dart:io';
import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/pos_provider.dart'; // import pkrFormatter
import '../../providers/khata_provider.dart';
import '../../services/db_service.dart';
import '../../models/sale.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../widgets/custom_button.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalesHistory();
  }

  Future<void> _loadSalesHistory() async {
    setState(() => _isLoading = true);
    final sales = await DbService.instance.getAllSales();
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(khataCustomersProvider);
    final productsAsync = ref.watch(posProductsProvider);

    // Filter today's sales
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // 'YYYY-MM-DD'
    final todaySales = _sales.where((s) => s.dateTime.startsWith(todayStr)).toList();
    final todaySalesTotal = todaySales.fold(0.0, (sum, s) => sum + s.total);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Analytics / رپورٹ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Daily Sales, Khata & CSV Exports', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSalesHistory();
              ref.invalidate(posProductsProvider);
              ref.read(khataCustomersProvider.notifier).refresh();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row of Daily figures
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on, size: 48, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Sales / نقد فروخت آج کی",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pkrFormatter.format(todaySalesTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Completed Invoices: ${todaySales.length}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Khata Receivables Sum card
                  customersAsync.when(
                    data: (customers) {
                      final totalArrears = customers.fold(
                        0.0,
                        (sum, c) => c.balance > 0 ? sum + c.balance : sum,
                      );
                      final totalAdvances = customers.fold(
                        0.0,
                        (sum, c) => c.balance < 0 ? sum + c.balance.abs() : sum,
                      );

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.menu_book, color: Colors.indigo),
                                  SizedBox(width: 10),
                                  Text(
                                    'Khata Summary / کھاتہ خلاصہ',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _sumItemCol(
                                      'Credit Accounts (Advances)',
                                      'پیشگی وصولیاں / امانتیں',
                                      pkrFormatter.format(totalAdvances),
                                      Colors.green,
                                    ),
                                  ),
                                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                                  Expanded(
                                    child: _sumItemCol(
                                      'Debit Accounts (Arrears)',
                                      'باقی بازار ادھار',
                                      pkrFormatter.format(totalArrears),
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading khata overview'),
                  ),

                  const SizedBox(height: 12),

                  // Stock Summary alert
                  productsAsync.when(
                    data: (products) {
                      final lowStockCount = products.where((p) => p.stock <= p.lowStockThreshold).length;
                      final totalItems = products.length;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: lowStockCount > 0 ? Colors.red.shade100 : Colors.green.shade100,
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: lowStockCount > 0 ? Colors.red.shade800 : Colors.green.shade800,
                            ),
                          ),
                          title: const Text('Stock Alerts / اسٹاک صورتحال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            '$lowStockCount out of $totalItems products are running extremely low.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: lowStockCount > 0 ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              lowStockCount > 0 ? 'ALERT / جلدی لائیں' : 'OK / تسلی بخش',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: lowStockCount > 0 ? Colors.red.shade900 : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error syncing catalog'),
                  ),

                  const SizedBox(height: 16),

                  // Row of CSV Export buttons
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'Report Data Export Center (CSV)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          height: 56,
                          icon: Icons.upload_file_outlined,
                          englishLabel: 'Export Sales CSV',
                          urduLabel: 'فروخت رپورٹ ایکسپورٹ',
                          onPressed: () => _exportSalesCSV(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          height: 56,
                          icon: Icons.contacts_outlined,
                          englishLabel: 'Export Ledger CSV',
                          urduLabel: 'کھاتہ بک ایکسپورٹ بالعموم',
                          backgroundColor: Colors.indigo,
                          onPressed: () => _exportKhataCSV(context, ref),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sumItemCol(String label, String urdu, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(urdu, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ],
    );
  }

  Future<void> _exportSalesCSV(BuildContext context) async {
    try {
      final csvBuffer = StringBuffer();
      // Add CSV Headers
      csvBuffer.writeln('Sale ID,DateTime,Total Amount,Discount %,Tax %,Customer ID,Subtotal');

      for (var sale in _sales) {
        csvBuffer.writeln(
          '${sale.id},"${sale.dateTime}",${sale.total},${sale.discountPercentage},${sale.taxPercentage},${sale.customerId ?? "CASH"},${sale.subtotal}',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvBuffer.toString());

      _showSuccessDialog(context, 'Sales Report Exported', path);
    } catch (e) {
      _showErrorDialog(context, 'Export failed: $e');
    }
  }

  Future<void> _exportKhataCSV(BuildContext context, WidgetRef ref) async {
    try {
      final customersAsync = ref.read(khataCustomersProvider);
      final customers = customersAsync.maybeWhen(
        data: (list) => list,
        orElse: () => <Customer>[],
      );

      if (customers.isEmpty) {
        throw Exception('No customers found to export');
      }

      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Customer ID,Name,Phone,Outstanding Arrears (PKR)');

      for (var c in customers) {
        csvBuffer.writeln('${c.id},"${c.name}","${c.phone}",${c.balance}');
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/khata_ledger_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvBuffer.toString());

      _showSuccessDialog(context, 'Khata Ledger Exported', path);
    } catch (e) {
      _showErrorDialog(context, 'Export failed: $e');
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your file was downloaded and saved securely on local storage:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(path, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error exporting reports'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss')),
        ],
      ),
    );
  }
}
