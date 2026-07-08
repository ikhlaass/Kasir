import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/product_provider.dart';
import '../../services/database_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';
import 'product_management_screen.dart';
import 'report_screen.dart';
import 'expense_screen.dart';
import 'settings_screen.dart';
import '../cashier/cashier_screen.dart';
import '../../services/supabase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Dashboard'),
    _NavItem(
      Icons.restaurant_menu_outlined,
      Icons.restaurant_menu_rounded,
      'Menu',
    ),
    _NavItem(Icons.analytics_outlined, Icons.analytics_rounded, 'Laporan'),
    _NavItem(
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      'Pengeluaran',
    ),
    _NavItem(Icons.tune_outlined, Icons.tune_rounded, 'Pengaturan'),
  ];

  List<Widget> get _pages => [
    _DashboardTab(user: widget.user),
    const ProductManagementScreen(),
    const ReportScreen(),
    const ExpenseScreen(),
    SettingsScreen(adminUsername: widget.user.username),
  ];

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    // Adaptive: sidebar ≥ 700px, bottom bar < 700px
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final body = IndexedStack(index: _selectedIndex, children: _pages);

        if (isWide) {
          return _buildSidebarLayout(body);
        } else {
          return _buildBottomBarLayout(body);
        }
      },
    );
  }

  // ═══════ SIDEBAR LAYOUT (Desktop/Tablet) ════════════════════════════════
  Widget _buildSidebarLayout(Widget body) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
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
                          Icons.blur_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Admin Panel',
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
                ...List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final selected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.background
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: AppFonts.poppins(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Buka Kasir button
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CashierScreen(user: widget.user),
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
                            Icons.point_of_sale_outlined,
                            color: AppColors.textMedium,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Buka Kasir (POS)',
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

                const Spacer(),

                // Owner badge at bottom
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
                              widget.user.username
                                  .substring(0, 1)
                                  .toUpperCase(),
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
                                'Owner',
                                style: AppFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(child: body),
        ],
      ),
    );
  }

  // ═══════ BOTTOM BAR LAYOUT (Mobile) ═════════════════════════════════════
  Widget _buildBottomBarLayout(Widget body) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.background
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textLight,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.poppins(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  final UserModel user;
  const _DashboardTab({required this.user});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> with WidgetsBindingObserver {
  final _db = DatabaseHelper();

  double _todayRevenue = 0;
  int _todayOrders = 0;
  double _avgTrx = 0;
  double _targetHarian = 500000;
  double _todayExpenses = 0;
  int _activeOrderCount = 0;
  Map<String, dynamic> _monthlyData = {};
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _topSellers = [];
  List<Map<String, dynamic>> _leastSellers = [];
  List<Map<String, dynamic>> _paymentStats = [];
  List<Map<String, dynamic>> _peakHours = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-sync when app comes to foreground
      SupabaseService().syncData().then((_) {
        if (mounted) _loadAll();
      }).catchError((_) {});
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _loading = true);
    await SupabaseService().syncData().catchError((_) {});
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _db.getTodayRevenue(),
      _db.getTodayOrderCount(),
      _db.getTodayAvgTransaction(),
      _db.getWeeklyRevenue(),
      _db.getTopSellingProducts(limit: 5),
      _db.getPaymentMethodStats(),
      _db.getPeakHours(),
      _db.getTargetHarian(),
      _db.getTodayExpenses(),
      _db.getActiveOrderCount(),
      _db.getMonthlyComparison(),
      _db.getLeastSellingProducts(limit: 5),
    ]);
    if (mounted) {
      setState(() {
        _todayRevenue = results[0] as double;
        _todayOrders = results[1] as int;
        _avgTrx = results[2] as double;
        _weeklyData = List<Map<String, dynamic>>.from(results[3] as List);
        _topSellers = List<Map<String, dynamic>>.from(results[4] as List);
        _paymentStats = List<Map<String, dynamic>>.from(results[5] as List);
        _peakHours = List<Map<String, dynamic>>.from(results[6] as List);
        _targetHarian = results[7] as double;
        _todayExpenses = results[8] as double;
        _activeOrderCount = results[9] as int;
        _monthlyData = results[10] as Map<String, dynamic>;
        _leastSellers = List<Map<String, dynamic>>.from(results[11] as List);
        _loading = false;
      });
    }
  }

  String _fc(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  String _fcFull(double v) {
    final s = v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $s';
  }

  // ── Ubah Target Harian ──────────────────────────────────────────────────
  void _editTarget() {
    final ctrl = TextEditingController(text: _targetHarian.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Harian',
                  style: AppFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set target pendapatan harian Anda.',
                  style: AppFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Target (Rp)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty || double.tryParse(v) == null)
                      ? 'Nilai tidak valid'
                      : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Batal',
                        style: AppFonts.poppins(color: AppColors.textMedium),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final val = double.parse(ctrl.text);
                        await _db.setTargetHarian(val);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        setState(() => _targetHarian = val);
                      },
                      child: Text(
                        'Simpan',
                        style: AppFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    _buildKpiGrid(),
                    const SizedBox(height: 16),
                    _buildActiveOrders(),
                    const SizedBox(height: 16),
                    _buildProfitCard(),
                    const SizedBox(height: 16),
                    _buildTargetHarian(),
                    const SizedBox(height: 16),
                    _buildMonthlyComparison(),
                    const SizedBox(height: 16),
                    _buildWeeklyChart(),
                    const SizedBox(height: 16),
                    _buildPeakHours(),
                    const SizedBox(height: 16),
                    _buildTopSellers(),
                    const SizedBox(height: 16),
                    _buildLeastSellers(),
                    const SizedBox(height: 16),
                    _buildPaymentStats(),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 17
        ? 'Selamat Siang'
        : 'Selamat Malam';
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: Icon(
            ThemeManager.isDark.value ? Icons.light_mode : Icons.dark_mode,
            color: AppColors.warning,
          ),
          onPressed: () {
            ThemeManager.isDark.value = !ThemeManager.isDark.value;
          },
          tooltip: 'Ganti Tema',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$greeting,',
                style: AppFonts.poppins(
                  color: AppColors.textMedium,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.username,
                style: AppFonts.poppins(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── KPI Grid ────────────────────────────────────────────────────────────
  Widget _buildKpiGrid() {
    final topMenu = _topSellers.isNotEmpty
        ? _topSellers.first['nama_menu'] as String
        : '-';
    final kpis = [
      _KpiData('Pendapatan', _fc(_todayRevenue), Icons.payments_outlined),
      _KpiData('Pesanan', '$_todayOrders trx', Icons.receipt_long_outlined),
      _KpiData('Rata-rata', _fc(_avgTrx), Icons.trending_up_rounded),
      _KpiData('Menu Terlaris', topMenu, Icons.emoji_events_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        double aspectRatio = 1.4;

        if (width >= 800) {
          crossAxisCount = 4;
          aspectRatio = 1.8;
        } else if (width >= 600) {
          crossAxisCount = 3;
          aspectRatio = 1.6;
        } else if (width >= 400) {
          crossAxisCount = 2;
          aspectRatio = 1.6;
        } else {
          crossAxisCount = 2;
          aspectRatio = 1.2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: kpis.length,
          itemBuilder: (ctx, i) => _KpiCard(data: kpis[i]),
        );
      },
    );
  }

  // ── Pesanan Aktif ───────────────────────────────────────────────────────
  Widget _buildActiveOrders() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _activeOrderCount > 0
            ? AppColors.warning.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _activeOrderCount > 0
            ? [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.pending_actions_outlined,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Aktif Saat Ini',
                  style: AppFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_activeOrderCount pesanan',
                  style: AppFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          if (_activeOrderCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LIVE',
                style: AppFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Laba Bersih Harian ──────────────────────────────────────────────────
  Widget _buildProfitCard() {
    final profit = _todayRevenue - _todayExpenses;
    final isPositive = profit >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                color: AppColors.textMedium,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Laba Bersih Hari Ini',
                style: AppFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Omzet',
                      style: AppFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _fcFull(_todayRevenue),
                        style: AppFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('—', style: AppFonts.poppins(fontSize: 16, color: AppColors.textLight)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Pengeluaran',
                      style: AppFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _fcFull(_todayExpenses),
                        style: AppFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('=', style: AppFonts.poppins(fontSize: 16, color: AppColors.textLight)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Laba',
                      style: AppFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${isPositive ? '+' : ''}${_fcFull(profit)}',
                        style: AppFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Target Harian ────────────────────────────────────────────────────────
  Widget _buildTargetHarian() {
    final pct = _targetHarian > 0
        ? (_todayRevenue / _targetHarian).clamp(0.0, 1.0)
        : 0.0;
    final tercapai = pct >= 1.0;
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.track_changes_outlined,
                    color: AppColors.textMedium,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Target Harian',
                    style: AppFonts.poppins(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              InkWell(
                key: const Key('edit_target'),
                onTap: _editTarget,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Edit',
                    style: AppFonts.poppins(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _fcFull(_todayRevenue),
                        style: AppFonts.poppins(
                          color: AppColors.textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'dari ${_fcFull(_targetHarian)}',
                      style: AppFonts.poppins(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                pctLabel,
                style: AppFonts.poppins(
                  color: tercapai ? AppColors.success : AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                tercapai ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly Chart ─────────────────────────────────────────────────────────
  Widget _buildWeeklyChart() {
    final maxRev = _weeklyData.fold(0.0, (mx, d) {
      final v = (d['total'] as num).toDouble();
      return v > mx ? v : mx;
    });
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    return _SectionCard(
      title: 'Pendapatan 7 Hari',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _weeklyData.map((d) {
            final rev = (d['total'] as num).toDouble();
            final isToday = d['date'] == todayStr;
            final pct = maxRev > 0 ? (rev / maxRev).clamp(0.05, 1.0) : 0.05;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (rev > 0)
                      Text(
                        rev >= 1000000
                            ? '${(rev / 1000000).toStringAsFixed(1)}jt'
                            : '${(rev / 1000).toStringAsFixed(0)}k',
                        style: AppFonts.poppins(
                          fontSize: 9,
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isToday
                              ? AppColors.textDark
                              : AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: pct,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d['day'] as String,
                      style: AppFonts.poppins(
                        fontSize: 10,
                        color: isToday
                            ? AppColors.textDark
                            : AppColors.textLight,
                        fontWeight: isToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Peak Hours Chart ──────────────────────────────────────────────────────
  Widget _buildPeakHours() {
    if (_peakHours.isEmpty) {
      return const _SectionCard(
        title: 'Jam Sibuk',
        icon: Icons.schedule_rounded,
        child: _EmptyInfo('Belum ada data'),
      );
    }

    final maxJumlah = _peakHours.fold(0, (mx, d) {
      final v = (d['jumlah'] as num).toInt();
      return v > mx ? v : mx;
    });

    final busiest = _peakHours.reduce(
      (a, b) => (a['jumlah'] as num) >= (b['jumlah'] as num) ? a : b,
    );
    final busiestHour = (busiest['hour'] as num).toInt();

    return _SectionCard(
      title: 'Jam Sibuk',
      icon: Icons.schedule_rounded,
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _peakHours.map((d) {
            final hour = (d['hour'] as num).toInt();
            final jumlah = (d['jumlah'] as num).toInt();
            final isBusiest = hour == busiestHour;
            final pct = maxJumlah > 0
                ? (jumlah / maxJumlah).clamp(0.06, 1.0)
                : 0.06;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isBusiest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$jumlah',
                          style: AppFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: pct,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBusiest
                                ? AppColors.textDark
                                : AppColors.border,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hour.toString().padLeft(2, '0'),
                      style: AppFonts.poppins(
                        fontSize: 9,
                        color: isBusiest
                            ? AppColors.textDark
                            : AppColors.textLight,
                        fontWeight: isBusiest
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Top Sellers ───────────────────────────────────────────────────────────
  Widget _buildTopSellers() {
    if (_topSellers.isEmpty) {
      return const _SectionCard(
        title: 'Top Menu',
        icon: Icons.star_border_rounded,
        child: _EmptyInfo('Belum ada data'),
      );
    }
    final maxQty = (_topSellers.first['total_qty'] as num).toDouble();

    return _SectionCard(
      title: 'Top Menu',
      icon: Icons.star_border_rounded,
      child: Column(
        children: List.generate(_topSellers.length, (i) {
          final item = _topSellers[i];
          final qty = (item['total_qty'] as num).toDouble();
          final rev = (item['total_revenue'] as num).toDouble();
          final pct = maxQty > 0 ? qty / maxQty : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${i + 1}.',
                      style: AppFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['nama_menu'] as String,
                        style: AppFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _fcFull(rev),
                      style: AppFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${qty.toInt()} porsi',
                      style: AppFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Monthly Comparison ──────────────────────────────────────────────────
  Widget _buildMonthlyComparison() {
    if (_monthlyData.isEmpty) return const SizedBox.shrink();

    final thisRev = _monthlyData['thisRevenue'] as double;
    final lastRev = _monthlyData['lastRevenue'] as double;
    final revChange = _monthlyData['revenueChange'] as double;
    final revIsUp = revChange >= 0;

    return _SectionCard(
      title: 'Performa Bulan Ini',
      icon: Icons.insights_rounded,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Omzet Bulan Ini',
                  style: AppFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fcFull(thisRev),
                  style: AppFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bulan Lalu',
                    style: AppFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        _fcFull(lastRev),
                        style: AppFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (revIsUp ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              revIsUp
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: revIsUp
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${revChange.abs().toStringAsFixed(1)}%',
                              style: AppFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: revIsUp
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Least Selling Products (Menu Kurang Laku) ───────────────────────────
  Widget _buildLeastSellers() {
    if (_leastSellers.isEmpty) {
      return const _SectionCard(
        title: 'Menu Paling Sedikit Terjual',
        icon: Icons.trending_down_rounded,
        child: _EmptyInfo('Belum ada data'),
      );
    }

    return _SectionCard(
      title: 'Menu Paling Sedikit Terjual',
      icon: Icons.trending_down_rounded,
      child: Column(
        children: List.generate(_leastSellers.length, (i) {
          final item = _leastSellers[i];
          final qty = (item['total_qty'] as num).toInt();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: AppFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
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
                        item['nama_menu'] as String,
                        style: AppFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        item['kategori'] as String,
                        style: AppFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$qty terjual',
                    style: AppFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Payment Stats ─────────────────────────────────────────────────────────
  Widget _buildPaymentStats() {
    if (_paymentStats.isEmpty) {
      return const _SectionCard(
        title: 'Pembayaran',
        icon: Icons.credit_card_outlined,
        child: _EmptyInfo('Belum ada data'),
      );
    }
    final total = _paymentStats.fold(
      0,
      (s, e) => s + (e['jumlah'] as num).toInt(),
    );

    return _SectionCard(
      title: 'Pembayaran',
      icon: Icons.credit_card_outlined,
      child: Column(
        children: _paymentStats.map((s) {
          final method = s['metode_pembayaran'] as String;
          final count = (s['jumlah'] as num).toInt();
          final rev = (s['total'] as num).toDouble();
          final pct = total > 0 ? count / total : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.wallet_rounded,
                    size: 16,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method,
                        style: AppFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '$count transaksi (${(pct * 100).toStringAsFixed(0)}%)',
                        style: AppFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _fcFull(rev),
                  style: AppFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────

class _KpiData {
  final String label, value;
  final IconData icon;
  const _KpiData(this.label, this.value, this.icon);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(data.icon, color: AppColors.textMedium, size: 20),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  style: AppFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    data.value,
                    style: AppFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textMedium, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _EmptyInfo extends StatelessWidget {
  final String message;
  const _EmptyInfo(this.message);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: AppFonts.poppins(color: AppColors.textLight, fontSize: 13),
        ),
      ),
    );
  }
}
