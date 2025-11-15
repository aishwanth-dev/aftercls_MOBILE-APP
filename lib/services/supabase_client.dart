import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();

  factory SupabaseManager() {
    return _instance;
  }

  SupabaseManager._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://g3f74j3e.us-east.insforge.app',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImczaDc0ajNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTk1ODU3OTQsImV4cCI6MjAzNTE2MTc5NH0.0-33Z3b-2dJb5iy222222222222222-r2222222222',
    );
  }
}