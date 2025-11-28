import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class InvoiceWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  // 🔥 FINAL NON-CROPPING WIDTH (ABSOLUTE SAFE)
  final double pageWidth = 480;

  const InvoiceWidget({super.key, required this.data});

  // ---------------- HEADER ----------------
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Rajashree Fashion",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Chennai 600116, Tamil Nadu",
                    style: TextStyle(fontSize: 10),
                  ),
                  Text("Phone: 7010041418", style: TextStyle(fontSize: 10)),
                  Text(
                    "GSTIN: 33GFWPS8459J1Z8",
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(-100, 0), // <<< HUGE LEFT SHIFT
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  "assets/images/logo.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Smaller logo
          ],
        ),
        SizedBox(height: 6),
        Divider(color: Colors.black),
      ],
    );
  }

  // ---------------- ADDRESS BLOCK ----------------
  Widget _addressBlock() {
    final name = data['customer_name'] ?? "";

    String raw = (data['shipping_address'] ?? "").toString();

    // 1️⃣ Remove ALL escaped newline variations
    raw = raw.replaceAll(r"\\n", "\n");
    raw = raw.replaceAll(r"\n", "\n");
    raw = raw.replaceAll(r"\\\\n", "\n");
    raw = raw.replaceAll(r"\\\sn", "\n");

    // 2️⃣ Remove stray backslashes
    raw = raw.replaceAll("\\", "");

    // 3️⃣ Remove extra spaces around newlines
    raw = raw.replaceAll(RegExp(r"\s*\n\s*"), "\n");

    // 4️⃣ Trim final output
    raw = raw.trim();

    // 5️⃣ Finally convert commas to new lines (Edge function logic)
    final formatted = raw
        .replaceAll(RegExp(r'\s*,\s*'), "\n")
        .replaceAll("_", "\n")
        .split("\n")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join("\n");

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "To:\n"
        "$name\n"
        "$formatted\n"
        "Pincode: ${data['shipping_pincode']}\n"
        "${data['shipping_state']}\n"
        "Phone: ${data['mobile_number']}",
        style: TextStyle(fontSize: 10.5, height: 1.2),
      ),
    );
  }

  // ---------------- ORDER INFO ----------------
  Widget _orderInfo() {
    final orderId = (data['order_id'] ?? "").toString();
    final date = (data['order_date'] ?? "").toString().split("T").first;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Invoice No: $orderId", style: TextStyle(fontSize: 11)),
              SizedBox(height: 2),
              Text("Order Date: $date", style: TextStyle(fontSize: 11)),
            ],
          ),
        ),

        // 🔥 Barcode moved LEFT and width REDUCED
        Transform.translate(
          offset: Offset(-100, 0), // <<< HUGE LEFT SHIFT
          child: SizedBox(
            width: 90, // <<< Much smaller
            height: 32,
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: orderId,
              drawText: false,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- PRODUCT TABLE ----------------
  // ---------------- PRODUCT TABLE ----------------
  Widget _productTable() {
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

    // Total allowed width = 480 - (6+6) padding = 468 → safe to use 450
    const double colProduct = 250;
    const double colPrice = 55;
    const double colQty = 35;
    const double colTotal = 60;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
            color: Colors.grey[300],
            child: Row(
              children: const [
                SizedBox(
                  width: colProduct,
                  child: Text(
                    "Product",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: colPrice,
                  child: Text(
                    "Price",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: colQty,
                  child: Text(
                    "Qty",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: colTotal,
                  child: Text(
                    "Total",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // DATA ROWS
          ...items.map((item) {
            final product = "${item['sku'] ?? ''} ${item['product_name'] ?? ''}"
                .trim();

            final price = (item['price'] ?? 0).toDouble();
            final qty = (item['quantity'] ?? 1).toDouble();
            final total = price * qty;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: colProduct,
                    child: Text(
                      product,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: const TextStyle(fontSize: 9, height: 1.1),
                    ),
                  ),
                  SizedBox(
                    width: colPrice,
                    child: Text(
                      "Rs.$price",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                  SizedBox(
                    width: colQty,
                    child: Text(
                      "$qty",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                  SizedBox(
                    width: colTotal,
                    child: Text(
                      "Rs.$total",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------- TOTALS ----------------
  Widget _totals() {
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

    double sub = 0, cgst = 0, sgst = 0, igst = 0;

    final shipping = (data['shipping_amount'] ?? 0).toDouble();
    final isTN =
        (data['shipping_state'] ?? "").toString().toLowerCase() == "tamil nadu";

    for (var item in items) {
      final p = (item['price'] ?? 0).toDouble();
      final q = (item['quantity'] ?? 1).toDouble();

      final lineIncl = p * q;
      final base = lineIncl / 1.03;
      final gst = lineIncl - base;

      sub += base;

      if (isTN) {
        cgst += gst / 2;
        sgst += gst / 2;
      } else {
        igst += gst;
      }
    }

    final grand = sub + cgst + sgst + igst + shipping;

    // 🔥 Move totals LEFT by 40 px
    return Transform.translate(
      offset: Offset(-100, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _total("Subtotal", sub),
          if (isTN) _total("CGST (1.5%)", cgst),
          if (isTN) _total("SGST (1.5%)", sgst),
          if (!isTN) _total("IGST (3%)", igst),
          _total("Shipping", shipping),
          Divider(),
          _total("Grand Total", grand, bold: true),
        ],
      ),
    );
  }

  Widget _total(String label, double v, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          "Rs.${v.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Container(
      width: pageWidth, // 480px — no cut ever
      padding: EdgeInsets.all(6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          SizedBox(height: 6),
          _addressBlock(),
          SizedBox(height: 6),
          _orderInfo(),
          SizedBox(height: 10),
          _productTable(),
          SizedBox(height: 10),
          _totals(),
          SizedBox(height: 12),

          Text(
            "Thank you for your purchase!",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 3),
          Text(
            "Please record a 360° parcel opening video while receiving your parcel.\n"
            "Without video evidence, returns cannot be accepted.",
            style: TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
