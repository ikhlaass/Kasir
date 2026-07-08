/// Model untuk tabel `settings` (key-value store)
class SettingModel {
  final String key;
  final String value;

  const SettingModel({required this.key, required this.value});

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'key': key, 'value': value};
}

/// Kunci-kunci yang digunakan di tabel settings
class SettingKeys {
  static const String namaToko = 'nama_toko';
  static const String alamatToko = 'alamat_toko';
  static const String teleponToko = 'telepon_toko';
  static const String deskripsiToko = 'deskripsi_toko';
  static const String qrisPath = 'qris_path';
  static const String qrisCloudUrl = 'qris_cloud_url';
}
