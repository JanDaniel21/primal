// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_scaffold.dart';



class DatabaseHelper {
  // singleton
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('primal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // USERS TABLE (for login)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // ACCOUNTS TABLE (for banks/accounts)
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bankName TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE spendings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Optional: insert a default test user (admin)
    await db.insert('users', {
      'username': 'admin',
      'password': '1234', // plaintext for testing only
    });

    // Optional: insert a sample account for testing
    await db.insert('accounts', {
      'bankName': 'AirBank',
      'balance': 12500500.00,
    });

    // Optional: insert spendings
    await db.insert('spendings', {
      'category': 'Food',
      'amount': 250.75,
      'date': '2024-06-01',
    });

    await db.insert('spendings', {
      'category': 'Transport',
      'amount': 120.00,
      'date': '2024-06-02',
    });

    await db.insert('spendings', {
      'category': 'Entertainment',
      'amount': 300.50,
      'date': '2024-06-03',
    });
  }

  // ----------------------------
  // USER (LOGIN) METHODS
  // ----------------------------

  /// Returns the user row if username+password match, otherwise null.
  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// Create a user (returns inserted id). Replaces on conflict (username UNIQUE).
  Future<int> createUser(String username, String password) async {
    final db = await database;
    return await db.insert(
      'users',
      {'username': username, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ----------------------------
  // ACCOUNT (BANK) METHODS
  // ----------------------------

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('accounts', row);
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await database;
    return await db.query('accounts', orderBy: 'id DESC');
  }

  Future<int> updateAccount(int id, String bankName, double balance) async {
    final db = await database;
    return await db.update(
      'accounts',
      {'bankName': bankName, 'balance': balance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    return await getAccounts();
  }
    

    // ----------------------------
    // NET WORTH
    // ----------------------------

    /// Returns the sum of all account balances as double.
    Future<double> computeNetWorth() async {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(balance) as networth FROM accounts');

      final value = result.first['networth'];
      if (value == null) return 0.0;

      // value may be int or double (or string), handle safely
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;

      return 0.0;
    }

  // ----------------------------
  // TOtal SPENDING 
  // ----------------------------

  /// Returns the sum of all spendings as double.
  Future<double> computeTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as totalspending FROM spendings');

    final value = result.first['totalspending'];
    if (value == null) return 0.0;

    // value may be int or double (or string), handle safely
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;

    return 0.0;
  }
}
