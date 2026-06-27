import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/database_helper.dart';

/// ProductProvider — mengelola state daftar produk menggunakan Provider.
class ProductProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<ProductModel> _products = [];
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  /// Daftar produk Extra / Topping untuk pop-up modifier
  List<ProductModel> get extraProducts => 
      _products.where((p) => p.kategori.trim().toLowerCase() == 'extra topping').toList();

  /// Semua produk (untuk admin - kelola menu)
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _db.getAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  /// Hanya produk aktif (untuk kasir)
  Future<void> loadActiveProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _db.getActiveProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    final id = await _db.insertProduct(product);
    _products.add(product.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.updateProduct(product);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  /// Toggle status aktif/nonaktif produk
  Future<void> toggleActive(ProductModel product) async {
    final newState = !product.isActive;
    await _db.toggleProductActive(product.id!, newState);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product.copyWith(isActive: newState);
      notifyListeners();
    }
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
