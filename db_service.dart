import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/khata_entry.dart';

class DbService {
  static final DbService instance = DbService._init();
  static Database? _database;

  DbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('poskhata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT NOT NULL,
        price REAL NOT NULL,
        stock REAL NOT NULL,
        category TEXT NOT NULL,
        lowStockThreshold REAL NOT NULL DEFAULT 5.0
      )
    ''');

    // 2. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 3. Sales Table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateTime TEXT NOT NULL,
        itemsJson TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discountPercentage REAL NOT NULL DEFAULT 0.0,
        taxPercentage REAL NOT NULL DEFAULT 0.0,
        total REAL NOT NULL,
        customerId INTEGER
      )
    ''');

    // 4. Khata Entries Table
    await db.execute('''
      CREATE TABLE khata_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Seed some initial products for Chicken & Electrical to make it useful immediately
    await db.insert('products', {
      'name': 'Desi Chicken (دیسی مرغی) per kg',
      'barcode': '111111',
      'price': 650.0,
      'stock': 15.0,
      'category': 'Chicken',
      'lowStockThreshold': 5.0
    });
    await db.insert('products', {
      'name': 'Broiler Chicken (برائلر مرغی) per kg',
      'barcode': '222222',
      'price': 480.0,
      'stock': 40.0,
      'category': 'Chicken',
      'lowStockThreshold': 8.0
    });
    await db.insert('products', {
      'name': 'LED Bulb 12W (ایل ای ڈی بلب)',
      'barcode': '333333',
      'price': 220.0,
      'stock': 50.0,
      'category': 'Electrical',
      'lowStockThreshold': 10.0
    });
    await db.insert('products', {
      'name': 'Copper Wire 3/29 (تانبے کی تار)',
      'barcode': '444444',
      'price': 4500.0,
      'stock': 3.0,
      'category': 'Electrical',
      'lowStockThreshold': 5.0
    });
  }

  // --- CRUD Products ---
  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProductStock(int id, double newStock) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Customers ---
  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete('khata_entries', where: 'customerId = ?', whereArgs: [id]);
      return await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- CRUD Khata Entries ---
  Future<int> insertKhataEntry(KhataEntry entry) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Insert Entry
      final id = await txn.insert('khata_entries', entry.toMap());

      // Update customer balance: debit increases, credit decreases
      final adjustment = entry.type == 'debit' ? entry.amount : -entry.amount;
      await txn.execute('''
        UPDATE customers 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [adjustment, entry.customerId]);

      return id;
    });
  }

  Future<List<KhataEntry>> getKhataEntriesForCustomer(int customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'khata_entries',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'dateTime DESC',
    );
    return result.map((json) => KhataEntry.fromMap(json)).toList();
  }

  Future<int> deleteKhataEntry(int entryId, int customerId, double amount, String type) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Revert customer balance: if card was debit, it added balance, so now subtract it
      final revertAdjustment = type == 'debit' ? -amount : amount;
      await txn.execute('''
        UPDATE customers 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [revertAdjustment, customerId]);

      // Delete entry
      return await txn.delete(
        'khata_entries',
        where: 'id = ?',
        whereArgs: [entryId],
      );
    });
  }

  // --- CRUD Sales ---
  Future<int> insertSale(Sale sale) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Deduct Stock
      for (final item in sale.items) {
        await txn.execute('''
          UPDATE products 
          SET stock = stock - ? 
          WHERE id = ?
        ''', [item.quantity, item.id]);
      }

      // If linked to customer as a debit sale
      if (sale.customerId != null && sale.total > 0) {
        // Create a debit Khata entry
        final khata = KhataEntry(
          customerId: sale.customerId!,
          amount: sale.total,
          type: 'debit',
          description: 'Sales Invoice ID: (POS)',
          dateTime: sale.dateTime,
        );
        await txn.insert('khata_entries', khata.toMap());

        // Update customer balance
        await txn.execute('''
          UPDATE customers
          SET balance = balance + ?
          WHERE id = ?
        ''', [sale.total, sale.customerId]);
      }

      // Insert Sale
      return await txn.insert('sales', sale.toMap());
    });
  }

  Future<List<Sale>> getAllSales() async {
    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'dateTime DESC');
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('products');
    await db.delete('customers');
    await db.delete('sales');
    await db.delete('khata_entries');
  }
}
