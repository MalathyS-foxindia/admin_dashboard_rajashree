import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class InvoiceService {
  static Future<Map<String, dynamic>?> generateInvoiceFromJson({
    required BuildContext context,
    required Map<String, dynamic> jsonData,
    required GlobalKey invoiceKey,
    required Widget invoiceWidget,
  }) async {
    try {
      // ------------ 1) OFFSCREEN EXACT A4 RENDER AREA ------------
      final overlayEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: -5000,
          top: -5000,
          child: IgnorePointer(
            ignoring: true,
            child: Material(
              color: Colors.white,
              child: SizedBox(
                width: 595, // A4 width in px
                height: 842, // A4 height in px
                child: RepaintBoundary(
                  key: invoiceKey,
                  child: SizedBox(
                    width: 595,
                    height: 842, // IMPORTANT → removes all top gaps
                    child: invoiceWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);

      // ------------ 2) WAIT FOR LAYOUT+PAINT ------------
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));

      RenderRepaintBoundary? boundary =
          invoiceKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      int tries = 0;
      while (boundary == null || boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 120));
        boundary =
            invoiceKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (++tries > 20) break;
      }

      if (boundary == null) throw Exception("Boundary not ready");

      // ------------ 3) IMAGE CAPTURE WITHOUT CROPPING ------------
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final png = byteData!.buffer.asUint8List();

      overlayEntry.remove();

      // ------------ 4) PDF WITH ZERO TOP SPACE ------------
      final pdf = pw.Document();
      final img = pw.MemoryImage(png);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero, // no margins
          build: (_) => pw.Container(
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
            child: pw.Image(
              img,
              fit: pw.BoxFit.cover, // 👈 EXACT NO GAP TOP/BOTTOM
            ),
          ),
        ),
      );

      final pdfBytes = await pdf.save();
      final orderId = jsonData['order_id'].toString();

      return {
        "fileName": "Invoice_$orderId.pdf",
        "fileData": pdfBytes,
        "mimeType": "application/pdf",
        "orderId": orderId,
        "filedate": jsonData['order_date'],
      };
    } catch (e, st) {
      debugPrint("Invoice generation error: $e\n$st");
      return null;
    }
  }
}
