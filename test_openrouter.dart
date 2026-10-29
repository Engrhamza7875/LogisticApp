// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing OpenRouter Gemini integration...');

  const String apiKey = 'YOUR_OPENROUTER_API_KEY';
  const String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  try {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'google/gemini-2.0-flash-001',
        'messages': [
          {'role': 'user', 'content': 'Say hi'},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('SUCCESS: ${data['choices'][0]['message']['content']}');
    } else {
      print('ERROR (${response.statusCode}): ${response.body}');
    }
  } catch (e) {
    print('EXCEPTION: $e');
  }
}
