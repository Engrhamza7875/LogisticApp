import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../models/app_user.dart';
import '../repositories/shipment_repository.dart';
import '../repositories/auth_repository.dart';
import 'shipment_service.dart';

class DriverService extends ChangeNotifier {
  final ShipmentRepository _shipmentRepo = ShipmentRepository();
  final AuthRepository _authRepo = AuthRepository();
  
  List<Shipment> _missions = [];
  bool _isLoading = false;

  List<Shipment> get missions => List.unmodifiable(_missions);
  bool get isLoading => _isLoading;

  DriverService() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Listen to real-time shipment updates
    ShipmentService.shipmentStream.listen((_) => refreshMissions());
    
    await refreshMissions();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshMissions() async {
    final user = await _authRepo.getCurrentUser();
    if (user != null && user.isDriver) {
      _missions = await _shipmentRepo.getShipments();
      notifyListeners();
    }
  }

  Future<void> completeMission(String id) async {
    final user = await _authRepo.getCurrentUser();
    if (user != null) {
      await _shipmentRepo.updateStatus(id, ShipmentStatus.delivered, user);
      await refreshMissions();
    }
  }

  Future<void> startMission(String id) async {
    final user = await _authRepo.getCurrentUser();
    if (user != null) {
      await _shipmentRepo.updateStatus(id, ShipmentStatus.outForDelivery, user);
      await refreshMissions();
    }
  }
}
