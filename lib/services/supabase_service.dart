import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final supabase = Supabase.instance.client;
  final DatabaseHelper _db = DatabaseHelper();

  // ─── FILE UPLOAD / DOWNLOAD ────────────────────────────────────────────

  /// Upload file lokal ke Supabase Storage.
  /// Return public URL jika berhasil, null jika gagal.
  Future<String?> uploadFile(String bucket, String localPath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return null;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last}';

      await supabase.storage.from(bucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage.from(bucket).getPublicUrl(fileName);
      debugPrint('✅ Uploaded to $bucket: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Upload gagal ($bucket): $e');
      return null;
    }
  }

  /// Download file dari URL cloud ke path lokal.
  /// Return path lokal jika berhasil, null jika gagal.
  Future<String?> downloadFile(String cloudUrl, String localFileName) async {
    try {
      if (cloudUrl.isEmpty) return null;

      final docDir = await getApplicationDocumentsDirectory();
      final localPath = '${docDir.path}/$localFileName';
      final localFile = File(localPath);

      // Skip download jika file sudah ada
      if (localFile.existsSync()) {
        // debugPrint('📁 File sudah ada: $localPath');
        return localPath;
      }

      // Download menggunakan HttpClient
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(cloudUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await localFile.writeAsBytes(bytes);
        debugPrint('✅ Downloaded: $localPath');
        httpClient.close();
        return localPath;
      }
      httpClient.close();
      return null;
    } catch (e) {
      debugPrint('❌ Download gagal: $e');
      return null;
    }
  }

  // ─── SYNC DATA ─────────────────────────────────────────────────────────

  /// Sync data: push unsynced local data then pull all from Cloud (incl. settings)
  Future<void> syncData() async {
    try {
      await supabase.from('users').select().limit(1);
      await _pushUnsyncedData();
      await _pullData(pullSettings: true);
    } catch (e) {
      debugPrint('Offline / Sync Failed: $e');
    }
  }

  /// Alias — sama dengan syncData
  Future<void> syncDataFull() async => syncData();

  // ─── PUSH SETTINGS ────────────────────────────────────────────────────

  /// Khusus dipanggil saat Admin klik "Simpan Perubahan" di halaman Pengaturan.
  /// Upload gambar QRIS ke cloud, lalu push settings.
  Future<void> pushSettings() async {
    try {
      await supabase.from('users').select().limit(1);
      final db = await _db.database;
      final allSettings = await db.query('settings');

      // Cari qris_path dan upload ke cloud jika ada
      final settingsMap = <String, String>{};
      for (final s in allSettings) {
        settingsMap[s['key'] as String] = s['value'] as String;
      }

      final qrisPath = settingsMap['qris_path'] ?? '';
      if (qrisPath.isNotEmpty && File(qrisPath).existsSync()) {
        final cloudUrl = await uploadFile('qris', qrisPath);
        if (cloudUrl != null) {
          settingsMap['qris_cloud_url'] = cloudUrl;
          // Simpan juga di lokal
          await db.insert(
            'settings',
            {'key': 'qris_cloud_url', 'value': cloudUrl},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Push semua settings ke cloud
      final settingsList = settingsMap.entries
          .map((e) => {'key': e.key, 'value': e.value})
          .toList();
      if (settingsList.isNotEmpty) {
        await supabase.from('settings').upsert(settingsList);
      }
    } catch (e) {
      debugPrint('Gagal push settings: $e');
    }
  }

  // ─── PUSH UNSYNCED DATA ───────────────────────────────────────────────

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
        final recordsToPush = <Map<String, dynamic>>[];

        for (final record in unsynced) {
          final map = Map<String, dynamic>.from(record);
          map.remove('is_synced');

          if (table == 'products') {
            map.remove('stok');
            map.remove('image_cloud_url');
            
            final imagePath = map['image_path'] as String?;
            if (imagePath != null &&
                imagePath.isNotEmpty &&
                File(imagePath).existsSync() &&
                !imagePath.startsWith('http')) {
              final cloudUrl = await uploadFile('products', imagePath);
              if (cloudUrl != null) {
                map['image_path'] = cloudUrl;
                // Update lokal juga
                await db.update(
                  'products',
                  {'image_cloud_url': cloudUrl},
                  where: 'id = ?',
                  whereArgs: [record['id']],
                );
              }
            } else if (record['image_cloud_url'] != null) {
               map['image_path'] = record['image_cloud_url'];
            }
          }

          recordsToPush.add(map);
        }

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

  // ─── PULL DATA ────────────────────────────────────────────────────────

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

          // Jika tabel products dan ada image_cloud_url, download ke lokal
          if (table == 'products') {
            final cloudUrl = record['image_cloud_url'] as String?;
            if (cloudUrl != null && cloudUrl.isNotEmpty) {
              final fileName =
                  'product_${record['id']}_${cloudUrl.split('/').last}';
              final localPath = await downloadFile(cloudUrl, fileName);
              if (localPath != null) {
                record['image_path'] = localPath;
              }
            }
          }

          await db.insert(
            table,
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      if (pullSettings) {
        final settingsRecords = await supabase.from('settings').select();

        // Pertama simpan semua settings apa adanya
        for (final record in settingsRecords) {
          await db.insert(
            'settings',
            record,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Lalu cek apakah ada qris_cloud_url, jika ada download ke lokal
        final settingsMap = <String, String>{};
        for (final r in settingsRecords) {
          settingsMap[r['key'] as String] = r['value'] as String;
        }

        final qrisCloudUrl = settingsMap['qris_cloud_url'] ?? '';
        if (qrisCloudUrl.isNotEmpty) {
          final fileName = 'qris_${qrisCloudUrl.split('/').last}';
          final localPath = await downloadFile(qrisCloudUrl, fileName);
          if (localPath != null) {
            // Update qris_path lokal agar menunjuk ke file yg baru didownload
            await db.insert(
              'settings',
              {'key': 'qris_path', 'value': localPath},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal pull data: $e');
    }
  }
}
