import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';

class ReportExportService {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final dateFormatter = DateFormat('dd MMM yyyy HH:mm');

  /// Export data transaksi ke PDF dan trigger preview/share
  Future<void> exportPdf(
      BuildContext context, String period, List<TransactionModel> trxs) async {
    final pdf = pw.Document();

    double totalRevenue = 0;
    for (var t in trxs) {
      totalRevenue += t.totalHarga;
    }

    final tableHeaders = [
      'ID',
      'Tanggal',
      'Pelanggan',
      'Metode',
      'Status',
      'Total (Rp)'
    ];
    final tableData = trxs.map((t) {
      return [
        t.id.toString(),
        dateFormatter.format(DateTime.parse(t.tanggalWaktu)),
        t.namaPelanggan ?? '-',
        t.metodePembayaran,
        t.status,
        currencyFormatter.format(t.totalHarga),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Laporan Transaksi Kasir',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'Periode: ${period.toUpperCase()}\nDicetak: ${dateFormatter.format(DateTime.now())}',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Transaksi: ${trxs.length}'),
                pw.Text('Total Pendapatan: ${currencyFormatter.format(totalRevenue)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Transaksi_$period.pdf',
    );
  }

  /// Export data transaksi ke CSV (Excel) dan bagikan (Share)
  Future<void> exportCsv(
      BuildContext context, String period, List<TransactionModel> trxs) async {
    try {
      final List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        'ID Transaksi',
        'Tanggal Waktu',
        'Nama Pelanggan',
        'Metode Pembayaran',
        'Status',
        'Total Harga'
      ]);

      // Data
      for (var t in trxs) {
        rows.add([
          t.id ?? '',
          dateFormatter.format(DateTime.parse(t.tanggalWaktu)),
          t.namaPelanggan ?? '-',
          t.metodePembayaran,
          t.status,
          t.totalHarga
        ]);
      }

      final String csvString = rows.map((row) {
        return row.map((field) {
          String f = field.toString();
          if (f.contains(',') || f.contains('"') || f.contains('\n')) {
            f = '"${f.replaceAll('"', '""')}"';
          }
          return f;
        }).join(',');
      }).join('\n');
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/Laporan_Transaksi_$period.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Laporan Transaksi Kasir ($period)',
        ),
      );
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor laporan: $e')),
        );
      }
    }
  }
}
