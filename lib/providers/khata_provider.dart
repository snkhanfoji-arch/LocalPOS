import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../models/khata_entry.dart';
import '../services/db_service.dart';

class KhataCustomersNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  KhataCustomersNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await DbService.instance.getAllCustomers();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCustomer(String name, String phone) async {
    try {
      final newCustomer = Customer(
        name: name,
        phone: phone,
        balance: 0.0,
      );
      await DbService.instance.insertCustomer(newCustomer);
      await refresh();
    } catch (e) {
      // Handle error in UI
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await DbService.instance.deleteCustomer(id);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }
}

final khataCustomersProvider = StateNotifierProvider<KhataCustomersNotifier, AsyncValue<List<Customer>>>((ref) {
  return KhataCustomersNotifier();
});

// Provider to manage entries for an individual customer
class CustomerEntriesNotifier extends StateNotifier<AsyncValue<List<KhataEntry>>> {
  final int customerId;
  final Ref _ref;

  CustomerEntriesNotifier(this._ref, this.customerId) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await DbService.instance.getKhataEntriesForCustomer(customerId);
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addEntry(double amount, String type, String description) async {
    try {
      final entry = KhataEntry(
        customerId: customerId,
        amount: amount,
        type: type,
        description: description,
        dateTime: DateTime.now().toIso8601String(),
      );
      await DbService.instance.insertKhataEntry(entry);
      await refresh();
      // Also vital to refresh the main customer list so their balances are accurate!
      _ref.read(khataCustomersProvider.notifier).refresh();
    } catch (e) {
      // Handle
    }
  }

  Future<void> removeEntry(int entryId, double amount, String type) async {
    try {
      await DbService.instance.deleteKhataEntry(entryId, customerId, amount, type);
      await refresh();
      _ref.read(khataCustomersProvider.notifier).refresh();
    } catch (e) {
      // Handle
    }
  }
}

// Family provider to dynamically fetch/manage entries for a specific customer
final customerEntriesProvider = StateNotifierProvider.family<CustomerEntriesNotifier, AsyncValue<List<KhataEntry>>, int>((ref, customerId) {
  return CustomerEntriesNotifier(ref, customerId);
});
