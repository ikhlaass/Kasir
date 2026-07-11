import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../cashier/cashier_screen.dart';
import '../cashier/open_shift_screen.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    // Sinkronisasi data otomatis saat aplikasi baru dibuka
    SupabaseService().syncData().catchError((_) {});
    _initializeFlow();
  }

  Future<void> _initializeFlow() async {
    final dbHelper = DatabaseHelper();
    
    // Get default kasir user (assuming first kasir user in db)
    final kasirs = await dbHelper.getAllKasir();
    if (kasirs.isEmpty) {
      // If no kasir found, maybe show error or wait
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun kasir tidak ditemukan di database.', style: AppFonts.poppins()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final kasirUser = kasirs.first;
    
    // Check if there is an active shift
    final activeShift = await dbHelper.getActiveShift(kasirUser.id!);
    
    if (!mounted) return;
    
    if (activeShift == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OpenShiftScreen(user: kasirUser)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CashierScreen(user: kasirUser)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Menyiapkan Kasir...',
              style: AppFonts.poppins(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
