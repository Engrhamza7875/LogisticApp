import '../models/shipment.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/shipment_service.dart';
import '../core/role_middleware.dart';
import 'base_repository.dart';

class ShipmentRepository extends BaseRepository {
  /// Fetches shipments based on user role and branch constraints
  Future<List<Shipment>> getShipments() async {
    return await safeCall(() async {
      // The backend scopes results to the authenticated user's role and branch.
      final List<Shipment> allShipments = await ShipmentService.getShipments();

      return allShipments;
    });
  }

  /// Adds a new booking
  Future<void> createBooking(
    Shipment shipment,
    AppUser user, {
    required String senderName,
    required String receiverName,
    required String receiverPhone,
    required double total,
  }) async {
    await safeCall(() async {
      // Ensure shipment is tagged with user's email if they are a regular user
      final updatedShipment = Shipment(
        id: shipment.id,
        trackingNumber: shipment.trackingNumber,
        itemName: shipment.itemName,
        origin: shipment.origin,
        destination: shipment.destination,
        status: ShipmentStatus.booked,
        expectedDate: shipment.expectedDate,
        weight: shipment.weight,
        type: shipment.type,
        userEmail: user.isUser ? user.email : shipment.userEmail,
        branchId: shipment.branchId, // Selected by user during booking
        steps: shipment.steps,
      );

      await ApiService.saveBooking({
        'bookingId': updatedShipment.trackingNumber,
        'itemName': updatedShipment.itemName,
        'cargoType': updatedShipment.type,
        'fromCity': updatedShipment.origin,
        'toCity': updatedShipment.destination,
        'senderName': senderName,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'weight': updatedShipment.weight,
        'total': total,
        'branchId': updatedShipment.branchId,
      });
      await ShipmentService.cacheShipment(updatedShipment);
    });
  }

  /// Updates shipment status
  Future<void> updateStatus(String shipmentId, ShipmentStatus newStatus, AppUser user) async {
    await safeCall(() async {
      // 1. Fetch current shipment
      final shipments = await ShipmentService.getShipments();
      final shipment = shipments.firstWhere((s) => s.id == shipmentId);

      // 2. Validate permission
      if (!RoleMiddleware.canUpdateStatus(user, shipment, newStatus)) {
        throw Exception('Unauthorized: You do not have permission to update this shipment status.');
      }

      // 3. Update tracking step
      await ShipmentService.addTrackingStep(
        shipmentId: shipment.trackingNumber,
        title: _getStatusTitle(newStatus),
        subtitle: _getStatusSubtitle(newStatus, user),
        status: newStatus.index,
      );
    });
  }

  String _getStatusTitle(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.booked: return 'Booking Confirmed';
      case ShipmentStatus.received: return 'Shipment Received';
      case ShipmentStatus.processing: return 'Processing at Warehouse';
      case ShipmentStatus.inTransit: return 'In Transit';
      case ShipmentStatus.outForDelivery: return 'Out for Delivery';
      case ShipmentStatus.delivered: return 'Shipment Delivered';
      case ShipmentStatus.cancelled: return 'Shipment Cancelled';
    }
  }

  String _getStatusSubtitle(ShipmentStatus status, AppUser user) {
    switch (status) {
      case ShipmentStatus.booked: return 'Booking initiated by user';
      case ShipmentStatus.received: return 'Received at ${user.branchName ?? 'Branch'}';
      case ShipmentStatus.processing: return 'Preparing for long-haul transit';
      case ShipmentStatus.inTransit: return 'Shipment is moving to destination city';
      case ShipmentStatus.outForDelivery: return 'Courier is on the way to your door';
      case ShipmentStatus.delivered: return 'Successfully delivered and signed';
      case ShipmentStatus.cancelled: return 'Cancelled by administrative action';
    }
  }
}
