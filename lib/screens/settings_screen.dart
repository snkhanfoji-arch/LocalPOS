import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  final _taxController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPreferences();
  }

  Future<void> _loadStoredPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('shop_name') ?? 'PosKhata Pro Shop';
      _addressController.text = prefs.getString('shop_address') ?? 'Main Bazaar, Pakistan';
      _phoneController.text = prefs.getString('shop_phone') ?? '0300-1234567';
      _headerController.text = prefs.getString('bill_header') ?? 'SALES RECEIPT / رسید';
      _footerController.text = prefs.getString('bill_footer') ?? 'Thank you for your business!\nدوبارہ تشریف لائیں۔ شکرية!';
      _taxController.text = (prefs.getDouble('default_tax_rate') ?? 5.0).toString();
    });
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('shop_name', _nameController.text.trim());
    await prefs.setString('shop_address', _addressController.text.trim());
    await prefs.setString('shop_phone', _phoneController.text.trim());
    await prefs.setString('bill_header', _headerController.text.trim());
    await prefs.setString('bill_footer', _footerController.text.trim());
    await prefs.setDouble('default_tax_rate', double.parse(_taxController.text));

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved successfully! / سیٹنگز محفوظ ہوگئیں')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings / ترتیبات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Shop details, Print config & Color theme', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Color Palette selector
              const Text(
                'Select Application Theme / رنگ کا انتخاب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ThemeOption.values.map((opt) {
                  final isSel = currentTheme == opt;
                  String label = opt.name.toUpperCase();
                  Color btnColor = Colors.grey;

                  if (opt == ThemeOption.light) btnColor = Colors.indigo;
                  if (opt == ThemeOption.dark) btnColor = Colors.black54;
                  if (opt == ThemeOption.blue) btnColor = Colors.blue;
                  if (opt == ThemeOption.green) btnColor = Colors.green;
                  if (opt == ThemeOption.orange) btnColor = Colors.orange;

                  return ChoiceChip(
                    label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    selected: isSel,
                    selectedColor: btnColor,
                    disabledColor: Colors.grey.shade300,
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black85),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(themeProvider.notifier).setTheme(opt);
                      }
                    },
                  );
                }).toList(),
              ),

              const Divider(height: 32),

              // 2. Shop configurations form
              const Text(
                'Shop Profile Information / دکان کی تفصیل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shop Name / نام دکان',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter shop name' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address / پتہ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter shop address' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Contact Number / فون نمبر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone contact' : null,
              ),

              const Divider(height: 32),

              // 3. Billing properties config
              const Text(
                'Receipt Customizations / بل ترتیب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _headerController,
                decoration: const InputDecoration(
                  labelText: 'Receipt Header Phrase / بل کی سرخی',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _footerController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Receipt Footer Phrase / بل کا نچلا حصہ',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _taxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Default Tax Rate / لاگو ٹیکس %',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                validator: (val) =>
                    val == null || double.tryParse(val) == null ? 'Enter default tax amount' : null,
              ),

              const SizedBox(height: 24),

              CustomButton(
                englishLabel: _isSaving ? 'Saving Configurations...' : 'Save Configuration Parameters',
                urduLabel: _isSaving ? 'محفوظ کیا جا رہا ہے...' : 'سیٹنگز اور بل کی تفصیل محفوظ کریں',
                onPressed: _isSaving ? () {} : _savePreferences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
