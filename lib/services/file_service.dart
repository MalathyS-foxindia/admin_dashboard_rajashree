import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';

class FileService {
  static Future<void> downloadAndSaveImage(
      BuildContext context,
      String imageUrl, {
        String? fileName,
      }) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw "HTTP ${response.statusCode}";

      // 🔍 Detect extension from URL
      String extension = "";
      final uri = Uri.parse(imageUrl);
      final path = uri.path.toLowerCase();

      if (path.endsWith(".png")) {
        extension = "png";
      } else if (path.endsWith(".jpeg")) {
        extension = "jpeg";
      } else if (path.endsWith(".jpg")) {
        extension = "jpg";
      } else if (path.endsWith(".webp")) {
        extension = "webp";
      } else {
        extension = "jpg"; // fallback
      }

      final name = fileName ?? "invoice_${DateTime.now().millisecondsSinceEpoch}";

      // 📥 Save file using FileSaver (works across Mobile, Web, Desktop)
      await FileSaver.instance.saveFile(
        name: "$name.$extension",
        bytes: Uint8List.fromList(response.bodyBytes),
        mimeType: MimeType.other, // universal fallback
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Invoice downloaded successfully")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Download failed: $e")),
        );
      }
    }
  }
}
