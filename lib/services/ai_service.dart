import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GenerativeAIService {
  static const String _apiKey = 'YOUR_OPENROUTER_API_KEY';
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  static Future<String> getChatResponse(String prompt) async {
    try {
      // Fetch dynamic rules from Admin Settings (via SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final rate = prefs.getDouble('admin_shipping_rate') ?? 30.0;
      final routesList = prefs.getStringList('admin_active_routes') ?? [
        'Pakistan', 'Bangladesh', 'India', 'Philippines', 'Indonesia', 
        'Egypt', 'Jordan', 'UAE', 'UK', 'USA'
      ];
      final routesStr = routesList.join(', ');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://sabcargo.com', // Required by OpenRouter
          'X-Title': 'Sabcargo App', // Optional but good practice
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001',
          'messages': [
            {
              'role': 'system', 
              'content': '''You are the Sabcargo Logistics Assistant — a professional and helpful virtual assistant.
Current Business Rules:
- Standard Shipping Rate: $rate SAR per kg (Strictly follow this).
- International Routes: $routesStr.
- Office Location: Al Olaya, Riyadh.
- Services: Door-to-door, Cargo, Express Shipping.
If asked about rates or routes, use the values provided above. Keep answers concise and supportive.'''
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        return content ?? "I'm sorry, I couldn't generate a response. Please try again.";
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        return "AI service error (${response.statusCode}): $errorMessage. Please check your configuration.";
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('SocketException') || errorMsg.contains('NetworkException')) {
        return "No internet connection. Please check your network and try again.";
      } else if (errorMsg.contains('TimeoutException')) {
        return "The request timed out. Please try again in a moment.";
      }
      return "Connection error: ${errorMsg.length > 120 ? "${errorMsg.substring(0, 120)}..." : errorMsg}";
    }
  }
}
