import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';

class InvoiceService {
  static Future<Map<String, dynamic>> generateInvoiceFromJson(Map<String, dynamic> jsonData) async {
    // Extract data from JSON
    String orderId = jsonData['order_id'] ?? '';
    String orderDate = jsonData['order_date'] ?? '';
    String customerName = jsonData['customer_name'] ?? '';
    String mobileNumber = jsonData['mobile_number'] ?? '';
    String shippingAddress = jsonData['shipping_address'] ?? '';
    String shippingState = jsonData['shipping_state'] ?? '';
    double totalAmount = (jsonData['total_amount'] ?? 0).toDouble();
    double shippingAmount = (jsonData['shipping_amount'] ?? 0).toDouble();
    String paymentMethod = jsonData['payment_method'] ?? '';
    String invoiceNote = jsonData['invoice_note'] ?? '';

    List<dynamic> items = jsonData['items'] ?? [];
    // Load a Unicode font
  final ttf = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
final customFont = pw.Font.ttf(ttf);

    // GST settings
    double cgstRate = 15; // Example rate, change as needed
    double sgstRate = 15;

    // Calculate subtotal (before GST & shipping)
    double subTotal = items.fold(0, (sum, item) {
      return sum + ((item['price'] ?? 0) * (item['quantity'] ?? 0));
    });

    double cgst = subTotal * (cgstRate / 100);
    double sgst = subTotal * (sgstRate / 100);
    double grandTotal = subTotal + cgst + sgst + shippingAmount;
            // Create barcode
    final barcode = Barcode.code128();
    final svg = barcode.toSvg(orderId, width: 200, height: 80);
    // Create PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(

        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Add Barcode at the top
            pw.Container(
              height: 80,
              child: pw.SvgImage(svg: svg),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Invoice ID: $orderId'),

            pw.Text('Date: $orderDate'),
            pw.Text('Customer: $customerName'),
            pw.Text('Mobile: $mobileNumber'),
            pw.Text('Address: $shippingAddress, $shippingState'),
            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: ['Item', 'Qty', 'Price', 'Total'],
              data: items.map((e) => [
                e['variant_name'] ?? '',
                e['quantity'].toString(),
                (e['price'] ?? 0).toStringAsFixed(2),
                ((e['price'] ?? 0) * (e['quantity'] ?? 0)).toStringAsFixed(2),
              ]).toList(),
            ),

            pw.SizedBox(height: 20),
            pw.Text('Subtotal: ₹${subTotal.toStringAsFixed(2)}',style: pw.TextStyle(
    font: customFont,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
  )
            ),
            
            pw.Text('CGST ($cgstRate%): ₹${cgst.toStringAsFixed(2)}',style: pw.TextStyle(
    font: customFont,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
  )),
            pw.Text('SGST ($sgstRate%): ₹${sgst.toStringAsFixed(2)}',style: pw.TextStyle(
    font: customFont,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
  )),
            pw.Text('Shipping: ₹${shippingAmount.toStringAsFixed(2)}',style: pw.TextStyle(
    font: customFont,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
  )),
            pw.Text('Total: ₹${grandTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(font:customFont, fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Payment Method: $paymentMethod'),
            if (invoiceNote.isNotEmpty) pw.SizedBox(height: 10),
            if (invoiceNote.isNotEmpty) pw.Text('Note: $invoiceNote'),
          ],
        ),
      ),
    );

    Uint8List pdfBytes = await pdf.save();
    // Assuming orderDate is a DateTime object
    DateTime norderDate = DateTime.tryParse(jsonData['order_date'] ?? '') ?? DateTime.now();

    // Return file details (base64 for API or upload)
    return {
      "fileName": "Invoice_$orderId.pdf",
      "filedate":  norderDate,
      "mimeType": "application/pdf",
      "fileData": base64Encode(pdfBytes),
    };
  }
}
