/// Model untuk tabel `users`
class UserModel {
  final int? id;
  final String username;
  final String password;
  final String role; // 'admin' atau 'kasir'

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  /// Konversi dari Map (hasil query SQLite) ke object UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
    );
  }

  /// Konversi object ke Map untuk disimpan ke SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password': password,
      'role': role,
    };
  }

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, role: $role)';
}
