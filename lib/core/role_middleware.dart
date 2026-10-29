import '../models/app_user.dart';
import '../models/shipment.dart';

class RoleMiddleware {
  /// Checks if a user has access to a specific shipment based on their role and branch.
  static bool canAccessShipment(AppUser user, Shipment shipment) {
    if (user.isSuperAdmin) return true;

    if (user.isOfficeAdmin) {
      // Office Admin can only access shipments of their assigned branch
      return shipment.branchId == user.branchId;
    }

    if (user.isDriver) {
      // Driver can only access shipments assigned to them
      return shipment.driverId == user.id;
    }

    if (user.isUser) {
      // User can only access their own shipments
      return shipment.userEmail == user.email;
    }

    return false;
  }

  /// Checks if a user can update the status of a shipment to a specific next status.
  static bool canUpdateStatus(AppUser user, Shipment currentShipment, ShipmentStatus nextStatus) {
    if (user.isSuperAdmin) return true;

    if (user.isOfficeAdmin) {
      // Office Admin can update status for shipments in their branch
      if (currentShipment.branchId != user.branchId) return false;
      
      // Office Admin can handle most statuses except those usually handled by drivers in the field
      return true;
    }

    if (user.isDriver) {
      // Driver can only update shipments assigned to them
      if (currentShipment.driverId != user.id) return false;

      // Drivers typically only update IN_TRANSIT, OUT_FOR_DELIVERY, and DELIVERED
      return [
        ShipmentStatus.inTransit,
        ShipmentStatus.outForDelivery,
        ShipmentStatus.delivered
      ].contains(nextStatus);
    }

    return false; // Users cannot update status
  }

  /// Determines if a user can manage other users.
  static bool canManageUsers(AppUser user) {
    return user.isSuperAdmin;
  }

  /// Determines if a user can manage branches.
  static bool canManageBranches(AppUser user) {
    return user.isSuperAdmin;
  }
}
