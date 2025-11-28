// lib/backend/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

  // bump the version when you change schema; current is 5
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // USERS TABLE
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // ACCOUNTS TABLE
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bankName TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    // SPENDINGS TABLE
    await db.execute('''
      CREATE TABLE IF NOT EXISTS spendings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // SAVINGS TABLE (includes 'current' to represent current saved amount)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target REAL NOT NULL,
        current REAL NOT NULL DEFAULT 0,
        color TEXT NOT NULL,
        targetDate TEXT NOT NULL
      )
    ''');

    // HISTORY: contributions to each saving
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saving_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        savingId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (savingId) REFERENCES savings(id) ON DELETE CASCADE
      )
    ''');

    // seed sample data (optional)
    await db.insert('users', {'username': 'admin', 'password': '1234'});

    await db.insert('accounts', {
      'bankName': 'AirBank',
      'balance': 12500500.0,
    });

    await db.insert('spendings', {
      'category': 'Food',
      'amount': 250.75,
      'date': '2024-06-01',
    });

    await db.insert('savings', {
      'name': 'Emergency Fund',
      'target': 50000.0,
      'current': 12540.0,
      'color': '2EA66F',
      'targetDate': '2025-12-31',
    });

    await db.insert('saving_history', {
      'savingId': 1,
      'amount': 12540.0,
      'date': '2025-01-11',
      'note': 'Initial seed',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Old versions may lack some tables/columns; migrate safely.

    if (oldVersion < 2) {
      // create spendings if missing
      await db.execute('''
        CREATE TABLE IF NOT EXISTS spendings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // create savings table if missing (basic)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target REAL NOT NULL,
          color TEXT NOT NULL,
          targetDate TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // add current column to savings if not present
      try {
        await db.execute('ALTER TABLE savings ADD COLUMN current REAL NOT NULL DEFAULT 0');
      } catch (_) {
        // might already exist on some devices — ignore
      }
    }

    if (oldVersion < 5) {
      // create saving_history if missing
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saving_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          savingId INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (savingId) REFERENCES savings(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ----------------------------
  // USER METHODS (unchanged)
  // ----------------------------
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

  Future<int> createUser(String username, String password) async {
    final db = await database;
    return await db.insert(
      'users',
      {'username': username, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ----------------------------
  // ACCOUNT METHODS (unchanged)
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

  Future<double> computeNetWorth() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(balance) as networth FROM accounts');
    final value = result.first['networth'];
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ----------------------------
  // SPENDINGS METHODS (unchanged)
  // ----------------------------
  Future<int> insertSpending(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('spendings', row);
  }

  Future<List<Map<String, dynamic>>> getSpendings({String? orderBy}) async {
    final db = await database;
    return await db.query('spendings', orderBy: orderBy ?? 'date DESC');
  }

  Future<double> computeTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as totalspending FROM spendings');

    final value = result.first['totalspending'];
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ----------------------------
  // SAVINGS METHODS (new / updated)
  // ----------------------------

  /// Insert a new saving. Expect keys: name, target, color, targetDate, (optional) current
  Future<int> insertSaving(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('savings', row);
  }

  /// Get all savings (most recent first)
  Future<List<Map<String, dynamic>>> getSavings() async {
    final db = await database;
    return await db.query('savings', orderBy: 'id DESC');
  }

  Future<int> updateSaving(int id, String name, double target, String color, String targetDate) async {
    final db = await database;
    return await db.update(
      'savings',
      {
        'name': name,
        'target': target,
        'color': color,
        'targetDate': targetDate,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update only name and/or color
  Future<int> renameSaving(int id, String newName) async {
    final db = await database;
    return await db.update('savings', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> changeSavingColor(int id, String colorHex) async {
    final db = await database;
    return await db.update('savings', {'color': colorHex}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSaving(int id) async {
    final db = await database;
    return await db.delete('savings', where: 'id = ?', whereArgs: [id]);
  }

  /// Add a contribution to a saving: insert into history AND increment savings.current
  Future<void> addSavingContribution(int savingId, double amount, String date, {String? note}) async {
    final db = await database;
    await db.insert('saving_history', {
      'savingId': savingId,
      'amount': amount,
      'date': date,
      'note': note,
    });

    // update current
    await db.rawUpdate('UPDATE savings SET current = current + ? WHERE id = ?', [amount, savingId]);
  }

  Future<List<Map<String, dynamic>>> getSavingHistory(int savingId) async {
    final db = await database;
    return await db.query('saving_history', where: 'savingId = ?', whereArgs: [savingId], orderBy: 'date DESC');
  }

  /// compute sum of current saved across all savings
  Future<double> computeTotalSaved() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(current) as total FROM savings');
    final value = result.first['total'];
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// compute sum of targets (goals)
  Future<double> computeTotalGoals() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(target) as totalGoal FROM savings');
    final value = result.first['totalGoal'];
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
