import 'dart:typed_data'; // Import Uint8List
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';


import 'package:admin_dashboard_rajshree/models/order_model.dart';

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
}