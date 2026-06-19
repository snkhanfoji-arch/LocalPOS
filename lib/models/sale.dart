import 'dart:convert';

class Sale {
  final int? id;
  final String dateTime;
  final List<SaleItem> items;
  final double subtotal;
  final double discountPercentage;
  final double taxPercentage;
  final double total;
  final int? customerId;

  Sale({
    this.id,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.discountPercentage,
    required this.taxPercentage,
    required this.total,
    this.customerId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'dateTime': dateTime,
      'itemsJson': jsonEncode(items.map((i) => i.toMap()).toList()),
      'subtotal': subtotal,
      'discountPercentage': discountPercentage,
      'taxPercentage': taxPercentage,
      'total': total,
      'customerId': customerId,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    var decodedItems = <SaleItem>[];
    if (map['itemsJson'] != null) {
      final List<dynamic> list = jsonDecode(map['itemsJson'] as String);
      decodedItems = list.map((item) => SaleItem.fromMap(item as Map<String, dynamic>)).toList();
    }
    return Sale(
      id: map['id'] as int?,
      dateTime: map['dateTime'] as String,
      items: decodedItems,
      subtotal: (map['subtotal'] as num).toDouble(),
      discountPercentage: (map['discountPercentage'] as num? ?? 0).toDouble(),
      taxPercentage: (map['taxPercentage'] as num? ?? 0).toDouble(),
      total: (map['total'] as num).toDouble(),
      customerId: map['customerId'] as int?,
    );
  }
}

class SaleItem {
  final int id; // Product ID
  final String name;
  final double price;
  final double quantity;
  final double total;

  SaleItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}
