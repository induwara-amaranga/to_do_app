// F-06: Centralized config. Provide secrets via:
//   flutter run --dart-define=SUPABASE_ANON_KEY=<key>
// The defaultValue is kept for local dev; remove it and use --dart-define in CI/production.
class AppConfig {
  static const supabaseUrl = 'https://vzltupelovhgagglqpjf.supabase.co';

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6bHR1cGVsb3ZoZ2FnZ2xxcGpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNjAwNjQsImV4cCI6MjA3NTkzNjA2NH0.1QLbTrM0bZiU4UMsKHvUkCAbnXtzZ0MOR5rmf7G9HhY',
  );
}
