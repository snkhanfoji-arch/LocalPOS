import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale.dart';

class PdfService {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static Future<Uint8List> generate80mmThermalBill(Sale sale) async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();

    final shopName = prefs.getString('shop_name') ?? 'PosKhata Pro Shop';
    final shopAddress = prefs.getString('shop_address') ?? 'Main Bazaar, Pakistan';
    final shopPhone = prefs.getString('shop_phone') ?? '0300-1234567';
    final billHeader = prefs.getString('bill_header') ?? 'SALES RECEIPT / رسید';
    final billFooter = prefs.getString('bill_footer') ?? 'Thank you for your business!\nدوبارہ تشریف لائیں۔ شکرية!';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
        ),
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                shopName,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                shopAddress,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Phone: $shopPhone',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                billHeader,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Divider(thickness: 1, style: pw.BorderStyle.dashed),

              // Metadata
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  cross: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: ${sale.dateTime.substring(0, 16)}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Invoice ID: POS-${sale.id ?? 'TEMP'}', style: const pw.TextStyle(fontSize: 8)),
                    if (sale.customerId != null)
                      pw.Text('Customer ID: ${sale.customerId}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, style: pw.BorderStyle.dashed),

              // Items Table Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Item / تفصیل', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('Qty', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Price', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 0.5),

              // Items
              pw.ListView.builder(
                itemCount: sale.items.length,
                itemBuilder: (context, index) {
                  final item = sale.items[index];
                  // Strip non-latin characters for standard PDF fonts, standard PDF fonts can crash with Urdu unless custom ttf is bundled.
                  // To avoid crashes on standard 14 core fonts, we filter/clean names, and display clean English string.
                  final cleanName = item.name.replaceAll(RegExp(r'[\u0600-\u06FF]'), '').trim();
                  final displayName = cleanName.isEmpty ? 'Item #${item.id}' : cleanName;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(displayName, style: const pw.TextStyle(fontSize: 7)),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(item.quantity.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(_formatter.format(item.price), style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.right),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(_formatter.format(item.total), style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                  );
                },
              ),
              pw.Divider(thickness: 1, style: pw.BorderStyle.dashed),

              // Calculations
              pw.Column(
                children: [
                  _receiptSumRow('Subtotal:', _formatter.format(sale.subtotal)),
                  if (sale.discountPercentage > 0)
                    _receiptSumRow('Discount (${sale.discountPercentage.toInt()}%):', '- ${_formatter.format(sale.subtotal * sale.discountPercentage / 100)}'),
                  if (sale.taxPercentage > 0)
                    _receiptSumRow('Tax (${sale.taxPercentage.toInt()}%):', '+ ${_formatter.format(sale.subtotal * (1 - sale.discountPercentage / 100) * sale.taxPercentage / 100)}'),
                  pw.Divider(thickness: 0.5),
                  _receiptSumRow('Total (PKR):', _formatter.format(sale.total), isBold: true),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, style: pw.BorderStyle.dashed),

              // Footer
              pw.SizedBox(height: 4),
              pw.Text(
                billFooter,
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Powered by PosKhata Pro',
                style: pw.TextStyle(fontSize: 5, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _receiptSumRow(String label, String value, {bool isBold = false}) {
    final style = pw.TextStyle(
      fontSize: 8,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
