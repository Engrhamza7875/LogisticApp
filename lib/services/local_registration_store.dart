import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalRegistrationStore {
  static const String _registrationsKey = 'sabcargo_registrations_json';

  static Future<void> saveRegistration({
    required String name,
    required String email,
    required String phone,
    required String pin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_registrationsKey) ?? <String>[];

    final record = <String, String>{
      'name': name,
      'email': email,
      'phone': phone,
      'pin': pin,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    // Upsert logic: if email already exists, replace it
    int existingIndex = -1;
    for (int i = 0; i < existing.length; i++) {
        final decoded = jsonDecode(existing[i]) as Map<String, dynamic>;
        if (decoded['email'] == email) {
            existingIndex = i;
            // Preserve creation date
            record['createdAt'] = decoded['createdAt']?.toString() ?? record['createdAt']!;
            break;
        }
    }

    if (existingIndex != -1) {
        existing[existingIndex] = jsonEncode(record);
    } else {
        existing.add(jsonEncode(record));
    }
    
    await prefs.setStringList(_registrationsKey, existing);
  }

  static Future<bool> checkEmailExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_registrationsKey) ?? <String>[];

    for (var item in raw) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      if (decoded['email'] == email) {
        return true;
      }
    }
    return false;
  }

  static Future<List<Map<String, String>>> getAllRegistrations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_registrationsKey) ?? <String>[];

    return raw.map((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
    }).toList();
  }
}
