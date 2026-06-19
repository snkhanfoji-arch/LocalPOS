class KhataEntry {
  final int? id;
  final int customerId;
  final double amount;
  final String type; // 'debit' (borrowed / owes) or 'credit' (paid / returns)
  final String description;
  final String dateTime;

  KhataEntry({
    this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.description,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'amount': amount,
      'type': type,
      'description': description,
      'dateTime': dateTime,
    };
  }

  factory KhataEntry.fromMap(Map<String, dynamic> map) {
    return KhataEntry(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      description: map['description'] as String? ?? '',
      dateTime: map['dateTime'] as String,
    );
  }
}
