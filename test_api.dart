// ignore_for_file: avoid_print
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    throw StateError('Pass GEMINI_API_KEY with --dart-define.');
  }

  print('Testing Gemini API...');
  final model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: apiKey,
  );
  try {
    final response = await model.generateContent([Content.text('Say hello')]);
    print('SUCCESS: ${response.text}');
  } catch (e) {
    print('ERROR: $e');
  }
}
