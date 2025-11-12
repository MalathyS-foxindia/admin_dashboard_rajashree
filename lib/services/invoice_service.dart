import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';

class InvoiceService {
  static Future<Map<String, dynamic>> generateInvoiceFromJson(
    Map<String, dynamic> jsonData,
  ) async {
    // Extract data
    String orderId = (jsonData['order_id'] ?? '').toString();
    String orderDate = (jsonData['order_date'] ?? '').toString();
    String customerName = (jsonData['customer_name'] ?? '').toString();
    String mobileNumber = (jsonData['mobile_number'] ?? '').toString();
    String shippingAddress = (jsonData['shipping_address'] ?? '')
        .toString()
        .replaceAll("\\ n", "\n"); // handles "backslash + space + n"

    String shippingState = (jsonData['shipping_state'] ?? '').toString();
    double shippingAmount = (jsonData['shipping_amount'] ?? 0).toDouble();
    List<dynamic> items = jsonData['items'] ?? [];

    // Font
    final ttf = await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf");
    final customFont = pw.Font.ttf(ttf);

    // GST
    double cgstRate = 1.5;
    double sgstRate = 1.5;
    double igstRate = 3.0;

    double subTotal = items.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0) * (item['quantity'] ?? 0));
    });

    double cgst = 0, sgst = 0, igst = 0;

    // Check state: Tamil Nadu -> CGST+SGST, Others -> IGST
    if (shippingState.trim().toLowerCase() == "tamil nadu") {
      cgst = subTotal * (cgstRate / 100);
      sgst = subTotal * (sgstRate / 100);
    } else {
      igst = subTotal * (igstRate / 100);
    }

    double grandTotal = subTotal + cgst + sgst + igst + shippingAmount;
    // Load logo image from assets
    final logoBytes = await rootBundle.load("assets/images/logo.png");
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Barcode
    final barcode = Barcode.code128();
    final svg = barcode.toSvg(orderId, width: 200, height: 60);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "From",
                      style: pw.TextStyle(
                        font: customFont,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Rajashree Fashion",
                      style: pw.TextStyle(font: customFont),
                    ),
                    pw.Text(
                      "Chennai 600116",
                      style: pw.TextStyle(font: customFont),
                    ),
                    pw.Text(
                      "Tamil Nadu",
                      style: pw.TextStyle(font: customFont),
                    ),
                    pw.Text(
                      "7010041418",
                      style: pw.TextStyle(font: customFont),
                    ),
                    pw.Text(
                      "GSTIN: 33GFWPS8459J1Z8",
                      style: pw.TextStyle(font: customFont),
                    ),
                  ],
                ),
                pw.Image(logoImage, width: 80), // your logo on the right
              ],
            ),

            pw.SizedBox(height: 20),

            // Shipping Address Highlighted (with barcode/date on the right)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1, color: PdfColors.black),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Shipping address
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Shipping Address",
                        style: pw.TextStyle(
                          font: customFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "$customerName",
                        style: pw.TextStyle(font: customFont, fontSize: 14),
                      ),
                      pw.Text(
                        "$shippingAddress",
                        style: pw.TextStyle(font: customFont, fontSize: 14),
                      ),
                      pw.Text(
                        "$shippingState",
                        style: pw.TextStyle(font: customFont, fontSize: 12),
                      ),
                      pw.Text(
                        "No: $mobileNumber",
                        style: pw.TextStyle(font: customFont, fontSize: 12),
                      ),
                    ],
                  ),

                  // Right: Barcode + Order details
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SvgImage(svg: svg, height: 60),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        "Order Date: $orderDate",
                        style: pw.TextStyle(font: customFont, fontSize: 10),
                      ),
                      pw.Text(
                        "Invoice No: $orderId",
                        style: pw.TextStyle(font: customFont, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Products
            pw.Text(
              "Products purchased:",
              style: pw.TextStyle(
                font: customFont,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.Table.fromTextArray(
              headers: ["Product", "Unit Price", "Qty", "Total"],
              headerStyle: pw.TextStyle(
                font: customFont,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: pw.TextStyle(font: customFont, fontSize: 10),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Product column wider
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
              },
              data: items.map((e) {
                final double price = (e['price'] ?? 0).toDouble();
                final int qty = (e['quantity'] ?? 0).toInt();
                final double total = price * qty;

                return [
                  e['variant_name'] ?? '',
                  "₹${price.toStringAsFixed(2)}",
                  qty.toString(),
                  "₹${total.toStringAsFixed(2)}",
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            // Totals Section (Right Aligned Box)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.black),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _summaryRow(
                      "Subtotal:",
                      "₹${subTotal.toStringAsFixed(2)}",
                      customFont,
                    ),
                    if (shippingState.trim().toLowerCase() == "tamil nadu") ...[
                      _summaryRow(
                        "CGST (${cgstRate.toStringAsFixed(1)}%):",
                        "₹${cgst.toStringAsFixed(2)}",
                        customFont,
                      ),
                      _summaryRow(
                        "SGST (${sgstRate.toStringAsFixed(1)}%):",
                        "₹${sgst.toStringAsFixed(2)}",
                        customFont,
                      ),
                    ] else ...[
                      _summaryRow(
                        "IGST (${igstRate.toStringAsFixed(1)}%):",
                        "₹${igst.toStringAsFixed(2)}",
                        customFont,
                      ),
                    ],
                    _summaryRow(
                      "Shipping:",
                      "₹${shippingAmount.toStringAsFixed(2)}",
                      customFont,
                    ),
                    pw.Divider(),
                    _summaryRow(
                      "Total:",
                      "₹${grandTotal.toStringAsFixed(2)}",
                      customFont,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // Footer Note
            pw.Text(
              "Thank you for your purchase!",
              style: pw.TextStyle(font: customFont, fontSize: 12),
            ),
            pw.Text(
              "It is mandatory to take a 360° parcel opening video after receiving your product from the courier. "
              "Without opening video the product will not be taken back for our consideration.",
              style: pw.TextStyle(font: customFont, fontSize: 10),
            ),
          ],
        ),
      ),
    );

    Uint8List pdfBytes = await pdf.save();
    DateTime norderDate = DateTime.tryParse(orderDate) ?? DateTime.now();

    return {
      "orderId": orderId,
      "fileName": "Invoice_$orderId.pdf",
      "filedate": norderDate,
      "mimeType": "application/pdf",
      "fileData": base64Encode(pdfBytes),
    };
  }

  static pw.Widget _summaryRow(
    String label,
    String value,
    pw.Font font, {
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
