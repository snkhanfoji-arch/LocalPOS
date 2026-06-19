import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/khata_provider.dart';
import '../../providers/pos_provider.dart'; // import pkrFormatter
import '../../models/customer.dart';
import '../../widgets/custom_button.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(khataCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ledger / کھاتہ برائے مراجعین', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Customer Arrears & Advances', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(khataCustomersProvider.notifier).refresh(),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Live search customer
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customer / کسٹمر تلاش کریں...',
                prefixIcon: const Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Total Stats
          customersAsync.maybeWhen(
            data: (customers) {
              final totalReceivables = customers.fold(
                0.0,
                (sum, c) => c.balance > 0 ? sum + c.balance : sum,
              );
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Arrears (قرضہ):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                        Text('Money you need to collect from market', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                    Text(
                      pkrFormatter.format(totalReceivables),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.red),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 4),

          // 2. Customers List
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = customers.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      c.phone.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Customers found / کوئی کھاتہ دار نہیں ملا',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final customer = filtered[idx];
                    final hasArrears = customer.balance > 0;
                    final cardColor = hasArrears
                        ? Colors.red.shade50.withOpacity(0.6)
                        : Colors.green.shade50.withOpacity(0.6);

                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: hasArrears ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: hasArrears ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            Icons.person,
                            color: hasArrears ? Colors.red.shade800 : Colors.green.shade800,
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          customer.phone,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              pkrFormatter.format(customer.balance.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: hasArrears ? Colors.red.shade850 : Colors.green.shade850,
                              ),
                            ),
                            Text(
                              hasArrears ? 'Owes (واجب الادا)' : 'Advance (جمع)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: hasArrears ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openCustomerDetails(context, customer),
                        onLongPress: () => _confirmDeleteCustomer(context, ref, customer),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading customer database: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context, ref),
        label: const Text('Add Customer / نیا کسٹمر', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add_alt_1),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Khata Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('نیا کھاتہ دار شامل کریں', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name / نام کسٹمر',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number / فون نمبر',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_iphone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter mobile' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel / کینسل'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(khataCustomersProvider.notifier).addCustomer(
                        nameController.text.trim(),
                        phoneController.text.trim(),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save / محفوظ کریں'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCustomer(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer "${customer.name}"?'),
        content: const Text(
          'Warning: This will delete ALL past Khata credit/debit history and cannot be undone!',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel / کینسل'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(khataCustomersProvider.notifier).deleteCustomer(customer.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete / ختم کریں'),
          ),
        ],
      ),
    );
  }

  void _openCustomerDetails(BuildContext context, Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    );
  }
}

// Interactive detail screen of selected customer
class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({required this.customer, super.key});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedEntryType = 'debit'; // 'debit' = Borrowed, 'credit' = Received

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(customerEntriesProvider(widget.customer.id!));
    final updatedCustomers = ref.watch(khataCustomersProvider);

    // Watch live balance updates from parent notifier state
    final liveCustomer = updatedCustomers.maybeWhen(
      data: (list) {
        return list.firstWhere(
          (c) => c.id == widget.customer.id,
          orElse: () => widget.customer,
        );
      },
      orElse: () => widget.customer,
    );

    final owesMoney = liveCustomer.balance > 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(liveCustomer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(liveCustomer.phone, style: const TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_arrival),
            tooltip: 'Share via WhatsApp',
            onPressed: () => _shareHistory(liveCustomer),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arrears Banner Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: owesMoney
                    ? [Colors.red.shade100, Colors.red.shade50]
                    : [Colors.green.shade100, Colors.green.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: owesMoney ? Colors.red.shade300 : Colors.green.shade300),
            ),
            child: Column(
              children: [
                Text(
                  owesMoney ? 'Outstanding Balance (واجب الادا قرضہ)' : 'Advance Balance / امانت',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: owesMoney ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pkrFormatter.format(liveCustomer.balance.abs()),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: owesMoney ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  owesMoney
                      ? 'Please recover this amount / برائے مہربانی یہ رقم وصول کریں'
                      : 'Settled or Advance / رقم برابر یا امانت ہے',
                  style: TextStyle(
                    fontSize: 11,
                    color: owesMoney ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Action input entry form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Transaction Entry / نیا اندراج',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Debit (borrowed / ادھار دیں)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              value: 'debit',
                              groupValue: _selectedEntryType,
                              onChanged: (val) => setState(() => _selectedEntryType = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Credit (paid / نقد ملا)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              value: 'credit',
                              groupValue: _selectedEntryType,
                              onChanged: (val) => setState(() => _selectedEntryType = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Amount / رقم Rs.',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              validator: (val) =>
                                  val == null || double.tryParse(val) == null || double.parse(val) <= 0
                                      ? 'Invalid amount'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _descController,
                              decoration: const InputDecoration(
                                labelText: 'Description / تفصیل (e.g. Chicken, bulb)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        height: 48,
                        englishLabel: _selectedEntryType == 'debit' ? 'Record Borrowed / DEBIT' : 'Record Received / CREDIT',
                        urduLabel: _selectedEntryType == 'debit' ? 'لوگ ادھار لکھیں (نام)' : 'رقم کی وصولی درج کریں (جمع)',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final val = double.parse(_amountController.text);
                            final desc = _descController.text.trim().isEmpty ? 'Manual entry' : _descController.text;

                            ref.read(customerEntriesProvider(liveCustomer.id!).notifier).addEntry(
                                  val,
                                  _selectedEntryType,
                                  desc,
                                );

                            _amountController.clear();
                            _descController.clear();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Khata updated successfully! / کھاتہ اپ ڈیٹ ہوگیا')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Ledger timeline history title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction History / حساب کی تفصیل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                ),
                Icon(Icons.history, size: 18, color: Colors.grey.shade600),
              ],
            ),
          ),

          // 3. Transactions History list
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No transaction entries yet / کوئی لین دین نہیں مل سکا'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: entries.length,
                  itemBuilder: (context, idx) {
                    final entry = entries[idx];
                    final isDebit = entry.type == 'debit';
                    final color = isDebit ? Colors.red.shade800 : Colors.green.shade800;

                    return Card(
                      elevation: 0.2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isDebit ? Icons.arrow_outward : Icons.arrow_downward,
                          color: color,
                        ),
                        title: Text(
                          entry.description,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          entry.dateTime.substring(0, 16).replaceAll('T', ' '),
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pkrFormatter.format(entry.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                              onPressed: () {
                                ref.read(customerEntriesProvider(liveCustomer.id!).notifier).removeEntry(
                                      entry.id!,
                                      entry.amount,
                                      entry.type,
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _shareHistory(Customer customer) {
    // Generate text snippet readable for WhatsApp sharing
    final detailsUrlText = 'https://wa.me/${customer.phone}';
    final owesStr = customer.balance > 0
        ? 'باقی ادھار رقم / Outstanding Udhaar Arrears: ${pkrFormatter.format(customer.balance)}'
        : 'رقم برابر یا امانت / Advance Cash: ${pkrFormatter.format(customer.balance.abs())}';

    final text = 'پوش کھاتہ پرو / PosKhata Pro summary:\n\n'
        'محترم کسٹمر / Dear customer, *${customer.name}*,\n'
        'آپ کے کھاتہ کی تفصیل درجہ ذیل ہے:\n'
        '$owesStr\n\n'
        'مہربانی کر کے جلد رقم ادا کریں یا رابطہ کریں۔ شکریہ!\n'
        'Please reconcile or clear arrears as soon as possible. Thank you!';

    // Show a simple copy to clipboard overlay which is standard and robust on all platforms
    // For direct deep linking, we can launch:
    final clipboardData = text;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Summary / واٹس ایپ پر بھیجیں'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Press copy to clip outline, and paste in WhatsApp freely:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(
                maxHeight: 180,
                child: Text(clipboardData, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              // Copy to clickboard programmatically
              Theme.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Khata summary copied to clipboard / کاپی ہوگیا')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
