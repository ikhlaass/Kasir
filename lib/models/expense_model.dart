/// Model untuk tabel `expenses`
class ExpenseModel {
  final int? id;
  final String tanggal;
  final String kategori;
  final String keterangan;
  final double jumlah;

  ExpenseModel({
    this.id,
    required this.tanggal,
    required this.kategori,
    required this.keterangan,
    required this.jumlah,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      tanggal: map['tanggal'] as String,
      kategori: map['kategori'] as String,
      keterangan: map['keterangan'] as String,
      jumlah: (map['jumlah'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': tanggal,
      'kategori': kategori,
      'keterangan': keterangan,
      'jumlah': jumlah,
    };
  }
}
