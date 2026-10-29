import 'dart:async';
import 'package:sabcargo/services/logger_service.dart';
// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shipment.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ShipmentService {
  static const String _shipmentsKey = 'sabcargo_shipments';

  // Real-time synchronization stream
  static final _shipmentStreamController = StreamController<List<Shipment>>.broadcast();
  static Stream<List<Shipment>> get shipmentStream => _shipmentStreamController.stream;

  /// Trigger a refresh of the shipment stream
  static Future<void> refresh() async {
    await getShipments();
  }
  static Future<List<Shipment>> getShipments() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = await _cacheKey();

    // 1. Try to load from Local Storage immediately for speed
    final String? cachedData = prefs.getString(cacheKey);
    List<Shipment> localList = [];
    if (cachedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        localList = jsonList.map((j) => Shipment.fromJson(j)).toList();
      } catch (e) {
        appLogger.i('Error loading local shipments: $e');
      }
    }

    // Return cached data immediately, then refresh it from the authenticated API.
    if (localList.isNotEmpty) {
      unawaited(
        _fetchCloudAndSync(prefs, cacheKey).then<void>((_) {}).catchError((error) {
          appLogger.e('Background shipment refresh failed: $error');
        }),
      );
      return localList;
    }

    return _fetchCloudAndSync(prefs, cacheKey);
  }

  static Future<String> _cacheKey() async {
    final role = await AuthService.getUserRole();
    final email = (await AuthService.getUserEmail()).toLowerCase();
    return '${_shipmentsKey}_${role}_$email';
  }

  /// Helper to fetch from cloud and update stream/cache without blocking UI
  static Future<List<Shipment>> _fetchCloudAndSync(
    SharedPreferences prefs,
    String cacheKey,
  ) async {
    final cloudData = await ApiService.fetchShipments();
    final remoteList = cloudData.map(Shipment.fromJson).toList();
    final encoded = jsonEncode(remoteList.map((s) => s.toJson()).toList());
    await prefs.setString(cacheKey, encoded);
    _shipmentStreamController.add(remoteList);
    return remoteList;
  }

  /// Add a new shipment (locally and in MongoDB through the API)
  static Future<void> addShipment(Shipment shipment, {String? userEmail}) async {
    final Map<String, dynamic> shipmentJson = shipment.toJson();
    
    await ApiService.saveShipment(shipmentJson, userEmail: userEmail);

    // Update local cache
    final List<Shipment> current = await getShipments();
    if (!current.any((s) => s.id == shipment.id)) {
      current.insert(0, shipment);
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = await _cacheKey();
      final String encoded = jsonEncode(current.map((s) => s.toJson()).toList());
      await prefs.setString(cacheKey, encoded);
      await refresh();
    }
  }

  static Future<void> cacheShipment(Shipment shipment) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = await _cacheKey();
    final cachedData = prefs.getString(cacheKey);
    final shipments = cachedData == null
        ? <Shipment>[]
        : (jsonDecode(cachedData) as List<dynamic>)
              .map((item) => Shipment.fromJson(Map<String, dynamic>.from(item)))
              .toList();
    shipments.removeWhere((item) => item.trackingNumber == shipment.trackingNumber);
    shipments.insert(0, shipment);
    await prefs.setString(
      cacheKey,
      jsonEncode(shipments.map((item) => item.toJson()).toList()),
    );
    _shipmentStreamController.add(shipments);
  }

  /// Search for a shipment (checking all sources)
  static Future<Shipment?> trackShipment(String trackingNumber) async {
    final normalizedNumber = trackingNumber.trim().toUpperCase();
    final cloudData = await ApiService.fetchShipments();
    for (final row in cloudData) {
      final shipment = Shipment.fromJson(row);
      if (shipment.trackingNumber.trim().toUpperCase() == normalizedNumber) {
        return shipment;
      }
    }
    return null;
  }

  /// Get status statistics
  static Future<Map<String, int>> getStats() async {
    final List<Shipment> all = await getShipments();
    return {
      'total': all.length,
      'active': all.where((s) => 
        s.status == ShipmentStatus.inTransit || 
        s.status == ShipmentStatus.outForDelivery ||
        s.status == ShipmentStatus.booked
      ).length,
      'delivered': all.where((s) => s.status == ShipmentStatus.delivered).length,
    };
  }

  /// Add a tracking event
  static Future<void> addTrackingStep({
    required String shipmentId,
    required String title,
    required String subtitle,
    int? status,
  }) async {
    final step = {
      'title': title,
      'subtitle': subtitle,
      'time': '${DateTime.now().day}/${DateTime.now().month} ${DateTime.now().hour}:${DateTime.now().minute}',
      'isCompleted': true,
      'isCurrent': true,
    };

    await ApiService.addTrackingStep(shipmentId, step, status ?? -1);

    // 2. Update local cache
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = await _cacheKey();
    final String? data = prefs.getString(cacheKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      final List<Shipment> list = jsonList.map((j) => Shipment.fromJson(j)).toList();
      final idx = list.indexWhere(
        (s) => s.id == shipmentId || s.trackingNumber == shipmentId,
      );
      if (idx != -1) {
        final s = list[idx];
        final newSteps = List<TrackingStep>.from(s.steps);
        // Mark others as not current
        for (int i = 0; i < newSteps.length; i++) {
          newSteps[i] = TrackingStep(
            title: newSteps[i].title,
            subtitle: newSteps[i].subtitle,
            time: newSteps[i].time,
            isCompleted: true,
            isCurrent: false,
          );
        }
        newSteps.add(TrackingStep.fromJson(step));
        
        final updatedShipment = Shipment(
          id: s.id,
          trackingNumber: s.trackingNumber,
          itemName: s.itemName,
          origin: s.origin,
          destination: s.destination,
          status: status != null &&
                  status >= 0 &&
                  status < ShipmentStatus.values.length
              ? ShipmentStatus.values[status]
              : s.status,
          expectedDate: s.expectedDate,
          weight: s.weight,
          type: s.type,
          userEmail: s.userEmail,
          branchId: s.branchId,
          driverId: s.driverId,
          steps: newSteps,
        );
        list[idx] = updatedShipment;
        await prefs.setString(cacheKey, jsonEncode(list.map((sh) => sh.toJson()).toList()));
        _shipmentStreamController.add(list);
      }
    }
  }
}
