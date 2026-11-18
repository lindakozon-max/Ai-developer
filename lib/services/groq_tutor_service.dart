import 'dart:convert';

import 'package:http/http.dart' as http;

class GroqTutorService {
  GroqTutorService({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'openai/gpt-oss-120b';
  static const _apiKey = String.fromEnvironment('GROQ_API_KEY');
  final http.Client _client;

  Future<String> ask({
    required String message,
    required String level,
    required String language,
  }) async {
    if (_apiKey.isEmpty) {
      return 'Add your Groq key when you run the app: '
          '--dart-define=GROQ_API_KEY=your_key';
    }
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.5,
        'max_completion_tokens': 500,
        'messages': [
          {
            'role': 'system',
            'content': 'You are Finn, a warm, patient and friendly English tutor for children. '
                'The student is practising at $level (Pre-A1, A1, A2, B1, B2, C1, C2, '
                'Fluent or Mastery). Use short, encouraging answers suitable for children. '
                'Teach English with daily lessons, tiny tests and simple exercises. '
                'Correct mistakes kindly, explain maths clearly when asked, and use '
                '$language for explanations when the student needs help. '
                'When asked to assess English, give an estimated CEFR level and one '
                'clear next step. Always include one small example.',
          },
          {'role': 'user', 'content': message},
        ],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Groq request failed (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['choices'] as List).first as Map<String, dynamic>)['message']
            ['content']
        as String;
  }

  void close() => _client.close();
}
