import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceService {
  static Future<Map<String, dynamic>?> generateInvoiceFromJson(
    Map<String, dynamic> jsonData,
  ) async {
    final supabase = Supabase.instance.client;
    final res = await supabase.functions.invoke(
      'generateInvoicePDFV2',
      body: {'jsonData': jsonData},
    );

    if (res.data != null) {
      return Map<String, dynamic>.from(res.data);
    } else {
      print('Error generating invoice: ${res.status}');
      return null;
    }
  }
}
