import 'package:sabcargo/services/logger_service.dart';
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService extends ChangeNotifier {
  static const String _settingsId = 'global_business_rules';

  List<AdminUser> _admins = [];
  double _shippingRatePerKg = 30.0;
  List<String> _activeRoutes = [
    'Pakistan',
    'Bangladesh',
    'India',
    'Philippines',
    'UAE',
    'UK',
    'USA',
  ];

  Map<String, bool> _featureToggles = {
    'file_upload': true,
    'comments_section': true,
    'metrics_view': true,
    'profile_edit': true,
    'ai_chat': true,
  };

  List<String> _officeLocations = [
    'Riyadh Main Office',
    'Jeddah Branch',
    'Medina Office',
    'Dammam Hub',
  ];

  final List<Map<String, dynamic>> _cargoServices = [
    {
      'id': 'S001',
      'title': 'Air Freight',
      'image':
          'https://images.unsplash.com/photo-1570710891163-6d3b5c47248b?q=80&w=400&fit=crop',
      'subtitle': 'Fastest Delivery',
      'iconCode': Icons.flight_rounded.codePoint,
      'colorValue': const Color(0xFF1E88E5).value,
      'description':
          'Our premium air freight service offers the quickest transit times for your urgent shipments.',
      'features': ['Express Delivery (24-48h)', 'Real-time Flight Tracking'],
    },
    {
      'id': 'S002',
      'title': 'Sea Freight',
      'image':
          'https://images.unsplash.com/photo-1505027492977-1037f14c46fa?q=80&w=400&fit=crop',
      'subtitle': 'Cost Effective',
      'iconCode': Icons.directions_boat_rounded.codePoint,
      'colorValue': const Color(0xFF00ACC1).value,
      'description':
          'Ideal for large volume shipments, our sea freight solutions provide the best cost-to-weight ratio.',
      'features': ['Economical for Bulk Cargo', 'Global Port Coverage'],
    },
    {
      'id': 'S003',
      'title': 'Land Freight',
      'image':
          'https://images.unsplash.com/photo-1519003722824-194d4455a60c?q=80&w=400&fit=crop',
      'subtitle': 'Reliable Route',
      'iconCode': Icons.local_shipping_rounded.codePoint,
      'colorValue': const Color(0xFF43A047).value,
      'description':
          'Our extensive network of trucks provides reliable door-to-door delivery across regions.',
      'features': ['Door-to-Door Service', 'Regional Connectivity'],
    },
  ];

  double get shippingRate => _shippingRatePerKg;
  List<String> get activeRoutes => List.unmodifiable(_activeRoutes);
  List<String> get officeLocations => List.unmodifiable(_officeLocations);
  List<AdminUser> get admins => List.unmodifiable(_admins);
  List<Map<String, dynamic>> get cargoServices => _cargoServices;
  Map<String, bool> get featureToggles => _featureToggles;

  AdminService() {
    refreshData();
  }

  /// Fetch admins and settings from the backend
  Future<void> refreshData() async {
    // Only attempt to fetch if we have an admin session
    final role = await AuthService.getUserRole();
    if (role != 'Admin' && role != 'SuperAdmin') return;

    try {
      await Future.wait([
        _loadAdmins(),
        _loadSettings(),
      ]);
      if (_admins.isEmpty && role == 'SuperAdmin') {
        await _seedInitialData();
      }
    } catch (e) {
      appLogger.i('Refresh failed: $e');
    }
    notifyListeners();
  }

  Future<void> _seedInitialData() async {
    appLogger.i('Seeding initial data through the backend API...');
    // Seed Super Admins
    final fiverr = AdminUser(
      id: 'A002',
      name: 'Fiverr Support',
      email: 'freelancing.fiver001@gmail.com',
      phoneNumber: '+966 50 000 0001',
      role: AdminRole.superAdmin,
      branchName: 'Global Ops',
    );
    await addAdmin(fiverr);

    // 2. Seed Settings
    await updateShippingRate(30.0);
  }

  Future<void> _loadSettings() async {
    try {
      // 1. Load global business rules
      final settings = await ApiService.getSettings(_settingsId);
      if (settings.isNotEmpty) {
        _shippingRatePerKg = (settings['shippingRate'] as num).toDouble();
        _activeRoutes = List<String>.from(settings['activeRoutes'] ?? []);
        if (settings['officeLocations'] != null) {
          _officeLocations = List<String>.from(settings['officeLocations']);
        }
        if (settings['featureToggles'] != null) {
          _featureToggles = Map<String, bool>.from(settings['featureToggles']);
        }
      }

      // 2. Load services from dedicated endpoint
      final servicesData = await ApiService.fetchServices();
      if (servicesData.isNotEmpty) {
        _cargoServices.clear();
        _cargoServices.addAll(servicesData.map((s) => {
          'id': s['id'],
          'title': s['name'],
          'description': s['description'],
          'iconCode': s['iconCode'],
          'colorValue': s['colorValue'],
          'isActive': s['isActive'],
        }));
      }
    } catch (e) {
      appLogger.i('Error loading settings/services: $e');
    }
  }

  Future<void> _loadAdmins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = await ApiService.fetchAdmins();
      if (adminData.isNotEmpty) {
        _admins = adminData.map((json) {
          final Map<String, dynamic> doc = Map<String, dynamic>.from(json);
          final adminUser = AdminUser.fromJson(doc);
          
          // Try to load pin from local SharedPreferences if the backend didn't provide one
          String? localPin = adminUser.pin ?? prefs.getString('admin_pin_${adminUser.id}');
          
          if (localPin != null) {
            return AdminUser(
              id: adminUser.id,
              name: adminUser.name,
              email: adminUser.email,
              phoneNumber: adminUser.phoneNumber,
              role: adminUser.role,
              branchName: adminUser.branchName,
              pin: localPin,
              isActive: adminUser.isActive,
              permissions: adminUser.permissions,
            );
          }
          return adminUser;
        }).toList();
      } else {
        _admins = [];
      }
    } catch (e) {
      appLogger.i('Error loading admins: $e');
    }
  }

  Future<void> addAdmin(AdminUser user) async {
    try {
      if (user.pin != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_pin_${user.id}', user.pin!);
      }
      
      await ApiService.addAdmin(user.toJson());
      
      // Explicitly register the new PIN with the authentication service
      if (user.pin != null && user.pin!.isNotEmpty) {
        try {
          await ApiService.setPin(email: user.email, pin: user.pin!);
        } catch (e) {
          appLogger.w('Warning: Failed to set PIN on backend: $e');
        }
      }
      
      await _loadAdmins(); // Refresh local list
      notifyListeners();
    } catch (e) {
      appLogger.i('Error adding admin: $e');
    }
  }

  Future<void> removeAdmin(String id) async {
    try {
      await ApiService.deleteAdmin(id);
      await _loadAdmins(); // Refresh local list
      notifyListeners();
    } catch (e) {
      appLogger.i('Error removing admin: $e');
    }
  }

  Future<void> togglePermission(String adminId, String permission) async {
    final index = _admins.indexWhere((a) => a.id == adminId);
    if (index != -1) {
      final admin = _admins[index];
      final newPermissions = List<String>.from(admin.permissions);
      if (newPermissions.contains(permission)) {
        newPermissions.remove(permission);
      } else {
        newPermissions.add(permission);
      }

      final updatedAdmin = AdminUser(
        id: admin.id,
        name: admin.name,
        email: admin.email,
        phoneNumber: admin.phoneNumber,
        role: admin.role,
        branchName: admin.branchName,
        pin: admin.pin,
        isActive: admin.isActive,
        permissions: newPermissions,
      );

      await addAdmin(updatedAdmin);
    }
  }

  Future<void> updateShippingRate(double newRate) async {
    _shippingRatePerKg = newRate;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> addRoute(String route) async {
    if (!_activeRoutes.contains(route)) {
      _activeRoutes.add(route);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> removeRoute(String route) async {
    _activeRoutes.remove(route);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> addOffice(String office) async {
    if (!_officeLocations.contains(office)) {
      _officeLocations.add(office);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> removeOffice(String office) async {
    _officeLocations.remove(office);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateOfficeName(String oldName, String newName) async {
    final index = _officeLocations.indexOf(oldName);
    if (index != -1) {
      _officeLocations[index] = newName;
      // Update admins linked to this branch
      for (var i = 0; i < _admins.length; i++) {
        if (_admins[i].branchName == oldName) {
          final admin = _admins[i];
          final updatedAdmin = AdminUser(
            id: admin.id,
            name: admin.name,
            email: admin.email,
            phoneNumber: admin.phoneNumber,
            role: admin.role,
            branchName: newName,
            pin: admin.pin,
            isActive: admin.isActive,
            permissions: admin.permissions,
          );
          await addAdmin(updatedAdmin);
        }
      }
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateFeatureToggle(String key, bool value) async {
    _featureToggles[key] = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> addCargoService(Map<String, dynamic> service) async {
    try {
      await ApiService.addService({
        'name': service['title'],
        'description': service['description'],
        'iconCode': service['iconCode'],
        'colorValue': service['colorValue'],
      });
      await _loadSettings(); // Refresh list
      notifyListeners();
    } catch (e) {
      appLogger.i('Error adding service: $e');
    }
  }

  Future<void> updateCargoService(int index, Map<String, dynamic> service) async {
    try {
      final serviceId = _cargoServices[index]['id'];
      if (serviceId != null) {
        await ApiService.updateService(serviceId is int ? serviceId : 0, {
          'name': service['title'],
          'description': service['description'],
          'iconCode': service['iconCode'],
          'colorValue': service['colorValue'],
          'isActive': service['isActive'] ?? true,
        });
      }
      
      // Update local state anyway for immediate UI response (Optimistic Update)
      _cargoServices[index] = { ..._cargoServices[index], ...service };
      notifyListeners();
    } catch (e) {
      appLogger.i('Update failed: $e');
      // If server fails, we still keep the local change for testing
      _cargoServices[index] = { ..._cargoServices[index], ...service };
      notifyListeners();
    }
  }

  Future<void> deleteCargoService(int index) async {
    try {
      final serviceId = _cargoServices[index]['id'];
      if (serviceId != null) {
        await ApiService.deleteService(serviceId);
        await _loadSettings();
        notifyListeners();
      }
    } catch (e) {
      appLogger.i('Error deleting service: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await ApiService.saveSettings(_settingsId, {
        'shippingRate': _shippingRatePerKg,
        'activeRoutes': _activeRoutes,
        'officeLocations': _officeLocations,
        'featureToggles': _featureToggles,
        // We no longer save services here as they have their own endpoint
      });
    } catch (e) {
      appLogger.i('Error saving settings: $e');
    }
  }
}
