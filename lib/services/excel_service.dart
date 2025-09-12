import 'dart:io';
import 'dart:typed_data'; // Import Uint8List
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:admin_dashboard_rajashree/models/order_model.dart';

class ExcelService {
  // Static method to allow direct call without creating an instance
  static Future<bool> exportToExcel(List<Order> selectedOrders) async {
    try {
      // 1. Create a new Excel workbook
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Orders'];

      // Remove TextCellValue / DoubleCellValue
sheetObject.appendRow([ TextCellValue('Order ID'), 
 TextCellValue('Customer Name'), 
 TextCellValue('Mobile Number'), 
 TextCellValue('Total Amount'), 
 TextCellValue('Payment Method'), 
 TextCellValue('Order Date'), ]);
for (var order in selectedOrders) { sheetObject.appendRow([ TextCellValue(order.orderId),
 TextCellValue(order.customerName), 
 TextCellValue(order.mobileNumber), 
 DoubleCellValue(order.totalAmount), 
 TextCellValue(order.paymentMethod), 
 TextCellValue(order.orderDate.toString()), ]); }
      // 4. Save the file and trigger download
      final bytes = excel.save();

      if (bytes != null) {
        await FileSaver.instance.saveFile(
  name: 'orders_export.xlsx', // include extension directly
  bytes: Uint8List.fromList(bytes),
  mimeType: MimeType.microsoftExcel,
);
        return true; // Return success
      }
      return false; // Return failure
    } catch (e) {
      debugPrint("Error exporting to Excel: $e");
      return false;
    }
  }
  
  static Future<bool> exportSkuSummaryToExcel(
      List<Map<String, dynamic>> skuSummary, DateTime date) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['SKU Summary'];

      // ✅ Add header row
      sheet.appendRow([
        TextCellValue('SKU'),
        TextCellValue('Variant'),
        TextCellValue('Qty Sold'),
        TextCellValue('Current Stock'),
        TextCellValue('Date'),
      ]);

      // ✅ Add SKU summary rows
      for (final sku in skuSummary) {
        sheet.appendRow([
           TextCellValue((sku['sku'] ?? 'N/A').toString()),
        TextCellValue((sku['variant_name'] ?? 'N/A').toString()),
          TextCellValue(sku['total_qty']?.toString() ?? '0'),
          TextCellValue(['current_stock']?.toString() ?? 'N/A'),
          TextCellValue(date.toIso8601String().split('T')[0]),
        ]);
      }
// Save to bytes
    final fileBytes = excel.save();

    if (fileBytes != null) {
      final blob = Uint8List.fromList(fileBytes);
      final fileName = "sku_summary_${date.toIso8601String().split('T')[0]}.xlsx";

      // ✅ This works on both Web and Desktop
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: blob,
                mimeType: MimeType.microsoftExcel,
      );
    }

    return true;
  } catch (e) {
    print("❌ Error exporting SKU summary: $e");
    return false;
  }
  }
}