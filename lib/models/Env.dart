class Env {
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    static const serviceRole = String.fromEnvironment('SUPABASE_SERVICE_ROLE',defaultValue:'');
}

