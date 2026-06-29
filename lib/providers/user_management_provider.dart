import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';
import '../services/supabase_service.dart';

/// UserManagementProvider — state management untuk kelola akun kasir.
class UserManagementProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<UserModel> _kasirList = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get kasirList => _kasirList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadKasir() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _kasirList = await _db.getAllKasir();
    _isLoading = false;
    notifyListeners();
  }

  /// Tambah kasir baru. Returns null jika sukses, atau pesan error.
  Future<String?> addKasir({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty) return 'Username tidak boleh kosong';
    if (password.length < 6) return 'Password minimal 6 karakter';

    final exists = await _db.isUsernameExists(username.trim());
    if (exists) return 'Username "$username" sudah digunakan';

    try {
      final id = await _db.insertUser(
        UserModel(username: username.trim(), password: password, role: 'kasir'),
      );
      _kasirList.add(
        UserModel(
          id: id,
          username: username.trim(),
          password: password,
          role: 'kasir',
        ),
      );
      notifyListeners();
      SupabaseService().syncData();
      return null;
    } catch (e) {
      return 'Gagal menambah kasir: $e';
    }
  }

  /// Ganti password kasir. Returns null jika sukses, atau pesan error.
  Future<String?> changePassword(int userId, String newPassword) async {
    if (newPassword.length < 6) return 'Password minimal 6 karakter';

    await _db.updateUserPassword(userId, newPassword);
    final index = _kasirList.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _kasirList[index] = UserModel(
        id: userId,
        username: _kasirList[index].username,
        password: newPassword,
        role: 'kasir',
      );
      notifyListeners();
      SupabaseService().syncData();
    }
    return null;
  }

  /// Hapus kasir. Returns null jika sukses, atau pesan error.
  Future<String?> deleteKasir(int id) async {
    try {
      await _db.deleteUser(id);
      _kasirList.removeWhere((u) => u.id == id);
      notifyListeners();
      SupabaseService().syncData();
      return null;
    } catch (e) {
      return 'Gagal menghapus kasir: $e';
    }
  }
}
