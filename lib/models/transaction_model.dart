/// Model untuk tabel `transactions`
class TransactionModel {
  final int? id;
  final String tanggalWaktu;
  final double totalHarga;
  final String metodePembayaran;
  final String status; // 'pending' atau 'completed'
  final String? namaPelanggan;

  TransactionModel({
    this.id,
    required this.tanggalWaktu,
    required this.totalHarga,
    required this.metodePembayaran,
    this.status = 'completed',
    this.namaPelanggan,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      tanggalWaktu: map['tanggal_waktu'] as String,
      totalHarga: (map['total_harga'] as num).toDouble(),
      metodePembayaran: map['metode_pembayaran'] as String,
      status: map['status'] as String? ?? 'completed',
      namaPelanggan: map['nama_pelanggan'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal_waktu': tanggalWaktu,
      'total_harga': totalHarga,
      'metode_pembayaran': metodePembayaran,
      'status': status,
      'nama_pelanggan': namaPelanggan,
    };
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, status: $status, namaPelanggan: $namaPelanggan, totalHarga: $totalHarga)';
}

/// Model untuk tabel `transaction_details`
class TransactionDetailModel {
  final int? id;
  final int idTransaksi;
  final int idProduk;
  final int qty;
  final double subtotal;

  final String? catatan;

  // Data join (opsional, tidak disimpan di DB)
  final String? namaMenu;

  TransactionDetailModel({
    this.id,
    required this.idTransaksi,
    required this.idProduk,
    required this.qty,
    required this.subtotal,
    this.catatan,
    this.namaMenu,
  });

  factory TransactionDetailModel.fromMap(Map<String, dynamic> map) {
    return TransactionDetailModel(
      id: map['id'] as int?,
      idTransaksi: map['id_transaksi'] as int,
      idProduk: map['id_produk'] as int,
      qty: map['qty'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
      catatan: map['catatan'] as String?,
      namaMenu: map['nama_menu'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_transaksi': idTransaksi,
      'id_produk': idProduk,
      'qty': qty,
      'subtotal': subtotal,
      if (catatan != null) 'catatan': catatan,
    };
  }
}
