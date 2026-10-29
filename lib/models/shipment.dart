import 'package:flutter/material.dart';
import '../core/colors.dart';

enum ShipmentStatus { 
  booked,      // 0: Created by user
  received,    // 1: Received at branch
  processing,  // 2: Being prepared for transit
  inTransit,   // 3: On the way
  outForDelivery, // 4: Local delivery
  delivered,   // 5: Finished
  cancelled    // 6: Aborted
}

class TrackingStep {
  final String title;
  final String subtitle;
  final String time;
  final bool isCompleted;
  final bool isCurrent;

  const TrackingStep({
    required this.title,
    required this.subtitle,
    required this.time,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'time': time,
        'isCompleted': isCompleted,
        'isCurrent': isCurrent,
      };

  factory TrackingStep.fromJson(Map<String, dynamic> json) => TrackingStep(
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        isCompleted: json['isCompleted'] ?? false,
        isCurrent: json['isCurrent'] ?? false,
      );
}

class Shipment {
  final String id;
  final String trackingNumber;
  final String itemName;
  final String origin;
  final String destination;
  final ShipmentStatus status;
  final String expectedDate;
  final double weight;
  final String type;
  final String? userEmail;
  final String? branchId;  // Added for branch isolation
  final String? driverId;  // Added for driver assignment
  final List<TrackingStep> steps;

  const Shipment({
    required this.id,
    required this.trackingNumber,
    required this.itemName,
    required this.origin,
    required this.destination,
    required this.status,
    required this.expectedDate,
    required this.weight,
    required this.type,
    this.userEmail,
    this.branchId,
    this.driverId,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackingNumber': trackingNumber,
        'itemName': itemName,
        'origin': origin,
        'destination': destination,
        'status': status.index,
        'expectedDate': expectedDate,
        'weight': weight,
        'type': type,
        'userEmail': userEmail,
        'branchId': branchId,
        'driverId': driverId,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final statusIndex = int.tryParse(json['status']?.toString() ?? '') ?? 0;
    final safeStatusIndex =
        statusIndex >= 0 && statusIndex < ShipmentStatus.values.length
        ? statusIndex
        : 0;
    return Shipment(
        id: json['id']?.toString() ?? '',
        trackingNumber: json['trackingNumber']?.toString() ?? '',
        itemName: json['itemName']?.toString() ?? '',
        origin: json['origin']?.toString() ?? '',
        destination: json['destination']?.toString() ?? '',
        status: ShipmentStatus.values[safeStatusIndex],
        expectedDate: json['expectedDate']?.toString() ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        type: json['type']?.toString() ?? '',
        userEmail: json['userEmail']?.toString(),
        branchId: json['branchId']?.toString(),
        driverId: json['driverId']?.toString(),
        steps: (json['steps'] as List?)
            ?.map((s) => TrackingStep.fromJson(Map<String, dynamic>.from(s)))
            .toList() ?? [],
      );
  }

  Color get statusColor {
    switch (status) {
      case ShipmentStatus.booked:
        return AppColors.warning;
      case ShipmentStatus.received:
        return AppColors.info;
      case ShipmentStatus.processing:
        return AppColors.orange;
      case ShipmentStatus.inTransit:
        return AppColors.info;
      case ShipmentStatus.outForDelivery:
        return AppColors.orange;
      case ShipmentStatus.delivered:
        return AppColors.success;
      case ShipmentStatus.cancelled:
        return AppColors.error;
    }
  }

  Color get statusBgColor {
    switch (status) {
      case ShipmentStatus.booked:
        return AppColors.warningLight;
      case ShipmentStatus.received:
        return AppColors.infoLight;
      case ShipmentStatus.processing:
        return AppColors.orangeLight;
      case ShipmentStatus.inTransit:
        return AppColors.infoLight;
      case ShipmentStatus.outForDelivery:
        return AppColors.orangeLight;
      case ShipmentStatus.delivered:
        return AppColors.successLight;
      case ShipmentStatus.cancelled:
        return AppColors.errorLight;
    }
  }

  String get statusLabel {
    switch (status) {
      case ShipmentStatus.booked:
        return 'Booked';
      case ShipmentStatus.received:
        return 'Received';
      case ShipmentStatus.processing:
        return 'Processing';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.outForDelivery:
        return 'Out for Delivery';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Sample data
final List<Shipment> sampleShipments = [
  Shipment(
    id: '1',
    trackingNumber: 'SAB-2024-001',
    itemName: 'MacBook Pro M3',
    origin: 'Dubai, UAE',
    destination: 'Karachi, Pakistan',
    status: ShipmentStatus.inTransit,
    expectedDate: 'Apr 10, 2026',
    weight: 2.5,
    type: 'Air Freight',
    steps: [
      TrackingStep(title: 'Order Picked Up', subtitle: 'Dubai Warehouse', time: 'Apr 3, 09:00 AM', isCompleted: true),
      TrackingStep(title: 'Customs Cleared', subtitle: 'Dubai International', time: 'Apr 4, 02:00 PM', isCompleted: true),
      TrackingStep(title: 'In Transit', subtitle: 'Flight EK-614 en route', time: 'Apr 5, 06:00 AM', isCompleted: false, isCurrent: true),
      TrackingStep(title: 'Out for Delivery', subtitle: 'Karachi Hub', time: 'Estimated Apr 9', isCompleted: false),
      TrackingStep(title: 'Delivered', subtitle: 'Final Destination', time: 'Estimated Apr 10', isCompleted: false),
    ],
  ),
  Shipment(
    id: '2',
    trackingNumber: 'SAB-2024-002',
    itemName: 'Industrial Equipment',
    origin: 'Shanghai, China',
    destination: 'Lahore, Pakistan',
    status: ShipmentStatus.booked,
    expectedDate: 'Apr 22, 2026',
    weight: 120.0,
    type: 'Sea Freight',
    steps: [
      TrackingStep(title: 'Order Confirmed', subtitle: 'Shanghai Port', time: 'Apr 5, 11:00 AM', isCompleted: true),
      TrackingStep(title: 'Awaiting Pickup', subtitle: 'Shanghai Warehouse', time: 'Scheduled Apr 6', isCompleted: false, isCurrent: true),
      TrackingStep(title: 'In Transit', subtitle: 'Sea Route', time: 'Estimated Apr 14', isCompleted: false),
      TrackingStep(title: 'Port Clearance', subtitle: 'Karachi Port', time: 'Estimated Apr 20', isCompleted: false),
      TrackingStep(title: 'Delivered', subtitle: 'Final Destination', time: 'Estimated Apr 22', isCompleted: false),
    ],
  ),
  Shipment(
    id: '3',
    trackingNumber: 'SAB-2024-003',
    itemName: 'Clothing & Textiles',
    origin: 'Istanbul, Turkey',
    destination: 'Islamabad, Pakistan',
    status: ShipmentStatus.delivered,
    expectedDate: 'Mar 28, 2026',
    weight: 35.0,
    type: 'Land Freight',
    steps: [
      TrackingStep(title: 'Order Picked Up', subtitle: 'Istanbul Hub', time: 'Mar 20, 08:00 AM', isCompleted: true),
      TrackingStep(title: 'In Transit', subtitle: 'Turkey-Iran Border', time: 'Mar 23, 03:00 PM', isCompleted: true),
      TrackingStep(title: 'In Transit', subtitle: 'Iran-Pakistan Border', time: 'Mar 26, 10:00 AM', isCompleted: true),
      TrackingStep(title: 'Out for Delivery', subtitle: 'Islamabad Hub', time: 'Mar 28, 09:00 AM', isCompleted: true),
      TrackingStep(title: 'Delivered', subtitle: 'Final Destination', time: 'Mar 28, 02:30 PM', isCompleted: true),
    ],
  ),
];
