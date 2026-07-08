import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/database_helper.dart';
import '../../../services/printer_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_fonts.dart';

Future<void> showCheckoutDialog(BuildContext context, CartProvider cart, UserModel user) async {
  final settings = await DatabaseHelper().getAllSettings();
  final String? qrisPath = settings['qris_path'];

  String selectedMethod = 'Tunai';
  final uangCtrl = TextEditingController();

  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateSB) {
        final isTunai = selectedMethod == 'Tunai';
        final uang = double.tryParse(uangCtrl.text) ?? 0;
        final kembalian = uang - cart.totalHarga;
        final valid = !isTunai || kembalian >= 0;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Total Tagihan',
                        style: AppFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${cart.totalHarga.toInt()}',
                        style: AppFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Metode Pembayaran',
                            style: AppFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: ['Tunai', 'QRIS', 'Transfer'].map((m) {
                              final isSel = selectedMethod == m;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setStateSB(() => selectedMethod = m),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppColors.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: isSel ? 1.5 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      m,
                                      style: AppFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSel
                                            ? AppColors.primary
                                            : AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          if (isTunai) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Uang Diterima (Rp)',
                              style: AppFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: uangCtrl,
                              keyboardType: TextInputType.number,
                              style: AppFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'Rp ',
                                prefixStyle: AppFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMedium,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (v) => setStateSB(() {}),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: valid
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kembalian',
                                    style: AppFonts.poppins(
                                      fontSize: 14,
                                      color: valid
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${kembalian > 0 ? kembalian.toInt() : 0}',
                                    style: AppFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: valid
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (selectedMethod == 'QRIS') ...[
                            const SizedBox(height: 24),
                            Text(
                              'Scan QRIS',
                              style: AppFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: qrisPath != null &&
                                      qrisPath.isNotEmpty &&
                                      File(qrisPath).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(qrisPath),
                                        width: 250,
                                        height: 250,
                                        fit: BoxFit.cover,
                                        cacheWidth: 500,
                                      ),
                                    )
                                  : Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2,
                                            size: 64,
                                            color: AppColors.textLight,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'QRIS belum disetting Admin',
                                            style: AppFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],

                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: AppColors.border),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: AppFonts.poppins(
                                      color: AppColors.textMedium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: valid
                                      ? () async {
                                          final nav = Navigator.of(ctx);
                                          final db = DatabaseHelper();
                                          final trx = TransactionModel(
                                            id: cart.activeTransactionId,
                                            totalHarga: cart.totalHarga,
                                            metodePembayaran: selectedMethod,
                                            status: 'active',
                                            namaPelanggan: 'Pelanggan Umum',
                                            tanggalWaktu: DateTime.now()
                                                .toIso8601String(),
                                          );
                                          final details = cart.items
                                              .map(
                                                (item) =>
                                                    TransactionDetailModel(
                                                  idTransaksi:
                                                      cart.activeTransactionId ?? 0,
                                                  idProduk: item.product.id!,
                                                  qty: item.qty,
                                                  subtotal: item.subtotal,
                                                  catatan: item.catatan,
                                                ),
                                              )
                                              .toList();

                                          final receiptItems = cart.items
                                              .map(
                                                (item) => {
                                                  'nama_menu': item.product.namaMenu,
                                                  'qty': item.qty,
                                                  'harga_satuan': item.product.harga,
                                                  'subtotal': item.subtotal,
                                                  'catatan': item.catatan,
                                                },
                                              )
                                              .toList();

                                          await db.saveTransaction(trx, details);

                                          if (selectedMethod == 'Tunai') {
                                            final shift = await db.getActiveShift(user.id!);
                                            if (shift != null && shift.id != null) {
                                              await db.updateShiftExpectedCash(
                                                shift.id!,
                                                cart.totalHarga,
                                              );
                                            }
                                          }
                                          
                                          // Auto-sync in background so admin sees it instantly
                                          SupabaseService().syncData().catchError((_) {});

                                          cart.clearCart();

                                          nav.pop(); // close payment dialog

                                          // Show Success Dialog
                                          if (context.mounted) {
                                            _showSuccessDialog(
                                                context, kembalian, trx, receiptItems, uang);
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: valid
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                  child: Text(
                                    'Bayar & Proses',
                                    style: AppFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: valid
                                          ? Colors.white
                                          : AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _showSuccessDialog(
  BuildContext context,
  double kembalian,
  TransactionModel trx,
  List<Map<String, dynamic>> receiptItems,
  double uang,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (sCtx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Transaksi Berhasil!',
              style: AppFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kembalian: Rp ${kembalian > 0 ? kembalian.toInt() : 0}',
              style: AppFonts.poppins(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final ps = PrinterService();
                  final printed = await ps.printReceipt(
                    trx,
                    receiptItems,
                    dibayar: uang,
                    kembalian: kembalian,
                  );
                  if (!printed) {
                    if (!sCtx.mounted) return;
                    ScaffoldMessenger.of(sCtx).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal mencetak. Cek koneksi printer.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print_outlined, size: 18),
                label: Text(
                  'Cetak Struk',
                  style: AppFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sCtx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Tutup',
                  style: AppFonts.poppins(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
