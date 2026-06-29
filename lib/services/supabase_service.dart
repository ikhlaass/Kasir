import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final supabase = Supabase.instance.client;
  final DatabaseHelper _db = DatabaseHelper();

  // Sync data: push unsynced local data then pull all from Cloud (incl. settings)
  Future<void> syncData() async {
    try {
      await supabase.from('users').select().limit(1);
      await _pushUnsyncedData();
      await _pullData(pullSettings: true);
    } catch (e) {
      debugPrint('Offline / Sync Failed: $e');
    }
  }

  // Alias — sama dengan syncData
  Future<void> syncDataFull() async => syncData();

  // Khusus dipanggil saat Admin klik "Simpan Perubahan" di halaman Pengaturan.
  // Hanya push settings, tidak menarik data lain.
  Future<void> pushSettings() async {
    try {
      await supabase.from('users').select().limit(1);
      final db = await _db.database;
      final allSettings = await db.query('settings');
      if (allSettings.isNotEmpty) {
        await supabase.from('settings').upsert(allSettings);
      }
    } catch (e) {
      debugPrint('Gagal push settings: $e');
    }
  }

  Future<void> _pushUnsyncedData() async {
    final db = await _db.database;
    const tables = [
      'users',
      'products',
      'transactions',
      'transaction_details',
      'expenses',
      'shifts',
    ];

    for (final table in tables) {
      final unsynced = await db.query(
        table,
        where: 'is_synced = ?',
        whereArgs: [0],
      );
      if (unsynced.isEmpty) continue;

      try {
        final recordsToPush = unsynced.map((record) {
          final map = Map<String, dynamic>.from(record);
          map.remove('is_synced');
          return map;
        }).toList();

        await supabase.from(table).upsert(recordsToPush);

        for (final record in unsynced) {
          await db.update(
            table,
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        }
      } catch (e) {
        debugPrint('Gagal push tabel $table: $e');
      }
    }
    // Settings TIDAK di-push di sini.
    // Settings hanya di-push saat user klik "Simpan Perubahan" via pushSettings().
  }

  Future<void> _pullData({bool pullSettings = false}) async {
    final db = await _db.database;

    try {
      const tables = [
        'products',
        'users',
        'transactions',
        'transaction_details',
        'shifts',
        'expenses',
      ];
      for (final table in tables) {
        final records = await supabase.from(table).select();
        for (final record in records) {
          record['is_synced'] = 1;
          await db.insert(
            table,
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      if (pullSettings) {
        final settingsRecords = await supabase.from('settings').select();
        for (final record in settingsRecords) {
          await db.insert(
            'settings',
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } catch (e) {
      debugPrint('Gagal pull data: $e');
    }
  }
}
