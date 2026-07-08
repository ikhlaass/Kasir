import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../auth/login_screen.dart';
import '../../services/database_helper.dart';
import '../../services/supabase_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/printer_settings_screen.dart';
import 'widgets/sidebar_widget.dart';
import 'widgets/cart_section_widget.dart';
import 'widgets/checkout_dialog.dart';
import 'widgets/product_modifier_dialog.dart';
import 'widgets/product_card.dart';
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
      if (!mounted) return;
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
                  labelText: 'Keterangan (Misal: Beli Es)',
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
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                
                await db.addKasirExpense(amount, descCtrl.text, shift.id!);
                
                // Auto-sync in background
                SupabaseService().syncData().catchError((_) {});
                
                nav.pop();
                messenger.showSnackBar(
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
          if (isWide) SidebarWidget(user: widget.user, currentIndex: _currentIndex, onIndexChanged: (i) => setState(() => _currentIndex = i), onLogout: _showLogoutDialog, onKasKeluar: _showKasKeluarDialog, onCloseShift: _closeShift),
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

  Widget _buildBuatPesananView(bool isWide) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: _buildMenuSection()),
          Container(width: 1, color: AppColors.border),
          SizedBox(width: 340, child: CartSectionWidget(onSaveOrder: _savePendingOrder, onPay: (ctx, cart) => showCheckoutDialog(ctx, cart, widget.user))),
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
        showCheckoutDialog(context, context.read<CartProvider>(), widget.user);
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
          child: CartSectionWidget(onSaveOrder: _savePendingOrder, onPay: (ctx, cart) => showCheckoutDialog(ctx, cart, widget.user)),
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
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

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
                itemBuilder: (ctx, i) => ProductCard(
                  product: products[i],
                  onTap: () => showModifierDialog(context, products[i]),
                ),
              );
            },
          ),
        ),
      ],
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

  }
