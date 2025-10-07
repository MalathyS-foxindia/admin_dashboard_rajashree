// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>?> getDailySalesStats(DateTime date, String? dsourceFilter) async {
    print('Fetching daily sales stats for date: $date with dsourceFilter: $dsourceFilter');
    try {
      final response = await supabase.rpc(
        'get_daily_sales_stats',
        params: {
          'target_date': date.toIso8601String().split('T').first,
          'dsource_filter': dsourceFilter
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
  Future<List<Map<String, dynamic>>?> getWeeklySalesStats() async {
    try {
      final response = await supabase.rpc(
        'get_weekly_sales_stats'
        
      );
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('Error calling get_weekly_sales_stats RPC: $e');
      return null;
    }
  }
    Future<List<Map<String, dynamic>>> fetchDailySkuSummary(DateTime date) async {
      print(date.toIso8601String().split('T')[0]);
  final response = await supabase.rpc(
    'daily_sku_summary_with_stock',
    params: {'p_date': date.toIso8601String().split('T')[0]},
  );

if (response == null) {
    throw Exception("❌ RPC returned null");
  }

  final data = response as List<dynamic>;
  return data.map((e) => Map<String, dynamic>.from(e)).toList();
}

Future<int> getTotalCustomers() async {
  try {
    final response = await supabase
        .from('customers')
        .select('customer_id');
       
    return response.length ?? 0;
  } catch (e) {
    print('Error fetching customers: $e');
    return 0;
  }
}

Future<int> getTotalProducts() async {
  try {
    final response = await supabase
        .from('product_variants')
        .select('variant_id');
        
    return response.length ?? 0;
  } catch (e) {
    print('Error fetching products: $e');
    return 0;
  }
}

}