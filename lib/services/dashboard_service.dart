// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>?> getDailySalesStats(DateTime date) async {
    try {
      final response = await supabase.rpc(
        'get_daily_sales_stats',
        params: {
          'target_date': date.toIso8601String().split('T').first,
        },
      );
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error calling get_daily_sales_stats RPC: $e');
      return null;
    }
  }
}