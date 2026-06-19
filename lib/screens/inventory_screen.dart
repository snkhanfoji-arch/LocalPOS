import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pos_provider.dart'; // loads posProductsProvider
import '../../models/product.dart';
import '../../services/db_service.dart';
import '../../widgets/custom_button.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(posProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Catalog / گودام اور اسٹاک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Chicken & Electrical Spares', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
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
                hintText: 'Search stock Catalog (Name or Barcode)...',
                prefixIcon: const Icon(Icons.inventory_outlined),
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

          // 2. Category Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['All', 'Chicken', 'Electrical'].map((cat) {
                final isSel = _selectedCategoryFilter == cat;
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
                        _selectedCategoryFilter = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 3. Products/Stock List
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) {
                  final matchesCat = _selectedCategoryFilter == 'All' || p.category == _selectedCategoryFilter;
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.barcode.contains(_searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No catalog products / کوئی چیز درج نہیں ہے'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final product = filtered[idx];
                    final isLowStock = product.stock <= product.lowStockThreshold;

                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: isLowStock
                            ? BorderSide(color: theme.colorScheme.error, width: 1.5)
                            : BorderSide(color: Colors.transparent),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: product.category == 'Chicken'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                          child: Icon(
                            product.category == 'Chicken'
                                ? Icons.shopping_basket_outlined
                                : Icons.bolt_outlined,
                            color: product.category == 'Chicken'
                                ? Colors.red.shade800
                                : Colors.blue.shade800,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Barcode: ${product.barcode}', style: const TextStyle(fontSize: 11)),
                            Text(
                              'Price: ${pkrFormatter.format(product.price)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${product.stock.toStringAsFixed(1)} remaining',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isLowStock ? theme.colorScheme.error : Colors.green.shade800,
                                  ),
                                ),
                                if (isLowStock)
                                  Text(
                                    'Low Alert / اسٹاک ختم',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Quick Adjustment stock-in / stock-out triggers
                            IconButton(
                              icon: const Icon(Icons.add_box_outlined, color: Colors.indigo),
                              onPressed: () => _showQuickStockAdjustDialog(context, ref, product, isAdd: true),
                            ),
                            // Action options edit/delete
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showProductFormBottomSheet(context, ref, product: product);
                                } else if (val == 'delete') {
                                  _confirmDeleteProduct(context, ref, product);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit / تدوین')],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete')],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading inventory: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductFormBottomSheet(context, ref),
        label: const Text('Add Product / نیا مال', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_to_photos_outlined),
      ),
    );
  }

  void _showQuickStockAdjustDialog(BuildContext context, WidgetRef ref, Product product, {required bool isAdd}) {
    final qtyController = TextEditingController();
    final verb = isAdd ? 'Stock IN (خریداری)' : 'Stock OUT (کمی)';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$verb - ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current stock: ${product.stock.toStringAsFixed(1)} units'),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity / وزن یا تعداد',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel / کینسل'),
            ),
            ElevatedButton(
              onPressed: () {
                final input = double.tryParse(qtyController.text) ?? 0.0;
                if (input > 0) {
                  final newStock = isAdd ? product.stock + input : product.stock - input;
                  DbService.instance.updateProductStock(product.id!, newStock);
                  ref.invalidate(posProductsProvider);
                  Navigator.pop(context);
                }
              },
              child: const Text('Confirm / تصدیق کریں'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${product.name}"?'),
        content: const Text('This will delete the product record from stock database permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              DbService.instance.deleteProduct(product.id!);
              ref.invalidate(posProductsProvider);
              Navigator.pop(context);
            },
            child: const Text('Delete / ختم کریں'),
          )
        ],
      ),
    );
  }

  void _showProductFormBottomSheet(BuildContext context, WidgetRef ref, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ProductFormSheet(product: product),
        );
      },
    );
  }
}

// Interactive bottom sheet to Add or Edit details
class ProductFormSheet extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormSheet({this.product, super.key});

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  late String _category;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toString() : '');
    _stockController = TextEditingController(text: p != null ? p.stock.toString() : '');
    _thresholdController = TextEditingController(text: p != null ? p.lowStockThreshold.toString() : '5.0');
    _category = p?.category ?? 'Chicken';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.product != null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text(
                isEdit ? 'Edit Product Directory / تدوین مصنوعات' : 'Add New Product / نیا آئٹم درج کریں',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Product Name (bilingual labels / Urdu placeholder)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name / نام چیز',
                  placeholder: 'e.g. Broiler Chicken, Bulb 12W',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Barcode
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode ID / کوڈ نمبر',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code),
                          onPressed: () async {
                            final code = await FlutterBarcodeScanner.scanBarcode('#FF6666', 'Cancel', true, ScanMode.BARCODE);
                            if (code != '-1') setState(() => _barcodeController.text = code);
                          },
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter barcode or custom number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category selector
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category / کیٹگری', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Chicken', child: Text('Chicken / چکن')),
                        DropdownMenuItem(value: 'Electrical', child: Text('Electric / بجلی')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _category = val!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  // Sale Price
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Selling Price / فروخت قیمت', border: OutlineInputBorder(), prefixText: 'Rs. '),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Initial/Current Stock
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Initial Stock / اسٹاک وزن', border: OutlineInputBorder()),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid stock' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Low Stock Warning Threshold
              TextFormField(
                controller: _thresholdController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Low Stock Alert Level / وارننگ لیول',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid threshold' : null,
              ),

              const SizedBox(height: 18),

              CustomButton(
                englishLabel: isEdit ? 'Update Details' : 'Save Product to DB',
                urduLabel: isEdit ? 'تبدیلیاں محفوظ کریں' : 'ڈیٹا بیس میں محفوظ کریں',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final product = Product(
                      id: widget.product?.id,
                      name: _nameController.text.trim(),
                      barcode: _barcodeController.text.trim(),
                      price: double.parse(_priceController.text),
                      stock: double.parse(_stockController.text),
                      category: _category,
                      lowStockThreshold: double.parse(_thresholdController.text),
                    );

                    if (isEdit) {
                      await DbService.instance.updateProduct(product);
                    } else {
                      await DbService.instance.insertProduct(product);
                    }

                    ref.invalidate(posProductsProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Product updated!' : 'Product added successfully!')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
