import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/database_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';

class PendingOrdersTab extends StatefulWidget {
  final VoidCallback onEdit;
  final Function(TransactionModel, List<TransactionDetailModel>) onPay;

  const PendingOrdersTab({
    super.key,
    required this.onEdit,
    required this.onPay,
  });

  @override
  State<PendingOrdersTab> createState() => _PendingOrdersTabState();
}

class _PendingOrdersTabState extends State<PendingOrdersTab> {
  final _db = DatabaseHelper();
  List<TransactionModel> _orders = [];
  // Cache detail per transaksi
  final Map<int, List<TransactionDetailModel>> _detailsCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant PendingOrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh saat tab ditampilkan kembali
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final trxs = await _db.getActiveOrders();
    _detailsCache.clear();
    for (final trx in trxs) {
      _detailsCache[trx.id!] = await _db.getTransactionDetails(trx.id!);
    }
    if (mounted) {
      setState(() {
        _orders = trxs;
        _isLoading = false;
      });
    }
  }

  void _editOrder(TransactionModel trx) {
    final details = _detailsCache[trx.id!] ?? [];
    context.read<CartProvider>().loadTransaction(
      trx,
      details,
      context.read<ProductProvider>().products,
    );
    widget.onEdit();
  }

  void _payOrder(TransactionModel trx) {
    final details = _detailsCache[trx.id!] ?? [];
    widget.onPay(trx, details);
  }

  void _completeOrder(TransactionModel trx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Selesaikan Pesanan?',
          style: AppFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Pesanan untuk "${trx.namaPelanggan ?? ''}" akan ditandai selesai (sudah diambil).',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await _db.completeTransaction(trx.id!);
              nav.pop();
              if (mounted) _loadOrders();
            },
            child: Text(
              'Selesaikan',
              style: AppFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteOrder(TransactionModel trx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Batalkan Pesanan?',
          style: AppFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Hapus pesanan untuk "${trx.namaPelanggan ?? 'Tanpa Nama'}"?',
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
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await _db.deleteTransaction(trx.id!);
              nav.pop();
              if (mounted) _loadOrders();
            },
            child: Text(
              'Hapus',
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pesanan aktif',
              style: AppFonts.poppins(
                fontSize: 16,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pesanan yang sudah dibayar akan muncul di sini',
              style: AppFonts.poppins(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Daftar Pesanan',
                style: AppFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_orders.length} aktif',
                  style: AppFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh_outlined),
                onPressed: _loadOrders,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _orders.length,
              separatorBuilder: (c, idx) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) => _buildOrderCard(_orders[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(TransactionModel trx) {
    final details = _detailsCache[trx.id!] ?? [];
    final isPending = trx.status == 'pending';
    final time = trx.tanggalWaktu.contains('T')
        ? trx.tanggalWaktu.split('T').last.substring(0, 5)
        : trx.tanggalWaktu;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isPending ? AppColors.warning : AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPending
                        ? Icons.hourglass_empty_outlined
                        : Icons.restaurant_outlined,
                    color: isPending ? AppColors.warning : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (trx.namaPelanggan == 'Pelanggan' || trx.namaPelanggan == 'Pelanggan Umum' || trx.namaPelanggan?.isEmpty == true)
                            ? 'Pelanggan'
                            : trx.namaPelanggan!,
                        style: AppFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jam $time',
                        style: AppFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isPending ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isPending ? AppColors.warning : AppColors.success)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isPending ? 'Belum Bayar' : 'Diproses',
                    style: AppFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPending ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail menu yang dipesan
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Pesanan:',
                  style: AppFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                ...details.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.circle,
                            size: 5,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.namaMenu ?? 'Produk #${d.idProduk}',
                                style: AppFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (d.catatan?.isNotEmpty == true)
                                Text(
                                  'Catatan: ${d.catatan}',
                                  style: AppFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'x${d.qty}',
                          style: AppFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rp ${d.subtotal.toInt()}',
                          style: AppFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: AppColors.border, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp ${trx.totalHarga.toInt()}',
                      style: AppFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _actionBtn(
                  Icons.edit_outlined,
                  'Edit',
                  AppColors.textDark,
                  () => _editOrder(trx),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  Icons.delete_outline,
                  'Hapus',
                  AppColors.error,
                  () => _deleteOrder(trx),
                ),
                const Spacer(),
                if (isPending)
                  ElevatedButton.icon(
                    icon: Icon(Icons.payment_outlined, size: 16),
                    label: Text(
                      'Bayar',
                      style: AppFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _payOrder(trx),
                  )
                else
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      'Selesaikan',
                      style: AppFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _completeOrder(trx),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppFonts.poppins(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
