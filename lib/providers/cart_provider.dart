import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';

/// Item yang ada di keranjang belanja kasir
class CartItem {
  final ProductModel product;
  int qty;
  String? catatan;

  CartItem({required this.product, this.qty = 1, this.catatan});

  double get subtotal => product.harga * qty;
}

/// CartProvider — mengelola keranjang belanja & proses transaksi.
class CartProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  final List<CartItem> _items = [];
  int? activeTransactionId;
  String? activeCustomerName;

  List<CartItem> get items => _items;

  double get totalHarga => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.qty);

  // ─── Tambah produk ke keranjang ─────────────────────────────────────────
  void addItem(ProductModel product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].qty++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // ─── Kurangi qty produk di keranjang ───────────────────────────────────
  void removeItem(ProductModel product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      if (_items[index].qty > 1) {
        _items[index].qty--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // ─── Hapus item dari keranjang ──────────────────────────────────────────
  void deleteItem(int productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  // ─── Update Catatan per Item ───────────────────────────────────────────
  void updateNote(ProductModel product, String note) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].catatan = note.trim().isEmpty ? null : note.trim();
      notifyListeners();
    }
  }

  // ─── Setter Nama Pelanggan ──────────────────────────────────────────────
  void setCustomerName(String name) {
    activeCustomerName = name;
    notifyListeners();
  }

  // ─── Load dari pending transaction (Edit) ───────────────────────────────
  void loadTransaction(
    TransactionModel trx,
    List<TransactionDetailModel> details,
    List<ProductModel> products,
  ) {
    _items.clear();
    activeTransactionId = trx.id;
    activeCustomerName = trx.namaPelanggan;
    for (final detail in details) {
      try {
        final p = products.firstWhere((prod) => prod.id == detail.idProduk);
        _items.add(
          CartItem(product: p, qty: detail.qty, catatan: detail.catatan),
        );
      } catch (e) {
        // Produk mungkin sudah terhapus, lewati atau tangani
      }
    }
    notifyListeners();
  }

  // ─── Kosongkan keranjang ────────────────────────────────────────────────
  void clearCart() {
    _items.clear();
    activeTransactionId = null;
    activeCustomerName = null;
    notifyListeners();
  }

  // ─── Proses checkout & simpan ke database ──────────────────────────────
  Future<int> checkout(String metodePembayaran) async {
    if (_items.isEmpty) return -1;

    final transaction = TransactionModel(
      tanggalWaktu: DateTime.now().toIso8601String(),
      totalHarga: totalHarga,
      metodePembayaran: metodePembayaran,
    );

    final details = _items
        .map(
          (item) => TransactionDetailModel(
            idTransaksi: 0, // akan di-set di DatabaseHelper
            idProduk: item.product.id!,
            qty: item.qty,
            subtotal: item.subtotal,
          ),
        )
        .toList();

    final transactionId = await _db.saveTransaction(transaction, details);
    clearCart();
    return transactionId;
  }
}
