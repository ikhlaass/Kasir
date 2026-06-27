import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/database_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _db = DatabaseHelper();
  String _selectedPeriod = 'today';
  bool _isLoading = true;

  List<TransactionModel> _transactions = [];
  double _totalRevenue = 0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final trxs = await _db.getTransactionsByPeriod(_selectedPeriod);

    double rev = 0;
    for (var t in trxs) {
      rev += t.totalHarga;
    }

    if (mounted) {
      setState(() {
        _transactions = trxs;
        _totalRevenue = rev;
        _totalTransactions = trxs.length;
        _isLoading = false;
      });
    }
  }



  String _fc(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) { Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Laporan Transaksi', style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.5)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              Container(color: AppColors.border, height: 1),
              Container(
                height: 59,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Text('Filter:', style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('Hari Ini', 'today'),
                            const SizedBox(width: 8),
                            _filterChip('7 Hari', 'week'),
                            const SizedBox(width: 8),
                            _filterChip('Bulan Ini', 'month'),
                            const SizedBox(width: 8),
                            _filterChip('Semua', 'all'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(color: AppColors.border, height: 1),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Summary Grid
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Total Pendapatan',
                              value: _fc(_totalRevenue),
                              icon: Icons.payments_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatBox(
                              label: 'Total Pesanan',
                              value: '$_totalTransactions trx',
                              icon: Icons.receipt_long_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Riwayat Transaksi', style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.5)),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),
                if (_transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 48, color: AppColors.textLight.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('Belum ada transaksi', style: AppFonts.poppins(color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TrxCard(trx: _transactions[i]),
                        childCount: _transactions.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, String value) {
    final sel = _selectedPeriod == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = value);
        _loadData();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: sel ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(
          label,
          style: AppFonts.poppins(
            fontSize: 12,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
            color: sel ? Colors.white : AppColors.textMedium,
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) { Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMedium, size: 20),
          const SizedBox(height: 12),
          Text(label, style: AppFonts.poppins(fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 2),
          Text(value, style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _TrxCard extends StatelessWidget {
  final TransactionModel trx;
  const _TrxCard({required this.trx});

  String _fc(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) { Theme.of(context);
    final dt = DateTime.parse(trx.tanggalWaktu);
    final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.receipt_outlined, color: AppColors.textMedium, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRX-${trx.id.toString().padLeft(4, '0')}', style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('$dateStr • $timeStr', style: AppFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fc(trx.totalHarga), style: AppFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(trx.metodePembayaran, style: AppFonts.poppins(fontSize: 10, color: AppColors.textMedium)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) async {
    final db = DatabaseHelper();
    final details = await db.getTransactionDetails(trx.id!);

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detail Transaksi', style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(ctx), color: AppColors.textMedium),
              ],
            ),
            Divider(color: AppColors.border),
            const SizedBox(height: 12),
            _infoRow('ID Transaksi', 'TRX-${trx.id.toString().padLeft(4, '0')}'),
            _infoRow('Waktu', trx.tanggalWaktu.substring(0, 16).replaceFirst('T', ' ')),
            _infoRow('Pembayaran', trx.metodePembayaran),
            const SizedBox(height: 16),
            Text('Item Pesanan:', style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: details.length,
                separatorBuilder: (c, i) => Divider(color: AppColors.border, height: 1),
                itemBuilder: (c, i) {
                  final d = details[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${d.qty}x', style: AppFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(d.namaMenu ?? 'Menu', style: AppFonts.poppins(fontSize: 13, color: AppColors.textDark)),
                        ),
                        Text(_fc(d.subtotal), style: AppFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textDark)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text(_fc(trx.totalHarga), style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
          Text(value, style: AppFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
