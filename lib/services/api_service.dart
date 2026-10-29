import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static String? _resolvedBaseUrl;
  static String? _overrideBaseUrl;

  static String get baseUrl =>
      _overrideBaseUrl ?? _resolvedBaseUrl ?? 'http://10.0.2.2:5000/api';

  /// Resolve a reachable backend URL automatically.
  /// Call `await ApiService.init()` from `main()` before `runApp()`.
  static Future<void> init() async {
    final prefs = await _getPrefs();
    _overrideBaseUrl = prefs.getString('override_base_url');
    _resolvedBaseUrl = await _autoResolveBaseUrl();
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        'ApiService resolved baseUrl: $baseUrl (override=${_overrideBaseUrl != null})',
      );
    }
  }

  /// Persist an override base URL. Pass `null` or empty to clear.
  static Future<void> setOverrideBaseUrl(String? url) async {
    final prefs = await _getPrefs();
    if (url == null || url.isEmpty) {
      _overrideBaseUrl = null;
      await prefs.remove('override_base_url');
    } else {
      _overrideBaseUrl = url;
      await prefs.setString('override_base_url', url);
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('ApiService override set: $_overrideBaseUrl');
    }
  }

  static Future<String> _autoResolveBaseUrl() async {
    // Prefer an explicit dart-define first.
    const envBaseUrl = String.fromEnvironment('BASE_URL');
    if (envBaseUrl.isNotEmpty) return envBaseUrl;

    // Then check repo-specific define if present.
    const defaultHost = String.fromEnvironment(
      'sabcargo_base_url',
      defaultValue: '',
    );
    if (defaultHost.isNotEmpty) return defaultHost;

    final candidates = kIsWeb
        ? <String>['http://localhost:5000/api', 'http://127.0.0.1:5000/api']
        : <String>[
            'http://localhost:5000/api',
            'http://127.0.0.1:5000/api',
            'http://10.0.2.2:5000/api',
            'http://10.0.3.2:5000/api',
          ];

    for (final c in candidates) {
      try {
        final uri = Uri.parse(c + '/health');
        final resp = await http
            .get(uri)
            .timeout(const Duration(milliseconds: 1200));
        if (resp.statusCode >= 200 && resp.statusCode < 400) return c;
      } catch (_) {
        try {
          final uri = Uri.parse(c + '/');
          final resp = await http
              .get(uri)
              .timeout(const Duration(milliseconds: 1200));
          if (resp.statusCode >= 200 && resp.statusCode < 400) return c;
        } catch (_) {}
      }
    }

    // Browser builds use the host's loopback; Android emulators use 10.0.2.2.
    return kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  }

  /// Builds HTTP headers that always include Content-Type.
  /// If a JWT is stored in SharedPreferences it is appended as a
  /// Bearer token so the backend RBAC middleware can verify the caller's role.
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await _getPrefs();
    final token = prefs.getString('sabcargo_auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all users from the backend.
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => Map<String, dynamic>.from(user)).toList();
      } else {
        throw Exception("Failed to load users: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to load users: $e");
    }
  }

  /// Admin/helper: create a user record directly (legacy endpoint).
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String phone,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'pin': pin,
        }),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception("Failed to create user: $e");
    }
  }

  /// Start registration: creates/updates user (isVerified=false) and sends OTP email.
  static Future<void> registerStart({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to register');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timed out while sending OTP. Please try again.',
      );
    } catch (e) {
      throw Exception('Network error during registration: $e');
    }
  }

  /// Verify OTP (2 min expiry, single-use, latest OTP only).
  static Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Failed to verify OTP');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timed out during verification. Please try again.',
      );
    } catch (e) {
      throw Exception('Network error during verification: $e');
    }
  }

  /// After OTP verification, set account PIN (stored hashed in backend).
  static Future<void> setPin({
    required String email,
    required String pin,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/set-pin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'pin': pin}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Failed to set PIN');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timed out while saving PIN. Please try again.',
      );
    } catch (e) {
      throw Exception('Network error while saving PIN: $e');
    }
  }

  /// Request PIN reset OTP (replaces previous OTP).
  static Future<void> requestPinReset({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/request-pin-reset'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(
            const Duration(seconds: 60),
          ); // Increased to 60s for slow email servers

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Failed to request PIN reset');
      }
    } on TimeoutException {
      throw Exception(
        'PIN request timed out. Please check your connection or try again.',
      );
    } catch (e) {
      throw Exception('Network error during PIN request: $e');
    }
  }

  /// Set new PIN using OTP (OTP must be valid and unexpired).
  static Future<void> setNewPin({
    required String email,
    required String otp,
    required String newPin,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/set-new-pin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'otp': otp, 'newPin': newPin}),
        )
        .timeout(const Duration(seconds: 30)); // Increased to 30s
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to set new PIN');
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateUserProfile(
    int userId,
    String name,
    String email,
    String phone,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'pin': '',
        }),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          "Failed to update user profile: ${error['error'] ?? response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to update user profile: $e");
    }
  }

  /// Verify PIN for login
  static Future<Map<String, dynamic>> verifyPin(
    String email,
    String pin,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-pin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'pin': pin}),
          )
          .timeout(const Duration(seconds: 15)); // 15s timeout

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['valid'] == true) {
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception(
          data['error'] ?? 'Authentication failed. Please check your PIN.',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception(
          "Server unreachable. Check your network or IP: $baseUrl",
        );
      }
      throw Exception("Login failed: $e");
    }
  }

  /// Ping the backend to get a fresh token with up-to-date roles
  static Future<Map<String, dynamic>> syncAuthStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to sync auth status: ${response.statusCode}');
    } catch (e) {
      throw Exception("Silent sync failed: $e");
    }
  }

  /// Save a shipment
  static Future<void> saveShipment(
    Map<String, dynamic> shipmentData, {
    String? userEmail,
  }) async {
    try {
      final payload = {
        ...shipmentData,
        if (userEmail != null) 'userEmail': userEmail,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/shipments'),
        headers: await _authHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 403) {
        throw Exception(
          'Permission denied: Admin access required to create shipments.',
        );
      }
      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(
          "Failed to save shipment: ${error['error'] ?? response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to save shipment: $e");
    }
  }

  /// Save a booking
  static Future<void> saveBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: await _authHeaders(),
        body: jsonEncode(bookingData),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          "Failed to save booking: ${error['error'] ?? response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to save booking: $e");
    }
  }

  /// Save mission update
  static Future<void> saveMissionUpdate(String missionId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/missions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'missionId': missionId, 'status': status}),
      );

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(
          "Failed to save mission update: ${error['error'] ?? response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to save mission update: $e");
    }
  }

  /// Delete a user by ID
  static Future<void> deleteUser(int userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/$userId'));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          "Failed to delete user: ${error['error'] ?? response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to delete user: $e");
    }
  }

  /// Fetch shipments authorized for the signed-in user.
  static Future<List<Map<String, dynamic>>> fetchShipments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/shipments'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(
      'Failed to fetch shipments: ${error['error'] ?? response.statusCode}',
    );
  }

  /// Fetch all admins (SuperAdmin-only endpoint)
  static Future<List<Map<String, dynamic>>> fetchAdmins() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admins'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 403) {
      throw Exception('Permission denied: SuperAdmin access required.');
    }
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch admins');
  }

  /// Add admin (SuperAdmin-only endpoint)
  static Future<void> addAdmin(Map<String, dynamic> admin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admins'),
      headers: await _authHeaders(),
      body: jsonEncode(admin),
    );
    if (response.statusCode == 403) {
      throw Exception('Permission denied: SuperAdmin access required.');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to add admin');
    }
  }

  /// Delete admin (SuperAdmin-only endpoint)
  static Future<void> deleteAdmin(String adminId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admins/$adminId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 403) {
      throw Exception('Permission denied: SuperAdmin access required.');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to delete admin');
    }
  }

  /// Get settings
  static Future<Map<String, dynamic>> getSettings(String key) async {
    final response = await http.get(Uri.parse('$baseUrl/settings/$key'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Settings not found');
  }

  /// Save settings (SuperAdmin-only endpoint)
  static Future<void> saveSettings(
    String key,
    Map<String, dynamic> value,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings'),
      headers: await _authHeaders(),
      body: jsonEncode({'key': key, 'value': value}),
    );
    if (response.statusCode == 403) {
      throw Exception(
        'Permission denied: SuperAdmin access required to change settings.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to save settings');
    }
  }

  /// Add a new tracking step to a shipment (Admin/SuperAdmin only)
  static Future<void> addTrackingStep(
    String trackingNumber,
    Map<String, dynamic> step,
    int status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/shipments/$trackingNumber/steps'),
        headers: await _authHeaders(),
        body: jsonEncode({'newStep': step, 'status': status}),
      );

      if (response.statusCode == 403) {
        throw Exception(
          'Permission denied: Admin access required to update tracking.',
        );
      }
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update tracking');
      }
    } catch (e) {
      throw Exception('Update tracking error: $e');
    }
  }

  // ============================================================
  // ADMIN: Users Management
  // ============================================================

  /// Fetch all users — Admin/SuperAdmin only
  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(
      'Failed to fetch users: ${error['error'] ?? response.statusCode}',
    );
  }

  /// Edit user details — Admin/SuperAdmin only
  static Future<void> editUser(
    int userId,
    String name,
    String email,
    String phone, {
    String? assignedOffice,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'assignedOffice': assignedOffice,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update user');
  }

  /// Delete a user — Admin/SuperAdmin only (authenticated)
  static Future<void> deleteUserAdmin(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete user');
  }

  /// Toggle user IsActive — Admin/SuperAdmin only
  static Future<bool> toggleUserActive(int userId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$userId/toggle-active'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isActive'] as bool;
    }
    throw Exception('Failed to toggle user active state');
  }

  /// Force logout a user — SuperAdmin only
  static Future<void> forceLogoutUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/force-logout'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Failed to force logout user');
  }

  /// Lock a suspicious user account — SuperAdmin only
  static Future<void> lockUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/lock'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Failed to lock user');
  }

  /// Reset user PIN by admin — Admin/SuperAdmin only
  static Future<void> resetUserPin(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/reset-pin'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Failed to reset user PIN');
  }

  // ============================================================
  // ADMIN: Admin Management Extensions
  // ============================================================

  /// Toggle admin IsActive — SuperAdmin only
  static Future<bool> toggleAdminActive(String adminId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/admins/$adminId/toggle-active'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isActive'] as bool;
    }
    throw Exception('Failed to toggle admin');
  }

  /// Reset admin PIN — SuperAdmin only
  static Future<void> resetAdminPin(String adminId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admins/$adminId/reset-pin'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Failed to reset admin PIN');
  }

  static Future<Map<String, dynamic>> fetchAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final startStr = startDate?.toIso8601String().split('T')[0] ?? '';
      final endStr = endDate?.toIso8601String().split('T')[0] ?? '';
      final url = '$baseUrl/analytics?startDate=$startStr&endDate=$endStr';

      final response = await http
          .get(Uri.parse(url), headers: await _authHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      }

      throw Exception('Failed to fetch analytics: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  // ============================================================
  // Dashboard Stats
  // ============================================================

  static Future<Map<String, dynamic>> fetchStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch stats');
  }

  // ============================================================
  // System Logs
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchLogs({int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/logs?limit=$limit'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch logs');
  }

  // ============================================================
  // Services CRUD
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchServices() async {
    final response = await http.get(Uri.parse('$baseUrl/services'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch services');
  }

  static Future<void> addService(Map<String, dynamic> service) async {
    final response = await http.post(
      Uri.parse('$baseUrl/services'),
      headers: await _authHeaders(),
      body: jsonEncode(service),
    );
    if (response.statusCode != 201) throw Exception('Failed to add service');
  }

  static Future<void> updateService(
    int id,
    Map<String, dynamic> service,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/services/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(service),
    );
    if (response.statusCode != 200) throw Exception('Failed to update service');
  }

  static Future<void> deleteService(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/services/$id'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete service');
  }

  static Future<bool> toggleService(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/services/$id/toggle'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isActive'] as bool;
    }
    throw Exception('Failed to toggle service');
  }

  // ============================================================
  // Notifications
  // ============================================================

  static Future<void> broadcastNotification({
    required String title,
    required String body,
    String targetRole = 'All',
    String? targetEmail,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/broadcast'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'title': title,
        'body': body,
        'targetRole': targetRole,
        if (targetEmail != null) 'targetEmail': targetEmail,
      }),
    );
    if (response.statusCode != 200)
      throw Exception('Failed to broadcast notification');
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch notifications');
  }

  // ============================================================
  // Shipment Cancel
  // ============================================================

  static Future<void> cancelShipment(String trackingNumber) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/shipments/$trackingNumber'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Failed to cancel shipment');
  }

  static Future<List<Map<String, dynamic>>> fetchUserNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/user'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch user notifications');
  }

  static Future<void> updateProfile(
    String name,
    String phone, {
    String? photo,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name, 'phone': phone, 'photo': photo}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update profile');
  }

  static Future<void> deleteUserAccount(int userId, String email) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/delete-account'),
      headers: await _authHeaders(),
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to delete account');
    }
  }
}
