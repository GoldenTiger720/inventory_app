class Product {
  final String id;
  final String code;
  final String name;
  final String description;
  final double price;
  final double? cost;
  final int currentQuantity;
  final String? location;
  final String? unit;
  final bool isActive;

  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    this.cost,
    required this.currentQuantity,
    this.location,
    this.unit,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      cost: json['cost']?.toDouble(),
      currentQuantity: json['current_quantity'] ?? 0,
      location: json['location'],
      unit: json['unit'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'price': price,
      'cost': cost,
      'current_quantity': currentQuantity,
      'location': location,
      'unit': unit,
      'is_active': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    double? price,
    double? cost,
    int? currentQuantity,
    String? location,
    String? unit,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      location: location ?? this.location,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
    );
  }
}