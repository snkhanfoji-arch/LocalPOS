class Product {
  final int? id;
  final String name;
  final String barcode;
  final double price;
  final double stock;
  final String category; // 'Chicken' or 'Electrical'
  final double lowStockThreshold;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
    required this.category,
    this.lowStockThreshold = 5.0,
  });

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? price,
    double? stock,
    String? category,
    double? lowStockThreshold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock': stock,
      'category': category,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String,
      price: (map['price'] as num).toDouble(),
      stock: (map['stock'] as num).toDouble(),
      category: map['category'] as String,
      lowStockThreshold: (map['lowStockThreshold'] as num? ?? 5.0).toDouble(),
    );
  }
}
