import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_fonts.dart';
import '../../../services/supabase_service.dart';
import '../../../providers/product_provider.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../admin/printer_settings_screen.dart';

class SidebarWidget extends StatelessWidget {
  final UserModel user;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onLogout;
  final VoidCallback onKasKeluar;
  final VoidCallback onCloseShift;

  const SidebarWidget({
    super.key,
    required this.user,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onLogout,
    required this.onKasKeluar,
    required this.onCloseShift,
  });

  Widget _sidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final selected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => onIndexChanged(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected ? AppColors.primary : AppColors.textLight,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kasir POS',
                    style: AppFonts.poppins(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Nav items
          _sidebarItem(
            context,
            0,
            Icons.point_of_sale_outlined,
            Icons.point_of_sale_rounded,
            'Kasir',
          ),
          _sidebarItem(
            context,
            1,
            Icons.receipt_long_outlined,
            Icons.receipt_long_rounded,
            'Daftar Pesanan',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrinterSettingsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.print_outlined,
                      color: AppColors.textLight,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Printer',
                      style: AppFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: InkWell(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menyinkronkan data...')),
                );
                await SupabaseService().syncDataFull().catchError((_) {});
                if (!context.mounted) return;
                context.read<ProductProvider>().loadActiveProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sinkronisasi selesai')),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.sync, color: AppColors.textLight, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      'Sinkronisasi',
                      style: AppFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (user.role == 'admin') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppColors.border, height: 1),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDashboardScreen(user: user),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AppColors.textMedium,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ke Admin Panel',
                        style: AppFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Cashier badge & Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: AppFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: AppFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Kasir',
                          style: AppFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    color: AppColors.error,
                    onPressed: onLogout,
                    tooltip: 'Logout',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.work_history_outlined, size: 16, color: AppColors.textMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Shift Aktif',
                      style: AppFonts.poppins(fontSize: 11, color: AppColors.textMedium),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.money_off, size: 18),
                    color: AppColors.warning,
                    onPressed: onKasKeluar,
                    tooltip: 'Kas Keluar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.point_of_sale, size: 18),
                    color: AppColors.info,
                    onPressed: onCloseShift,
                    tooltip: 'Tutup Shift',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
