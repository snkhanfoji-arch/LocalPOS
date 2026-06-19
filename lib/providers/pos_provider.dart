import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../services/db_service.dart';

final pkrFormatter = NumberFormat.currency(
  locale: 'en_PK',
  symbol: 'Rs. ',
  decimalDigits: 2,
);

class CartState {
  final Map<int, SaleItem> items; // Key is Product ID
  final double discountPercentage;
  final double taxPercentage;
  final int? selectedCustomerId;

  CartState({
    required this.items,
    this.discountPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.selectedCustomerId,
  });

  double get subtotal {
    return items.values.fold(0.0, (sum, item) => sum + item.total);
  }

  double get discountAmount {
    return subtotal * (discountPercentage / 100);
  }

  double get taxAmount {
    return (subtotal - discountAmount) * (taxPercentage / 100);
  }

  double get total {
    return subtotal - discountAmount + taxAmount;
  }

  CartState copyWith({
    Map<int, SaleItem>? items,
    double? discountPercentage,
    double? taxPercentage,
    int? selectedCustomerId,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      selectedCustomerId: clearCustomer ? null : (selectedCustomerId ?? this.selectedCustomerId),
    );
  }
}

class PosNotifier extends StateNotifier<CartState> {
  final Ref _ref;

  PosNotifier(this._ref) : super(CartState(items: {}));

  void addToCart(Product product, {double quantity = 1.0}) {
    final currentItems = Map<int, SaleItem>.from(state.items);

    if (currentItems.containsKey(product.id)) {
      final existing = currentItems[product.id!]!;
      final newQty = existing.quantity + quantity;
      currentItems[product.id!] = SaleItem(
        id: product.id!,
        name: product.name,
        price: product.price,
        quantity: newQty,
        total: product.price * newQty,
      );
    } else {
      currentItems[product.id!] = SaleItem(
        id: product.id!,
        name: product.name,
        price: product.price,
        quantity: quantity,
        total: product.price * quantity,
      );
    }

    state = state.copyWith(items: currentItems);
  }

  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final currentItems = Map<int, SaleItem>.from(state.items);
    if (currentItems.containsKey(productId)) {
      final existing = currentItems[productId]!;
      currentItems[productId] = SaleItem(
        id: productId,
        name: existing.name,
        price: existing.price,
        quantity: quantity,
        total: existing.price * quantity,
      );
      state = state.copyWith(items: currentItems);
    }
  }

  void removeFromCart(int productId) {
    final currentItems = Map<int, SaleItem>.from(state.items);
    currentItems.remove(productId);
    state = state.copyWith(items: currentItems);
  }

  void setDiscount(double percentage) {
    state = state.copyWith(discountPercentage: percentage);
  }

  void setTax(double percentage) {
    state = state.copyWith(taxPercentage: percentage);
  }

  void selectCustomer(int? customerId) {
    state = state.copyWith(selectedCustomerId: customerId, clearCustomer: customerId == null);
  }

  void clearCart() {
    state = CartState(items: {});
  }

  Future<Sale?> checkout() async {
    if (state.items.isEmpty) return null;

    final sale = Sale(
      dateTime: DateTime.now().toIso8601String(),
      items: state.items.values.toList(),
      subtotal: state.subtotal,
      discountPercentage: state.discountPercentage,
      taxPercentage: state.taxPercentage,
      total: state.total,
      customerId: state.selectedCustomerId,
    );

    final insertedId = await DbService.instance.insertSale(sale);
    final completedSale = Sale(
      id: insertedId,
      dateTime: sale.dateTime,
      items: sale.items,
      subtotal: sale.subtotal,
      discountPercentage: sale.discountPercentage,
      taxPercentage: sale.taxPercentage,
      total: sale.total,
      customerId: sale.customerId,
    );

    clearCart();
    return completedSale;
  }
}

final posProvider = StateNotifierProvider<PosNotifier, CartState>((ref) {
  return PosNotifier(ref);
});

// A provider to fetch all products for POS
final posProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return await DbService.instance.getAllProducts();
});

// A provider to fetch customers for linking
final posCustomersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  return await DbService.instance.getAllCustomers();
});
