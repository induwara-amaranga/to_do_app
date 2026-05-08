// lib/services/ai_task_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:to_do_app/config/app_config.dart';

class AiTaskService {
  static const String _endpoint =
      'https://vzltupelovhgagglqpjf.supabase.co/functions/v1/super-endpoint';
  //'https://vzltupelovhgagglqpjf.supabase.co/functions/v1/super-endpoint';

  /// Call AI generation API
  static Future<Map<String, dynamic>> generateTasks({
    required String goal,
    required String timeframe,
  }) async {
    final body = {
      "goal": goal,
      "timeframe": timeframe,
      "timeStamp": DateTime.now().toLocal().toString(),
    };
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          // F-05: authenticate the edge function call with the Supabase anon key
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        throw Exception(
          'Failed to fetch tasks: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error during API call: $e');
    }
  }
}
