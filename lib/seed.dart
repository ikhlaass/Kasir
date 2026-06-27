import 'package:flutter/material.dart';
import 'models/expense_model.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1, 15);

  // 1. Get Available Products
  final products = await dbHelper.getActiveProducts();
  if (products.isEmpty) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Gagal: Tidak ada produk aktif di database. Tambahkan menu dulu dari kasir.", style: TextStyle(fontSize: 20))))));
    return;
  }
  
  final p1 = products[0].id!;
  final p2 = products.length > 1 ? products[1].id! : products[0].id!;
  final p3 = products.length > 2 ? products[2].id! : products[0].id!;

  // 2. Seed Expenses (This Month)
  await dbHelper.insertExpense(ExpenseModel(
    tanggal: now.toIso8601String(), 
    kategori: 'Bahan Baku', 
    keterangan: 'Belanja Ayam & Telur', 
    jumlah: 150000
  ));
  await dbHelper.insertExpense(ExpenseModel(
    tanggal: now.toIso8601String(), 
    kategori: 'Gas & BBM', 
    keterangan: 'Gas 3kg', 
    jumlah: 20000
  ));
  
  // 3. Seed Expenses (Last Month)
  await dbHelper.insertExpense(ExpenseModel(
    tanggal: lastMonth.toIso8601String(), 
    kategori: 'Listrik & Air', 
    keterangan: 'Token Listrik', 
    jumlah: 100000
  ));
  await dbHelper.insertExpense(ExpenseModel(
    tanggal: lastMonth.toIso8601String(), 
    kategori: 'Bahan Baku', 
    keterangan: 'Belanja Beras', 
    jumlah: 300000
  ));

  // 4. Seed Transactions (Last Month)
  int trxLastId = await db.insert('transactions', {
    'tanggal_waktu': lastMonth.toIso8601String(),
    'metode_pembayaran': 'Tunai',
    'total_harga': 45000,
    'status': 'completed',
    'nama_pelanggan': 'Pak Budi'
  });
  
  await db.insert('transaction_details', {
    'id_transaksi': trxLastId,
    'id_produk': p1,
    'qty': 3,
    'subtotal': 45000,
  });

  // 5. Seed Transactions (This Month) - Completed
  int trxThisId = await db.insert('transactions', {
    'tanggal_waktu': now.toIso8601String(),
    'metode_pembayaran': 'QRIS',
    'total_harga': 100000,
    'status': 'completed',
    'nama_pelanggan': 'Bu Siti'
  });
  
  await db.insert('transaction_details', {
    'id_transaksi': trxThisId,
    'id_produk': p2,
    'qty': 5,
    'subtotal': 100000,
  });

  int trxThisId2 = await db.insert('transactions', {
    'tanggal_waktu': now.toIso8601String(),
    'metode_pembayaran': 'Tunai',
    'total_harga': 125000,
    'status': 'completed',
    'nama_pelanggan': 'Mas Agus'
  });
  
  await db.insert('transaction_details', {
    'id_transaksi': trxThisId2,
    'id_produk': p3,
    'qty': 5,
    'subtotal': 125000,
  });

  // 6. Seed Active Orders (Pesanan belum diambil)
  int trxActiveId = await db.insert('transactions', {
    'tanggal_waktu': now.toIso8601String(),
    'metode_pembayaran': 'Tunai',
    'total_harga': 30000,
    'status': 'active',
    'nama_pelanggan': 'Mbak Sari'
  });
  
  await db.insert('transaction_details', {
    'id_transaksi': trxActiveId,
    'id_produk': p1,
    'qty': 2,
    'subtotal': 30000,
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "Data Dummy Berhasil Ditambahkan!\nSilakan tutup window ini dan jalankan ulang aplikasinya.", 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
          )
        )
      )
    )
  );
}
