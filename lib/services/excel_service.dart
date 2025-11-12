import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import 'package:admin_dashboard_rajashree/models/order_model.dart';

import 'package:admin_dashboard_rajashree/models/purchase_model.dart';

import 'package:admin_dashboard_rajashree/models/products_model.dart';

import '../models/return_model.dart';


class ExcelService {
  // ================= ORDERS EXPORT =================
  static Future<bool> exportToExcel(List<Order> selectedOrders) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Orders'];

      // Header row
      sheetObject.appendRow([
        TextCellValue('Order ID'),
        TextCellValue('Customer Name'),
        TextCellValue('Mobile Number'),
        TextCellValue('Email'),
        TextCellValue('Address'),
        TextCellValue('State'),
        TextCellValue('Pincode'),
        TextCellValue('Total Amount'),
        TextCellValue('Payment Method'),
        TextCellValue('Order Date'),
      ]);

      // Data rows
      for (var order in selectedOrders) {
        final customer = order.customer;

        sheetObject.appendRow([
          TextCellValue(order.orderId.toString()),
          TextCellValue(customer?.fullName ?? ''),
          TextCellValue(customer?.mobileNumber ?? ''),
          TextCellValue(customer?.email ?? ''),
          TextCellValue(customer?.address ?? ''),
          TextCellValue(customer?.state ?? ''),
          TextCellValue(customer?.pincode ?? ''),
          DoubleCellValue(order.totalAmount),
          TextCellValue(order.paymentMethod),
          TextCellValue(order.orderDate.toString()),
        ]);
      }

      final bytes = excel.save();
      if (bytes != null) {
        await FileSaver.instance.saveFile(
          name: 'orders_export.xlsx',
          bytes: Uint8List.fromList(bytes),
          mimeType: MimeType.microsoftExcel,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error exporting Orders: $e");
      return false;
    }
  }

  // ================= SKU SUMMARY EXPORT =================
  static Future<bool> exportSkuSummaryToExcel(
    List<Map<String, dynamic>> skuSummary,
    DateTime date,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['SKU Summary'];

      // Header row
      sheet.appendRow([
        TextCellValue('SKU'),
        TextCellValue('Variant'),
        TextCellValue('Qty Sold'),
        TextCellValue('Current Stock'),
        TextCellValue('Date'),
      ]);

      for (final sku in skuSummary) {
        sheet.appendRow([
          TextCellValue((sku['sku'] ?? 'N/A').toString()),
          TextCellValue((sku['variant_name'] ?? 'N/A').toString()),
          TextCellValue(sku['total_qty']?.toString() ?? '0'),
          TextCellValue(sku['current_stock']?.toString() ?? 'N/A'),
          TextCellValue(date.toIso8601String().split('T')[0]),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await FileSaver.instance.saveFile(
          name: "sku_summary_${date.toIso8601String().split('T')[0]}.xlsx",
          bytes: Uint8List.fromList(fileBytes),
          mimeType: MimeType.microsoftExcel,
        );
      }
      return true;
    } catch (e) {
      print("❌ Error exporting SKU summary: $e");
      return false;
    }
  }

  // ================= PURCHASE EXPORT =================
  static Future<bool> exportPurchasesToExcel(List<Purchase> purchases) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Purchases'];

      // Header row
      sheet.appendRow([
        TextCellValue('Purchase ID'),
        TextCellValue('Invoice No'),
        TextCellValue('Vendor Name'),
        TextCellValue('Invoice Date'),
        TextCellValue('Total Amount'),
        TextCellValue('Item Count'),
        TextCellValue('Invoice Image URL'),
      ]);

      // Data rows
      for (final purchase in purchases) {
        sheet.appendRow([
          TextCellValue(purchase.purchaseId.toString()),
          TextCellValue(purchase.invoiceNo),
          TextCellValue(purchase.vendordetails.name),
          TextCellValue(
            "${purchase.invoiceDate?.day}-${purchase.invoiceDate?.month}-${purchase.invoiceDate?.year}",
          ),
          DoubleCellValue(purchase.totalAmount),
          TextCellValue(purchase.items.length.toString()),
          TextCellValue(purchase.invoiceImage ?? "-"),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await FileSaver.instance.saveFile(
          name: "purchases_export.xlsx",
          bytes: Uint8List.fromList(fileBytes),
          mimeType: MimeType.microsoftExcel,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error exporting Purchases: $e");
      return false;
    }
  }

// ================= RETURNS EXPORT =================
  static Future<bool> exportReturnsToExcel(List<ReturnModel> returnsList) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Returns'];

      // ✅ Header row
      sheet.appendRow([
        TextCellValue('Order ID'),
        TextCellValue('Return Date'),
        TextCellValue('Status'),
        TextCellValue('Reason'),
        TextCellValue('Returned Items'),
        TextCellValue('Refund Amount'),
        TextCellValue('Created At'),
      ]);

      // ✅ Data rows
      for (final r in returnsList) {
        sheet.appendRow([
          TextCellValue(r.orderId ?? '-'),
          TextCellValue(r.returnDate != null
              ? r.returnDate!.toIso8601String().split('T')[0]
              : '-'),
          TextCellValue(r.status),
          TextCellValue(r.reason ?? '-'),
          TextCellValue(r.returnedItems ?? '-'),
          DoubleCellValue(r.refundAmount ?? 0.0),
          TextCellValue(r.createdAt.toIso8601String().split('T')[0]),
        ]);
      }

      // ✅ Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final today = DateTime.now();
        final fileName =
            "returns_export_${today.year}_${today.month}_${today.day}.xlsx";

        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          mimeType: MimeType.microsoftExcel,
        );

        debugPrint("✅ Returns exported successfully: $fileName");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error exporting Returns: $e");
      return false;
    }
  }

static Future<bool> exportProductsToExcel(List<Product> products) async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel['Products'];

    sheet.appendRow([
      TextCellValue('Product Name'),
      TextCellValue('Product SKU'),
      TextCellValue('Category'),
      TextCellValue('Variant Name'),
      TextCellValue('Variant SKU'),
      TextCellValue('Regular Price'),
      TextCellValue('Sale Price'),
      TextCellValue('Weight'),
      TextCellValue('Stock'),
      TextCellValue('Variant Active'),
      TextCellValue('Product Active'),
    ]);

    for (final product in products) {
      if (product.variants != null && product.variants!.isNotEmpty) {
        for (final variant in product.variants!) {
          sheet.appendRow([
            TextCellValue(product.name ?? ''),
            TextCellValue(product.sku ?? ''),
            TextCellValue(product.category ?? ''),
            TextCellValue(variant.name ?? ''),
            TextCellValue(variant.sku ?? ''),
            TextCellValue(variant.regularPrice?.toString() ?? ''),
            TextCellValue(variant.salePrice?.toString() ?? ''),
            TextCellValue(variant.weight?.toString() ?? ''),
            TextCellValue(variant.stock?.toString() ?? ''),
            TextCellValue((variant.isActive ?? false) ? '✅' : '❌'),
            TextCellValue((product.isActive ?? false) ? '✅' : '❌'),
          ]);
        }
      }

      final bytes = excel.save();
      if (bytes != null) {
        await FileSaver.instance.saveFile(
          name: 'products_export.xlsx',
          bytes: Uint8List.fromList(bytes),
          mimeType: MimeType.microsoftExcel,
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Error exporting to Excel: $e");
      return false;
    }
  }
}
