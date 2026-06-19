class Customer {
  final int? id;
  final String name;
  final String phone;
  final double balance; // Positive means debit (owes money - red), Negative/Zero means credit/clear (paid in advance or balanced - green)

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.balance,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    double? balance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      balance: (map['balance'] as num? ?? 0.0).toDouble(),
    );
  }
}
