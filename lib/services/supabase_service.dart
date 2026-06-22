import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final supabase = Supabase.instance.client;
  final DatabaseHelper _db = DatabaseHelper();

  // Memanggil fungsi sync ketika ada koneksi
  Future<void> syncData() async {
    try {
      // Cek koneksi sederhana ke Supabase (misal get 1 baris)
      await supabase.from('users').select().limit(1);
      
      // Jika berhasil, mulai proses Push (Upload data lokal ke Cloud)
      await _pushUnsyncedData();
      
      // Kemudian Pull (Download data baru dari Cloud ke lokal)
      await _pullData();
    } catch (e) {
      // Jika gagal (offline), diamkan saja. Data aman di SQLite.
      print("Offline / Sync Failed: $e");
    }
  }

  Future<void> _pushUnsyncedData() async {
    final db = await _db.database;
    final tables = ['users', 'products', 'transactions', 'transaction_details', 'expenses', 'shifts'];

    for (String table in tables) {
      final unsynced = await db.query(table, where: 'is_synced = ?', whereArgs: [0]);
      if (unsynced.isEmpty) continue;

      try {
        // Hapus kunci is_synced sebelum dikirim ke Supabase karena di Supabase tidak ada kolom is_synced
        List<Map<String, dynamic>> recordsToPush = [];
        for (var record in unsynced) {
          final map = Map<String, dynamic>.from(record);
          map.remove('is_synced');
          recordsToPush.add(map);
        }

        // Upsert ke Supabase
        await supabase.from(table).upsert(recordsToPush);

        // Jika sukses, update SQLite is_synced = 1
        for (var record in unsynced) {
          await db.update(
            table,
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        }
      } catch (e) {
        print("Gagal push tabel $table: $e");
      }
    }
  }

  Future<void> _pullData() async {
    // Sebagai MVP: kita mendownload tabel Products dan Users dari Cloud ke lokal
    // (karena admin bisa tambah menu/user dari perangkat lain)
    final db = await _db.database;

    try {
      final products = await supabase.from('products').select();
      for (var p in products) {
        p['is_synced'] = 1; // Tandai sudah tersinkronisasi
        await db.insert('products', p, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final users = await supabase.from('users').select();
      for (var u in users) {
        u['is_synced'] = 1;
        await db.insert('users', u, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      // Opsional: Pull Settings, Expenses, dll.
    } catch (e) {
      print("Gagal pull data: $e");
    }
  }
}
