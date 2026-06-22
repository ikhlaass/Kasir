import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../models/user_model.dart';
import '../../services/database_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../auth/login_screen.dart';

class CloseShiftScreen extends StatefulWidget {
  final UserModel user;
  final ShiftModel shift;

  const CloseShiftScreen({super.key, required this.user, required this.shift});

  @override
  State<CloseShiftScreen> createState() => _CloseShiftScreenState();
}

class _CloseShiftScreenState extends State<CloseShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualCashCtrl = TextEditingController();
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = false;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final actualCash = double.parse(_actualCashCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final difference = actualCash - widget.shift.expectedCash;
      final now = DateTime.now().toIso8601String();

      final updatedShift = ShiftModel(
        id: widget.shift.id,
        userId: widget.shift.userId,
        startTime: widget.shift.startTime,
        endTime: now,
        startingCash: widget.shift.startingCash,
        expectedCash: widget.shift.expectedCash,
        actualCash: actualCash,
        difference: difference,
        status: 'closed',
      );

      await _db.closeShift(updatedShift);

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Center(
            child: Icon(
              difference == 0 ? Icons.check_circle : (difference > 0 ? Icons.info : Icons.warning),
              color: difference == 0 ? AppColors.success : (difference > 0 ? AppColors.info : AppColors.error),
              size: 64,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Shift Berhasil Ditutup!', style: AppFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 16),
              _summaryRow('Seharusnya Ada:', currencyFormatter.format(widget.shift.expectedCash)),
              _summaryRow('Uang Fisik:', currencyFormatter.format(actualCash)),
              const Divider(height: 24),
              _summaryRow(
                'Selisih:',
                difference == 0 ? 'Balance' : currencyFormatter.format(difference),
                valueColor: difference == 0 ? AppColors.success : (difference > 0 ? AppColors.info : AppColors.error),
                isBold: true,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                child: Text('Kembali ke Login', style: AppFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _summaryRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
          Text(
            value,
            style: AppFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tutup Shift', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Hitung Uang Laci',
                      style: AppFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Silakan hitung semua uang tunai yang ada di dalam laci saat ini dan masukkan jumlahnya di bawah.',
                      textAlign: TextAlign.center,
                      style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Modal Awal', currencyFormatter.format(widget.shift.startingCash)),
                        _summaryRow('Pendapatan Tunai', currencyFormatter.format(widget.shift.expectedCash - widget.shift.startingCash)),
                        const Divider(),
                        _summaryRow('Estimasi Laci', currencyFormatter.format(widget.shift.expectedCash), isBold: true, valueColor: AppColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Uang Fisik Sebenarnya (Rp)', style: AppFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _actualCashCtrl,
                    keyboardType: TextInputType.number,
                    style: AppFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: AppFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      final val = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                      if (val == null) return 'Angka tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Tutup Kasir', style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
