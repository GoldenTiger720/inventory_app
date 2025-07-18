import 'product.dart';

enum CountingStatus { pending, counted, confirmed }

class InventoryItem {
  final String id;
  final Product product;
  final int expectedQuantity;
  final int? countedQuantity;
  final CountingStatus status;
  final String? location;
  final DateTime? countedAt;
  final String? notes;

  const InventoryItem({
    required this.id,
    required this.product,
    required this.expectedQuantity,
    this.countedQuantity,
    required this.status,
    this.location,
    this.countedAt,
    this.notes,
  });

  int get variance {
    if (countedQuantity == null) return 0;
    return countedQuantity! - expectedQuantity;
  }

  bool get hasVariance => variance != 0;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      product: Product.fromJson(json['product'] ?? {}),
      expectedQuantity: json['expected_quantity'] ?? 0,
      countedQuantity: json['counted_quantity'],
      status: _parseStatus(json['status']),
      location: json['location'],
      countedAt: json['counted_at'] != null 
          ? DateTime.parse(json['counted_at']) 
          : null,
      notes: json['notes'],
    );
  }

  static CountingStatus _parseStatus(String? status) {
    switch (status) {
      case 'counted':
        return CountingStatus.counted;
      case 'confirmed':
        return CountingStatus.confirmed;
      default:
        return CountingStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'expected_quantity': expectedQuantity,
      'counted_quantity': countedQuantity,
      'status': status.name,
      'location': location,
      'counted_at': countedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  InventoryItem copyWith({
    String? id,
    Product? product,
    int? expectedQuantity,
    int? countedQuantity,
    CountingStatus? status,
    String? location,
    DateTime? countedAt,
    String? notes,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      product: product ?? this.product,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      status: status ?? this.status,
      location: location ?? this.location,
      countedAt: countedAt ?? this.countedAt,
      notes: notes ?? this.notes,
    );
  }
}