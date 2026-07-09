import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/expense_model.dart';
import '../models/setting_model.dart';
import '../models/shift_model.dart';
import 'supabase_service.dart';

/// DatabaseHelper — Singleton untuk mengelola koneksi SQLite.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kasir_nasi_goreng.db');
    return await openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ─── CREATE (fresh install) ────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultData(db);
  }

  // ─── UPGRADE (existing install) ───────────────────────────────────────
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await _insertDefaultSettings(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
        );
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN status TEXT NOT NULL DEFAULT "completed"',
        );
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN nama_pelanggan TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          tanggal    TEXT    NOT NULL,
          kategori   TEXT    NOT NULL,
          keterangan TEXT    NOT NULL,
          jumlah     REAL    NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE transaction_details ADD COLUMN catatan TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE transaction_details ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE expenses ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE users ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute('''
          CREATE TABLE shifts (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id       INTEGER NOT NULL,
            start_time    TEXT    NOT NULL,
            end_time      TEXT,
            starting_cash REAL    NOT NULL,
            expected_cash REAL    NOT NULL,
            actual_cash   REAL,
            difference    REAL,
            status        TEXT    NOT NULL DEFAULT 'open',
            is_synced     INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN image_cloud_url TEXT',
        );
      } catch (_) {}
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT    NOT NULL UNIQUE,
        password TEXT    NOT NULL,
        role     TEXT    NOT NULL CHECK(role IN ('admin','kasir')),
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_menu  TEXT    NOT NULL,
        harga      REAL    NOT NULL,
        kategori   TEXT    NOT NULL,
        is_active  INTEGER NOT NULL DEFAULT 1,
        image_path      TEXT,
        image_cloud_url TEXT,
        is_synced       INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal_waktu     TEXT    NOT NULL,
        total_harga       REAL    NOT NULL,
        metode_pembayaran TEXT    NOT NULL,
        status            TEXT    NOT NULL DEFAULT 'completed',
        nama_pelanggan    TEXT,
        is_synced         INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_details (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        id_transaksi INTEGER NOT NULL,
        id_produk    INTEGER NOT NULL,
        qty          INTEGER NOT NULL,
        subtotal     REAL    NOT NULL,
        catatan      TEXT,
        is_synced    INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_transaksi) REFERENCES transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (id_produk)    REFERENCES products(id)     ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal    TEXT    NOT NULL,
        kategori   TEXT    NOT NULL,
        keterangan TEXT    NOT NULL,
        jumlah     REAL    NOT NULL,
        is_synced  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id       INTEGER NOT NULL,
        start_time    TEXT    NOT NULL,
        end_time      TEXT,
        starting_cash REAL    NOT NULL,
        expected_cash REAL    NOT NULL,
        actual_cash   REAL,
        difference    REAL,
        status        TEXT    NOT NULL DEFAULT 'open',
        is_synced     INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _insertDefaultData(Database db) async {
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });
    await db.insert('users', {
      'username': 'kasir',
      'password': 'kasir123',
      'role': 'kasir',
    });

    await db.insert('products', {
      'nama_menu': 'Nasi Goreng Biasa',
      'harga': 15000,
      'kategori': 'Nasi Goreng',
      'is_active': 1,
    });
    await db.insert('products', {
      'nama_menu': 'Nasi Goreng Spesial',
      'harga': 20000,
      'kategori': 'Nasi Goreng',
      'is_active': 1,
    });
    await db.insert('products', {
      'nama_menu': 'Nasi Goreng Seafood',
      'harga': 25000,
      'kategori': 'Nasi Goreng',
      'is_active': 1,
    });

    await _insertDefaultSettings(db);
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final defaults = {
      SettingKeys.namaToko: 'Nasi Goreng Pak Budi',
      SettingKeys.alamatToko: 'Jl. Makan Enak No. 1',
      SettingKeys.teleponToko: '0812-3456-7890',
      SettingKeys.deskripsiToko: 'Nasi Goreng Lezat & Terjangkau',
      'target_harian': '500000',
    };
    for (final entry in defaults.entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<UserModel?> login(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<List<UserModel>> getAllKasir() async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['kasir'],
      orderBy: 'username ASC',
    );
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': newPassword, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    try {
      await SupabaseService().supabase.from('users').delete().eq('id', id);
    } catch (_) {}
    return await db.delete(
      'users',
      where: 'id = ? AND role = ?',
      whereArgs: [id, 'kasir'],
    );
  }

  Future<bool> isUsernameExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<ProductModel>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'nama_menu ASC');
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  /// Hanya produk yang aktif (untuk kasir)
  Future<List<ProductModel>> getActiveProducts() async {
    final db = await database;
    final sql = '''
      SELECT p.*, COALESCE(SUM(td.qty), 0) as sold_qty
      FROM products p
      LEFT JOIN transaction_details td ON p.id = td.id_produk
      WHERE p.is_active = 1
      GROUP BY p.id
      ORDER BY sold_qty DESC, p.id ASC
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    final map = product.toMap();
    map['is_synced'] = 0;
    int id = await db.insert('products', map);
    SupabaseService().syncData();
    return id;
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    final map = product.toMap();
    map['is_synced'] = 0;
    int res = await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    SupabaseService().syncData();
    return res;
  }

  Future<int> toggleProductActive(int id, bool isActive) async {
    final db = await database;
    int res = await db.update(
      'products',
      {'is_active': isActive ? 1 : 0, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    SupabaseService().syncData();
    return res;
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    // Hapus dari Supabase sekalian kalau lagi online
    try {
      await SupabaseService().supabase.from('products').delete().eq('id', id);
    } catch (_) {}
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> saveTransaction(
    TransactionModel transaction,
    List<TransactionDetailModel> details,
  ) async {
    final db = await database;
    int transactionId = transaction.id ?? 0;
    await db.transaction((txn) async {
      if (transaction.id == null) {
        transactionId = await txn.insert('transactions', transaction.toMap());
      } else {
        final map = transaction.toMap();
        map['is_synced'] = 0;
        await txn.update(
          'transactions',
          map,
          where: 'id = ?',
          whereArgs: [transaction.id],
        );
        await txn.delete(
          'transaction_details',
          where: 'id_transaksi = ?',
          whereArgs: [transaction.id],
        );
      }

      for (final detail in details) {
        final detailMap = detail.toMap();
        detailMap['id_transaksi'] = transactionId;
        // is_synced akan otomatis 0 karena DEFAULT 0
        await txn.insert('transaction_details', detailMap);
      }
    });
    SupabaseService().syncData();
    return transactionId;
  }

  Future<void> deleteTransaction(int transactionId) async {
    final db = await database;
    try {
      await SupabaseService().supabase
          .from('transactions')
          .delete()
          .eq('id', transactionId);
    } catch (_) {}
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<List<TransactionModel>> getActiveOrders() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: "status IN ('pending', 'active')",
      orderBy: 'id ASC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<void> completeTransaction(int transactionId) async {
    final db = await database;
    await db.update(
      'transactions',
      {'status': 'completed', 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    SupabaseService().syncData();
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: "status = 'completed'",
      orderBy: 'id DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByPeriod(String period) async {
    final db = await database;
    String? whereClause;
    final now = DateTime.now();
    switch (period) {
      case 'today':
        final today = now.toIso8601String().substring(0, 10);
        whereClause = "tanggal_waktu LIKE '$today%'";
        break;
      case 'week':
        final weekAgo = now
            .subtract(const Duration(days: 7))
            .toIso8601String()
            .substring(0, 10);
        whereClause = "tanggal_waktu >= '$weekAgo'";
        break;
      case 'month':
        final monthStart =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        whereClause = "tanggal_waktu >= '$monthStart'";
        break;
      default:
        whereClause = "1=1";
    }
    whereClause += " AND status IN ('active', 'completed')";
    final maps = await db.query(
      'transactions',
      where: whereClause,
      orderBy: 'id DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionDetailModel>> getTransactionDetails(
    int transactionId,
  ) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT td.*, p.nama_menu
      FROM transaction_details td
      JOIN products p ON td.id_produk = p.id
      WHERE td.id_transaksi = ?
    ''',
      [transactionId],
    );
    return maps.map((m) => TransactionDetailModel.fromMap(m)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  Future<double> getTodayRevenue() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(total_harga), 0) AS total FROM transactions WHERE status IN ('active', 'completed') AND tanggal_waktu LIKE ?",
      ['$today%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> getTodayOrderCount() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM transactions WHERE status IN ('active', 'completed') AND tanggal_waktu LIKE ?",
      ['$today%'],
    );
    return (result.first['count'] as num).toInt();
  }

  Future<double> getTodayAvgTransaction() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT COALESCE(AVG(total_harga), 0) AS avg FROM transactions WHERE status IN ('active', 'completed') AND tanggal_waktu LIKE ?",
      ['$today%'],
    );
    return (result.first['avg'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getWeeklyRevenue() async {
    final db = await database;
    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final rows = await db.rawQuery(
        "SELECT COALESCE(SUM(total_harga), 0) AS total FROM transactions WHERE status IN ('active', 'completed') AND tanggal_waktu LIKE ?",
        ['$dateStr%'],
      );
      result.add({
        'date': dateStr,
        'day': _dayName(date.weekday),
        'total': (rows.first['total'] as num).toDouble(),
      });
    }
    return result;
  }

  String _dayName(int wd) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[wd - 1];
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 5,
  }) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT p.nama_menu, SUM(td.qty) AS total_qty, SUM(td.subtotal) AS total_revenue
      FROM transaction_details td
      JOIN products p ON td.id_produk = p.id
      JOIN transactions t ON td.id_transaksi = t.id
      WHERE t.status IN ('active', 'completed')
      GROUP BY td.id_produk
      ORDER BY total_qty DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentMethodStats() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT metode_pembayaran,
             COUNT(*)          AS jumlah,
             SUM(total_harga)  AS total
      FROM transactions
      WHERE status IN ('active', 'completed')
      GROUP BY metode_pembayaran
      ORDER BY jumlah DESC
    ''');
  }

  /// Jam tersibuk — jumlah transaksi per jam (format 'HH' string)
  /// Returns list sorted by hour ascending
  Future<List<Map<String, dynamic>>> getPeakHours() async {
    final db = await database;
    // SQLite: strftime('%H', datetime_string) → '07', '08', ...
    return await db.rawQuery('''
      SELECT
        CAST(strftime('%H', tanggal_waktu) AS INTEGER) AS hour,
        COUNT(*) AS jumlah,
        SUM(total_harga) AS total
      FROM transactions
      WHERE status IN ('active', 'completed')
      GROUP BY hour
      ORDER BY hour ASC
    ''');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final maps = await db.query('settings');
    return {for (final m in maps) m['key'] as String: m['value'] as String};
  }

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return defaultValue;
    return maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveAllSettings(Map<String, String> settings) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in settings.entries) {
      batch.insert('settings', {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Target pendapatan harian (dalam Rupiah)
  Future<double> getTargetHarian() async {
    final val = await getSetting('target_harian', defaultValue: '500000');
    return double.tryParse(val) ?? 500000;
  }

  Future<void> setTargetHarian(double target) async {
    await setSetting('target_harian', target.toStringAsFixed(0));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXPENSES (Pengeluaran)
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await database;
    int id = await db.insert('expenses', expense.toMap());
    SupabaseService().syncData();
    return id;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await database;
    final map = expense.toMap();
    map['is_synced'] = 0;
    await db.update('expenses', map, where: 'id = ?', whereArgs: [expense.id]);
    SupabaseService().syncData();
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    try {
      await SupabaseService().supabase.from('expenses').delete().eq('id', id);
    } catch (_) {}
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExpenseModel>> getExpensesByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: "tanggal LIKE ?",
      whereArgs: ['$date%'],
      orderBy: 'id DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<List<ExpenseModel>> getExpensesByPeriod(String period) async {
    final db = await database;
    String? whereClause;
    final now = DateTime.now();
    switch (period) {
      case 'today':
        final today = now.toIso8601String().substring(0, 10);
        whereClause = "tanggal LIKE '$today%'";
        break;
      case 'week':
        final weekAgo = now
            .subtract(const Duration(days: 7))
            .toIso8601String()
            .substring(0, 10);
        whereClause = "tanggal >= '$weekAgo'";
        break;
      case 'month':
        final monthStart =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        whereClause = "tanggal >= '$monthStart'";
        break;
      default:
        whereClause = '1=1';
    }
    final maps = await db.query(
      'expenses',
      where: whereClause,
      orderBy: 'tanggal DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<double> getTodayExpenses() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(jumlah), 0) AS total FROM expenses WHERE tanggal LIKE ?",
      ['$today%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MONTHLY ANALYTICS (Ringkasan Bulanan)
  // ═══════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getMonthlyComparison() async {
    final db = await database;
    final now = DateTime.now();

    // Bulan ini
    final thisMonthStart =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final thisMonthRevResult = await db.rawQuery(
      "SELECT COALESCE(SUM(total_harga), 0) AS total, COUNT(*) AS count FROM transactions WHERE status IN ('active', 'completed') AND tanggal_waktu >= ?",
      [thisMonthStart],
    );
    final thisMonthExpResult = await db.rawQuery(
      "SELECT COALESCE(SUM(jumlah), 0) AS total FROM expenses WHERE tanggal >= ?",
      [thisMonthStart],
    );

    // Bulan lalu
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthStart =
        '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}-01';
    final lastMonthEnd =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final lastMonthRevResult = await db.rawQuery(
      "SELECT COALESCE(SUM(total_harga), 0) AS total, COUNT(*) AS count FROM transactions WHERE status IN ('active', 'completed') AND tanggal_waktu >= ? AND tanggal_waktu < ?",
      [lastMonthStart, lastMonthEnd],
    );
    final lastMonthExpResult = await db.rawQuery(
      "SELECT COALESCE(SUM(jumlah), 0) AS total FROM expenses WHERE tanggal >= ? AND tanggal < ?",
      [lastMonthStart, lastMonthEnd],
    );

    final thisRevenue = (thisMonthRevResult.first['total'] as num).toDouble();
    final thisOrders = (thisMonthRevResult.first['count'] as num).toInt();
    final thisExpenses = (thisMonthExpResult.first['total'] as num).toDouble();
    final lastRevenue = (lastMonthRevResult.first['total'] as num).toDouble();
    final lastOrders = (lastMonthRevResult.first['count'] as num).toInt();
    final lastExpenses = (lastMonthExpResult.first['total'] as num).toDouble();

    return {
      'thisRevenue': thisRevenue,
      'thisOrders': thisOrders,
      'thisExpenses': thisExpenses,
      'thisProfit': thisRevenue - thisExpenses,
      'lastRevenue': lastRevenue,
      'lastOrders': lastOrders,
      'lastExpenses': lastExpenses,
      'lastProfit': lastRevenue - lastExpenses,
      'revenueChange': lastRevenue > 0
          ? ((thisRevenue - lastRevenue) / lastRevenue * 100)
          : 0.0,
      'ordersChange': lastOrders > 0
          ? ((thisOrders - lastOrders) / lastOrders * 100)
          : 0.0,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LEAST SELLING PRODUCTS (Menu Tidak Laku)
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getLeastSellingProducts({
    int limit = 5,
  }) async {
    final db = await database;
    // Produk aktif yang paling sedikit terjual (termasuk 0)
    return await db.rawQuery(
      '''
      SELECT p.id, p.nama_menu, p.kategori, COALESCE(SUM(td.qty), 0) AS total_qty
      FROM products p
      LEFT JOIN transaction_details td ON p.id = td.id_produk
      LEFT JOIN transactions t ON td.id_transaksi = t.id AND t.status IN ('active', 'completed')
      WHERE p.is_active = 1
      GROUP BY p.id
      ORDER BY total_qty ASC
      LIMIT ?
    ''',
      [limit],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIVE ORDER COUNT
  // ═══════════════════════════════════════════════════════════════════════

  Future<int> getActiveOrderCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM transactions WHERE status IN ('pending', 'active')",
    );
    return (result.first['count'] as num).toInt();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIFTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<ShiftModel?> getActiveShift(int userId) async {
    final db = await database;
    final maps = await db.query(
      'shifts',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'open'],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ShiftModel.fromMap(maps.first);
  }

  Future<int> openShift(ShiftModel shift) async {
    final db = await database;
    final map = shift.toMap();
    map['is_synced'] = 0;
    int id = await db.insert('shifts', map);
    SupabaseService().syncData();
    return id;
  }

  Future<int> closeShift(ShiftModel shift) async {
    final db = await database;
    final map = shift.toMap();
    map['is_synced'] = 0;
    int id = await db.update(
      'shifts',
      map,
      where: 'id = ?',
      whereArgs: [shift.id],
    );
    SupabaseService().syncData();
    return id;
  }

  Future<void> updateShiftExpectedCash(int shiftId, double amountToAdd) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE shifts SET expected_cash = expected_cash + ?, is_synced = 0 WHERE id = ?',
      [amountToAdd, shiftId],
    );
    SupabaseService().syncData();
  }

  Future<void> addKasirExpense(
    double amount,
    String description,
    int shiftId,
  ) async {
    final db = await database;

    // 1. Tambah pengeluaran ke tabel expenses
    await db.insert('expenses', {
      'tanggal': DateTime.now().toIso8601String(),
      'kategori': 'Operasional Kasir',
      'keterangan': description,
      'jumlah': amount,
      'is_synced': 0,
    });

    // 2. Kurangi estimasi kas di tabel shifts
    // Karena mengurangi, amountToAdd bernilai negatif
    await db.rawUpdate(
      'UPDATE shifts SET expected_cash = expected_cash - ?, is_synced = 0 WHERE id = ?',
      [amount, shiftId],
    );

    SupabaseService().syncData();
  }
}
