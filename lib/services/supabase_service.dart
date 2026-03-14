import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';

class SupabaseService {
  const SupabaseService._();

  static bool _initialized = false;

  static bool get isConfigured => AppConfig.hasSupabaseConfig;

  static Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    _initialized = true;
  }

  static SupabaseClient get client {
    if (!isConfigured || !_initialized) {
      throw StateError(
        'Supabase is not initialized. Provide SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }
}
