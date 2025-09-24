import 'package:supabase_flutter/supabase_flutter.dart';

class Logger {
  final SupabaseClient supabase;
  Logger(this.supabase);

  Future<void> log({
    required String provider,
    required String action,
    String? message,
    String level = 'INFO',
  }) async {
    try {
      await supabase.from('logs').insert({
        'provider': provider,
        'action': action,
        'message': message ?? '',
        'level': level,
      });
    } catch (e) {
      // fallback — in case logging itself fails
      print('❌ Failed to log: $e');
    }
  }
}
