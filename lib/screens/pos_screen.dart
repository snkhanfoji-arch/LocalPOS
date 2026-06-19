import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pos_provider.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../widgets/product_card.dart';
import '../../widgets/cart_item.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(posProductsProvider);
    final cartState = ref.watch(posProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POS Registry / پوائنٹ آف سیل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Chicken & Electrical Retail', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode / بارکوڈ اسکین',
            onPressed: () => _scanBarcode(ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(posProductsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Product / تلاش کریں (Name or Barcode)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // 2. Category Selector Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['All', 'Chicken', 'Electrical'].map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      cat == 'All'
                          ? 'All / تمام'
                          : cat == 'Chicken'
                              ? 'Chicken / چکن'
                              : 'Electric / بجلی',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? theme.colorScheme.onPrimary : null),
                    ),
                    selected: isSel,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: theme.colorScheme.onPrimary,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 3. Grid representation of items
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) {
                  final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.barcode.contains(_searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found / کوئی چیز نہیں ملی',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.76,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final prod = filtered[idx];
                    return ProductCard(
                      product: prod,
                      onAdd: () {
                        ref.read(posProvider.notifier).addToCart(prod);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${prod.name} / شامل کرلیا گیا'),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      },
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

      // 4. Cart Bottom Sheet trigger
      bottomNavigationBar: cartState.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cartState.items.length} items / اشیاء',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          pkrFormatter.format(cartState.total),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showCartBottomSheet(context),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text(
                        'View Cart / ٹوکری دیکھیں',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _scanBarcode(WidgetRef ref) async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcode != '-1' && barcode.isNotEmpty) {
        final productsAsync = ref.read(posProductsProvider);
        productsAsync.whenData((prods) {
          final found = prods.firstWhere(
            (p) => p.barcode == barcode,
            orElse: () => throw Exception('Product code not found'),
          );
          ref.read(posProvider.notifier).addToCart(found);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${found.name} / بارکوڈ سے شامل کیا گیا')),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification / Barcode error: No scanner found')),
      );
    }
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return const CartBottomSheetContent();
      },
    );
  }
}

// Separate StatefulWidget for inside the BottomSheet to manage state smoothly
class CartBottomSheetContent extends ConsumerStatefulWidget {
  const CartBottomSheetContent({super.key});

  @override
  ConsumerState<CartBottomSheetContent> createState() => _CartBottomSheetContentState();
}

class _CartBottomSheetContentState extends ConsumerState<CartBottomSheetContent> {
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cart = ref.read(posProvider);
    _discountController.text = cart.discountPercentage.toInt().toString();
    _taxController.text = cart.taxPercentage.toInt().toString();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = ref.watch(posProvider);
    final customersAsync = ref.watch(posCustomersProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header indicator
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cart / بل کے اشیاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Customize tax, customer, discount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: () {
                      ref.read(posProvider.notifier).clearCart();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear / خالی کریں'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Items
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: cartState.items.length,
                  itemBuilder: (context, idx) {
                    final item = cartState.items.values.toList()[idx];
                    return CartItemWidget(
                      item: item,
                      onQuantityChanged: (qty) {
                        ref.read(posProvider.notifier).updateQuantity(item.id, qty);
                      },
                      onRemove: () {
                        ref.read(posProvider.notifier).removeFromCart(item.id);
                      },
                    );
                  },
                ),
              ),

              const Divider(),

              // Configs (Customer, Discount, Tax)
              Row(
                children: [
                  // Bind to Customer (Khata)
                  Expanded(
                    child: customersAsync.when(
                      data: (customers) {
                        return DropdownButtonFormField<int?>(
                          value: cartState.selectedCustomerId,
                          decoration: InputDecoration(
                            labelText: 'Link Khata Customer / کھاتہ',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Cash Customer / نقد کسٹمر'),
                            ),
                            ...customers.map((c) => DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text('${c.name} (${c.phone})'),
                                )),
                          ],
                          onChanged: (val) {
                            ref.read(posProvider.notifier).selectCustomer(val);
                          },
                        );
                      },
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (_, __) => const Text('Error loading customers'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  // Discount Input
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount % / ڈسکاؤنٹ',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        final limit = double.tryParse(val) ?? 0.0;
                        ref.read(posProvider.notifier).setDiscount(limit);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tax Input
                  Expanded(
                    child: TextField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tax % / ٹیکس',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        final limit = double.tryParse(val) ?? 0.0;
                        ref.read(posProvider.notifier).setTax(limit);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Invoice calculations
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _sumRow('Subtotal / کل قیمت:', pkrFormatter.format(cartState.subtotal)),
                    if (cartState.discountAmount > 0)
                      _sumRow('Discount / ڈسکاؤنٹ کم کی:', '- ${pkrFormatter.format(cartState.discountAmount)}', color: Colors.green),
                    if (cartState.taxAmount > 0)
                      _sumRow('Tax / ٹیکس:', '+ ${pkrFormatter.format(cartState.taxAmount)}', color: Colors.red),
                    const Divider(),
                    _sumRow(
                      'Net Total / کل واجب الادا:',
                      pkrFormatter.format(cartState.total),
                      isBold: true,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Print Receipt and Save Checkout Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        onPressed: () async {
                          final processedSale = await ref.read(posProvider.notifier).checkout();
                          if (processedSale != null) {
                            ref.invalidate(posProductsProvider); // Refresh stock states
                            Navigator.pop(context);
                            // Generate and print invoice instantly
                            final bytes = await PdfService.generate80mmThermalBill(processedSale);
                            await Printing.layoutPdf(
                              onLayout: (_) => bytes,
                              name: 'Bill-${processedSale.id}.pdf',
                            );
                          }
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Checkout & Print', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('بل پرنٹ کریں', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          final processedSale = await ref.read(posProvider.notifier).checkout();
                          if (processedSale != null) {
                            ref.invalidate(posProductsProvider); // Refresh stock states
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invoice saved successfully! ID: POS-${processedSale.id}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Save Cash / محفوظ کریں', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('No Print', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sumRow(String label, String value, {bool isBold = false, Color? color, double size = 13}) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
