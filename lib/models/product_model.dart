/// Model untuk tabel `products`
class ProductModel {
  final int? id;
  final String namaMenu;
  final double harga;
  final String kategori;
  final bool isActive;
  final String? imagePath;
  final String? imageCloudUrl;

  ProductModel({
    this.id,
    required this.namaMenu,
    required this.harga,
    required this.kategori,
    this.isActive = true,
    this.imagePath,
    this.imageCloudUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      namaMenu: map['nama_menu'] as String,
      harga: (map['harga'] as num).toDouble(),
      kategori: map['kategori'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      imagePath: map['image_path'] as String?,
      imageCloudUrl: map['image_cloud_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_menu': namaMenu,
      'harga': harga,
      'kategori': kategori,
      'is_active': isActive ? 1 : 0,
      if (imagePath != null) 'image_path': imagePath,
      if (imageCloudUrl != null) 'image_cloud_url': imageCloudUrl,
    };
  }

  ProductModel copyWith({
    int? id,
    String? namaMenu,
    double? harga,
    String? kategori,
    bool? isActive,
    String? imagePath,
    String? imageCloudUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      namaMenu: namaMenu ?? this.namaMenu,
      harga: harga ?? this.harga,
      kategori: kategori ?? this.kategori,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
      imageCloudUrl: imageCloudUrl ?? this.imageCloudUrl,
    );
  }

  @override
  String toString() =>
      'ProductModel(id: $id, namaMenu: $namaMenu, harga: $harga, isActive: $isActive)';
}
