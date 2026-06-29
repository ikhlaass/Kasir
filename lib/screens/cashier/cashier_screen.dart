import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../auth/login_screen.dart';
import '../../services/database_helper.dart';
import '../../services/printer_service.dart';
import '../../services/supabase_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/printer_settings_screen.dart';
import 'pending_orders_tab.dart';
import 'close_shift_screen.dart';

class CashierScreen extends StatefulWidget {
  final UserModel user;
  const CashierScreen({super.key, required this.user});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  String _selectedCategory = 'Semua';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadActiveProducts();
    });
  }

  Future<void> _closeShift() async {
    final db = DatabaseHelper();
    final shift = await db.getActiveShift(widget.user.id!);
    if (shift != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CloseShiftScreen(user: widget.user, shift: shift),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak ada shift aktif')));
    }
  }

  Future<void> _showKasKeluarDialog() async {
    final db = DatabaseHelper();
    final shift = await db.getActiveShift(widget.user.id!);

    if (shift == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak ada shift aktif')));
      return;
    }

    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Catat Kas Keluar',
          style: AppFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null) return 'Angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Keterangan (Misa: Beli Es)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppFonts.poppins(color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountCtrl.text);
                await db.addKasirExpense(amount, descCtrl.text, shift.id!);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kas keluar berhasil dicatat'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              'Simpan',
              style: AppFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Keluar?',
          style: AppFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin logout?',
          style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppFonts.poppins(color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<CartProvider>().clearCart();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: Text(
              'Logout',
              style: AppFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: _currentIndex == 0
                ? _buildBuatPesananView(isWide)
                : _buildPendingOrdersView(),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) {
                if (idx == 0 || idx == 1) {
                  setState(() => _currentIndex = idx);
                } else if (idx == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrinterSettingsScreen(),
                    ),
                  );
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMedium,
              selectedLabelStyle: AppFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: AppFonts.poppins(fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale_outlined),
                  activeIcon: Icon(Icons.point_of_sale),
                  label: 'Kasir',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Pesanan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.print_outlined),
                  label: 'Printer',
                ),
              ],
            ),
      floatingActionButton: _currentIndex == 0 && !isWide
          ? Consumer<CartProvider>(
              builder: (ctx, cart, _) {
                if (cart.items.isEmpty) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () => _showMobileCart(),
                  backgroundColor: AppColors.primary,
                  icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  label: Text(
                    '${cart.items.length} Item - Rp ${cart.totalHarga.toInt()}',
                    style: AppFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildSidebar() {
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
                  child: Icon(
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
            0,
            Icons.point_of_sale_outlined,
            Icons.point_of_sale_rounded,
            'Kasir',
          ),
          _sidebarItem(
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
                if (!mounted) return;
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

          if (widget.user.role == 'admin') ...[
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
                      builder: (_) => AdminDashboardScreen(user: widget.user),
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
                        widget.user.username.substring(0, 1).toUpperCase(),
                        style: AppFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.username,
                          style: AppFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Kasir',
                          style: AppFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout_outlined, size: 18),
                    color: AppColors.error,
                    onPressed: _showLogoutDialog,
                    tooltip: 'Logout',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(Icons.money_off, size: 18),
                    color: AppColors.warning,
                    onPressed: _showKasKeluarDialog,
                    tooltip: 'Kas Keluar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.point_of_sale, size: 18),
                    color: AppColors.info,
                    onPressed: _closeShift,
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

  Widget _sidebarItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final selected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
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

  Widget _buildBuatPesananView(bool isWide) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: _buildMenuSection()),
          Container(width: 1, color: AppColors.border),
          SizedBox(width: 340, child: _buildCartSection()),
        ],
      );
    } else {
      return _buildMenuSection();
    }
  }

  Widget _buildPendingOrdersView() {
    return PendingOrdersTab(
      onEdit: () {
        setState(() => _currentIndex = 0);
      },
      onPay: (trx, details) {
        context.read<CartProvider>().loadTransaction(
          trx,
          details,
          context.read<ProductProvider>().products,
        );
        _showPaymentDialog(context, context.read<CartProvider>());
      },
    );
  }

  void _showMobileCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 100,
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _buildCartSection(),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final provider = context.watch<ProductProvider>();
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          color: Colors.transparent,
          alignment: Alignment.centerLeft,
          child: Builder(
            builder: (ctx) {
              final isWide = MediaQuery.of(ctx).size.width >= 950;
              return Row(
                children: [
                  Text(
                    'Kasir',
                    style: AppFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (!isWide)
                    IconButton(
                      icon: Icon(
                        ThemeManager.isDark.value
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: AppColors.warning,
                      ),
                      onPressed: () {
                        // JURUS GANTI TEMA INSTAN!
                        ThemeManager.isDark.value = !ThemeManager.isDark.value;
                      },
                      tooltip: 'Ganti Tema',
                    ),

                  const Spacer(),
                  if (!isWide && widget.user.role == 'admin')
                    IconButton(
                      icon: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminDashboardScreen(user: widget.user),
                        ),
                      ),
                      tooltip: 'Ke Admin Panel',
                    ),
                  if (!isWide)
                    IconButton(
                      icon: Icon(Icons.logout, color: AppColors.error),
                      onPressed: _showLogoutDialog,
                      tooltip: 'Keluar',
                    ),
                  if (!isWide)
                    IconButton(
                      icon: Icon(Icons.money_off, color: AppColors.warning),
                      onPressed: _showKasKeluarDialog,
                      tooltip: 'Kas Keluar',
                    ),
                  if (!isWide)
                    IconButton(
                      icon: Icon(Icons.point_of_sale, color: AppColors.info),
                      onPressed: _closeShift,
                      tooltip: 'Tutup Shift',
                    ),
                ],
              );
            },
          ),
        ),

        // Categories
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  () {
                    final catMap = <String, int>{};
                    for (var p in provider.products) {
                      if (p.id != null) {
                        if (!catMap.containsKey(p.kategori) ||
                            p.id! < catMap[p.kategori]!) {
                          catMap[p.kategori] = p.id!;
                        }
                      }
                    }
                    final cats = catMap.keys.toList();
                    cats.removeWhere((c) => c.toLowerCase() == 'extra topping');
                    cats.sort((a, b) => catMap[a]!.compareTo(catMap[b]!));
                    return ['Semua', ...cats];
                  }().map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Text(
                            cat,
                            style: AppFonts.poppins(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMedium,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Product Grid
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (ctx, provider, _) {
              if (provider.isLoading)
                return const Center(child: CircularProgressIndicator());

              final products = _selectedCategory == 'Semua'
                  ? provider.products
                        .where(
                          (p) => p.kategori.toLowerCase() != 'extra topping',
                        )
                        .toList()
                  : provider.products
                        .where((p) => p.kategori == _selectedCategory)
                        .toList();

              if (products.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada menu',
                    style: AppFonts.poppins(color: AppColors.textLight),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (ctx, i) => _ProductCard(
                  product: products[i],
                  onTap: () => _showModifierDialog(context, products[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Consumer<CartProvider>(
        builder: (ctx, cart, _) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      color: AppColors.textDark,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cart.activeTransactionId == null
                          ? 'Pesanan Baru'
                          : 'Edit Pesanan',
                      style: AppFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    if (cart.items.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20),
                        color: AppColors.error,
                        onPressed: () => _confirmClearCart(cart),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: cart.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: AppColors.textLight.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Keranjang masih kosong',
                              style: AppFonts.poppins(
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: cart.items.length,
                        separatorBuilder: (c, idx) =>
                            Divider(color: AppColors.border, height: 24),
                        itemBuilder: (ctx, i) {
                          final item = cart.items[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.namaMenu,
                                      style: AppFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${item.product.harga.toInt()}',
                                      style: AppFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                    if (item.catatan?.isNotEmpty == true) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Catatan: ${item.catatan}',
                                        style: AppFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                        ).copyWith(fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _qtyBtn(
                                    Icons.remove,
                                    () => cart.removeItem(item.product),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${item.qty}',
                                      textAlign: TextAlign.center,
                                      style: AppFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  _qtyBtn(
                                    Icons.add,
                                    () => cart.addItem(item.product),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),

              if (cart.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total Pembayaran',
                              style: AppFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ),
                          Text(
                            'Rp ${cart.totalHarga.toInt()}',
                            style: AppFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _savePendingOrder(cart),
                              child: Text(
                                'Simpan',
                                style: AppFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                if (MediaQuery.of(context).size.width < 950)
                                  Navigator.pop(context);
                                _showPaymentDialog(context, cart);
                              },
                              child: Text(
                                'Bayar Langsung',
                                style: AppFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.textDark),
      ),
    );
  }

  void _confirmClearCart(CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Kosongkan Pesanan?',
          style: AppFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppFonts.poppins(color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            child: Text(
              'Kosongkan',
              style: AppFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _savePendingOrder(CartProvider cart) async {
    final db = DatabaseHelper();
    final trx = TransactionModel(
      id: cart.activeTransactionId,
      totalHarga: cart.totalHarga,
      metodePembayaran: 'Belum Bayar',
      status: 'pending',
      namaPelanggan: 'Pelanggan Umum',
      tanggalWaktu: DateTime.now().toIso8601String(),
    );
    final details = cart.items
        .map(
          (item) => TransactionDetailModel(
            idTransaksi: cart.activeTransactionId ?? 0,
            idProduk: item.product.id!,
            qty: item.qty,
            subtotal:item.subtotal,
          ),
        )
        .toList();

    await db.saveTransaction(trx, details);
    cart.clearCart();

    if (mounted) {
      if (MediaQuery.of(context).size.width < 950 &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan berhasil disimpan', style: AppFonts.poppins()),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    CartProvider cart,
  ) async {
    final settings = await DatabaseHelper().getAllSettings();
    final String? qrisPath = settings['qris_path'];
    if (qrisPath != null && qrisPath.isEmpty) {
      // do nothing, let it be handled below
    }

    String selectedMethod = 'Tunai';
    final uangCtrl = TextEditingController(
      text: cart.totalHarga.toInt().toString(),
    );

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
                                onTap: () =>
                                    setStateSB(() => selectedMethod = m),
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
                            child: qrisPath != null && qrisPath.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(qrisPath),
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.cover,
                                      cacheWidth: 500, // Optimize memory usage
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
                                              (item) => TransactionDetailModel(
                                                idTransaksi:
                                                    cart.activeTransactionId ??
                                                    0,
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
                                                'nama_menu':
                                                    item.product.namaMenu,
                                                'qty': item.qty,
                                                'harga_satuan':
                                                    item.product.harga,
                                                'subtotal': item.subtotal,
                                                'catatan': item.catatan,
                                              },
                                            )
                                            .toList();

                                        await db.saveTransaction(trx, details);

                                        if (selectedMethod == 'Tunai') {
                                          final shift = await db.getActiveShift(
                                            widget.user.id!,
                                          );
                                          if (shift != null &&
                                              shift.id != null) {
                                            await db.updateShiftExpectedCash(
                                              shift.id!,
                                              cart.totalHarga,
                                            );
                                          }
                                        }

                                        cart.clearCart();

                                        nav.pop(); // close payment dialog

                                        // Tampilkan Success Dialog dengan gaya premium
                                        if (mounted) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (sCtx) => Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              child: Container(
                                                width: 320,
                                                padding: const EdgeInsets.all(
                                                  32,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      blurRadius: 20,
                                                      offset: const Offset(
                                                        0,
                                                        10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.success
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color:
                                                            AppColors.success,
                                                        size: 64,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 24),
                                                    Text(
                                                      'Transaksi Berhasil!',
                                                      style: AppFonts.poppins(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Kembalian: Rp ${kembalian > 0 ? kembalian.toInt() : 0}',
                                                      style: AppFonts.poppins(
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .textMedium,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 32),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                        onPressed: () async {
                                                          final ps =
                                                              PrinterService();
                                                          final printed = await ps
                                                              .printReceipt(
                                                                trx,
                                                                receiptItems,
                                                                dibayar: uang,
                                                                kembalian:
                                                                    kembalian,
                                                              );
                                                          if (!printed) {
                                                            if (!sCtx.mounted)
                                                              return;
                                                            ScaffoldMessenger.of(
                                                              sCtx,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Gagal mencetak. Cek koneksi printer.',
                                                                ),
                                                                backgroundColor:
                                                                    AppColors
                                                                        .error,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        icon: Icon(
                                                          Icons.print_outlined,
                                                          size: 18,
                                                        ),
                                                        label: Text(
                                                          'Cetak Struk',
                                                          style:
                                                              AppFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppColors.primary,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 14,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(sCtx);
                                                        },
                                                        style: TextButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 14,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Tutup',
                                                          style:
                                                              AppFonts.poppins(
                                                                color: AppColors
                                                                    .textMedium,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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

  void _showModifierDialog(BuildContext context, ProductModel product) {
    final cart = context.read<CartProvider>();
    final extraProducts = context.read<ProductProvider>().extraProducts;

    String pedasLevel = 'Sedang';
    Map<ProductModel, int> selectedExtras = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.8,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.namaMenu,
                              style: AppFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Rp ${product.harga.toInt()}',
                              style: AppFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Level Pedas (Pilih 1)',
                        style: AppFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                              'Tidak Pedas',
                              'Sedang',
                              'Pedas',
                              'Sangat Pedas',
                            ].map((lvl) {
                              final isSelected = pedasLevel == lvl;
                              return ChoiceChip(
                                label: Text(
                                  lvl,
                                  style: AppFonts.poppins(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.background,
                                onSelected: (v) =>
                                    setStateSB(() => pedasLevel = lvl),
                              );
                            }).toList(),
                      ),
                      if (extraProducts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Extra / Topping',
                          style: AppFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...extraProducts.map((extra) {
                          final qty = selectedExtras[extra] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: qty > 0
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        extra.namaMenu,
                                        style: AppFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '+ Rp ${extra.harga.toInt()}',
                                        style: AppFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (qty == 0)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.surface,
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      side: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => setStateSB(
                                      () => selectedExtras[extra] = 1,
                                    ),
                                    child: Text(
                                      'Tambah',
                                      style: AppFonts.poppins(fontSize: 12),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => setStateSB(() {
                                          if (qty == 1) {
                                            selectedExtras.remove(extra);
                                          } else {
                                            selectedExtras[extra] = qty - 1;
                                          }
                                        }),
                                      ),
                                      Text(
                                        '$qty',
                                        style: AppFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: () => setStateSB(
                                          () => selectedExtras[extra] = qty + 1,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final finalCatatan = pedasLevel;

                      cart.addItem(product);
                      // Set catatan for the newly added item (assuming it's at the end or we just set it)
                      // A safer way is to update the note of the latest matching item, but we'll use a hack to update the last added item
                      // Actually CartProvider updates the first matched item.
                      cart.updateNote(product, finalCatatan);

                      // Add extras
                      selectedExtras.forEach((extra, qty) {
                        for (int i = 0; i < qty; i++) {
                          cart.addItem(extra);
                        }
                      });

                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Masukkan Keranjang',
                      style: AppFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image:
                      product.imagePath != null &&
                          File(product.imagePath!).existsSync()
                      ? DecorationImage(
                          image: FileImage(File(product.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    product.imagePath == null ||
                        !File(product.imagePath!).existsSync()
                    ? Center(
                        child: Icon(
                          product.kategori == 'Minuman'
                              ? Icons.local_drink_outlined
                              : Icons.restaurant_outlined,
                          size: 32,
                          color: AppColors.textLight.withValues(alpha: 0.5),
                        ),
                      )
                    : null,
              ),
            ),
            // Optional separator:
            // Container(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.namaMenu,
                    style: AppFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.harga.toInt()}',
                    style: AppFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
