import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import 'database_helper.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  /// Check if platform supports bluetooth printing
  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get paired bluetooth devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    if (!isSupported) return [];
    
    final bool result = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!result) {
      // Trying to request permissions implicitly or explicitly depends on Android version
      // PrintBluetoothThermal might request it natively on scan
    }
    
    try {
      final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;
      return listResult;
    } catch (e) {
      debugPrint("Error getting paired devices: $e");
      return [];
    }
  }

  /// Connect to a device by mac address
  Future<bool> connect(String macAddress) async {
    if (!isSupported) return false;
    
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      return result;
    } catch (e) {
      debugPrint("Error connecting to printer: $e");
      return false;
    }
  }

  /// Check connection status
  Future<bool> get isConnected async {
    if (!isSupported) return false;
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Disconnect printer
  Future<bool> disconnect() async {
    if (!isSupported) return true;
    return await PrintBluetoothThermal.disconnect;
  }

  /// Print receipt for a specific transaction
  Future<bool> printReceipt(TransactionModel transaction, List<Map<String, dynamic>> items, {bool isReprint = false, double dibayar = 0, double kembalian = 0}) async {
    if (!isSupported) {
      debugPrint("Printing not supported on this platform.");
      return false;
    }

    final connected = await isConnected;
    if (!connected) {
      // Coba konek ke printer yang disimpan di settings
      final dbHelper = DatabaseHelper();
      final mac = await dbHelper.getSetting('printer_mac');
      if (mac.isEmpty) return false;
      
      final connectSuccess = await connect(mac);
      if (!connectSuccess) return false;
    }

    // Generate ESC/POS bytes
    List<int> bytes = await _generateReceiptBytes(transaction, items, isReprint: isReprint, dibayar: dibayar, kembalian: kembalian);
    
    try {
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      debugPrint("Failed to print: $e");
      return false;
    }
  }

  /// Generate receipt layout using esc_pos_utils_plus
  Future<List<int>> _generateReceiptBytes(TransactionModel transaction, List<Map<String, dynamic>> items, {bool isReprint = false, double dibayar = 0, double kembalian = 0}) async {
    final profile = await CapabilityProfile.load();
    // Gunakan 58mm
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header: Cetak Logo jika ada
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      final Uint8List bytesImg = data.buffer.asUint8List();
      final img.Image? logo = img.decodeImage(bytesImg);
      if (logo != null) {
        final resizedLogo = img.copyResize(logo, width: 150); 
        bytes += generator.image(resizedLogo, align: PosAlign.center);
      } else {
        bytes += generator.text('NASI GORENG REMPAH', styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      }
    } catch (e) {
      // Jika logo gagal diload, fallback ke teks
      bytes += generator.text('NASI GORENG REMPAH', styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    }
    
    // Tambahkan Judul Toko di bawah logo
    bytes += generator.text('NASI GORENG REMPAH', styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Jl. Printis kemerdekaan 3', styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Telp: 082193739177', styles: PosStyles(align: PosAlign.center));
    bytes += generator.emptyLines(1);
    
    if (isReprint) {
      bytes += generator.text('*** COPY ***', styles: PosStyles(align: PosAlign.center, bold: true));
    }

    // Info Transaksi
    bytes += generator.text('Tgl: ${transaction.tanggalWaktu.substring(0, 16).replaceAll('T', ' ')}');
    bytes += generator.hr();

    // Item List
    for (var item in items) {
      final String name = item['nama_menu'] ?? 'Item';
      final int qty = (item['qty'] as num).toInt();
      final double price = (item['harga_satuan'] as num).toDouble();
      final double subtotal = (item['subtotal'] as num).toDouble();

      // Baris 1: Nama Item
      bytes += generator.text(name, styles: PosStyles(bold: true));
      
      // Baris Catatan (opsional)
      final String? catatan = item['catatan'] as String?;
      if (catatan != null && catatan.isNotEmpty) {
        bytes += generator.text('  Catatan: $catatan');
      }

      // Baris 2: Qty x Harga     Subtotal
      // Alignment dengan string padding: max 32 character untuk 58mm
      final qtyPrice = '$qty x ${_fc(price)}';
      final subtotalStr = _fc(subtotal);
      
      int spaceLength = 32 - qtyPrice.length - subtotalStr.length;
      if (spaceLength < 1) spaceLength = 1;
      
      bytes += generator.text(qtyPrice + (' ' * spaceLength) + subtotalStr);
    }
    bytes += generator.hr();

    // Total
    final totalStr = _fc(transaction.totalHarga);
    final totalSpace = 32 - 'Total:'.length - totalStr.length;
    bytes += generator.text('Total:' + (' ' * totalSpace) + totalStr, styles: PosStyles(bold: true));

    final dibayarStr = _fc(dibayar);
    final bayarSpace = 32 - 'Dibayar:'.length - dibayarStr.length;
    bytes += generator.text('Dibayar:' + (' ' * bayarSpace) + dibayarStr);

    final kembaliStr = _fc(kembalian);
    final kembaliSpace = 32 - 'Kembali:'.length - kembaliStr.length;
    bytes += generator.text('Kembali:' + (' ' * kembaliSpace) + kembaliStr);

    bytes += generator.emptyLines(1);
    bytes += generator.text('Terima Kasih', styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Silakan Datang Kembali', styles: PosStyles(align: PosAlign.center));
    
    // Feed and cut
    bytes += generator.feed(2);
    // bytes += generator.cut(); // 58mm mini printers usually don't have auto cutter, but you can send the command

    return bytes;
  }

  String _fc(double v) {
    return 'Rp${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
