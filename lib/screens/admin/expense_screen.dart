import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/expense_model.dart';
import '../../services/database_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _db = DatabaseHelper();
  String _selectedPeriod = 'today';
  List<ExpenseModel> _expenses = [];
  double _totalExpenses = 0;
  bool _isLoading = true;

  static const _categories = ['Bahan Baku', 'Gas & BBM', 'Listrik & Air', 'Gaji', 'Sewa', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expenses = await _db.getExpensesByPeriod(_selectedPeriod);
    double total = 0;
    for (var e in expenses) {
      total += e.jumlah;
    }
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _totalExpenses = total;
        _isLoading = false;
      });
    }
  }

  String _fc(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  void _showExpenseDialog({ExpenseModel? expense}) {
    final isEdit = expense != null;
    final keteranganCtrl = TextEditingController(text: expense?.keterangan ?? '');
    final jumlahCtrl = TextEditingController(text: expense != null ? expense.jumlah.toInt().toString() : '');
    String selectedCategory = expense?.kategori ?? _categories.first;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran',
                      style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppFonts.poppins(fontSize: 14)))).toList(),
                    onChanged: (v) => setStateSB(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: keteranganCtrl,
                    decoration: InputDecoration(
                      labelText: 'Keterangan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: jumlahCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Jumlah (Rp)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Batal', style: AppFonts.poppins(color: AppColors.textMedium)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final exp = ExpenseModel(
                          id: expense?.id,
                          tanggal: DateTime.now().toIso8601String(),
                          kategori: selectedCategory,
                          keterangan: keteranganCtrl.text.trim(),
                          jumlah: double.parse(jumlahCtrl.text),
                        );
                        if (isEdit) {
                          await _db.updateExpense(exp);
                        } else {
                          await _db.insertExpense(exp);
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      child: Text(isEdit ? 'Simpan' : 'Tambah', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteExpense(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Hapus Pengeluaran?', style: AppFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('"${expense.keterangan}" — ${_fc(expense.jumlah)}', style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: AppFonts.poppins(color: AppColors.textMedium))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _db.deleteExpense(expense.id!);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadData();
            },
            child: Text('Hapus', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
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
        title: Text('Pengeluaran', style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.5)),
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
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.trending_down_outlined, color: AppColors.error, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Pengeluaran', style: AppFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
                            Text(_fc(_totalExpenses), style: AppFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error)),
                          ],
                        ),
                      ),
                      Text('${_expenses.length} item', style: AppFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: _expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_outlined, size: 48, color: AppColors.textLight.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('Belum ada pengeluaran', style: AppFonts.poppins(color: AppColors.textMedium)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _expenses.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final e = _expenses[i];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(_categoryIcon(e.kategori), size: 20, color: AppColors.textMedium),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.keterangan, style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(e.kategori, style: AppFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
                                      ],
                                    ),
                                  ),
                                  Text(_fc(e.jumlah), style: AppFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.error)),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'edit') _showExpenseDialog(expense: e);
                                      if (val == 'delete') _deleteExpense(e);
                                    },
                                    itemBuilder: (c) => [
                                      PopupMenuItem(value: 'edit', child: Text('Edit', style: AppFonts.poppins(fontSize: 13))),
                                      PopupMenuItem(value: 'delete', child: Text('Hapus', style: AppFonts.poppins(fontSize: 13, color: AppColors.error))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_expense',
        onPressed: () => _showExpenseDialog(),
        icon: const Icon(Icons.add),
        label: Text('Tambah', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedPeriod == value;
    return InkWell(
      onTap: () { setState(() => _selectedPeriod = value); _loadData(); },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(label, style: AppFonts.poppins(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? Colors.white : AppColors.textMedium)),
      ),
    );
  }

  IconData _categoryIcon(String kategori) {
    switch (kategori) {
      case 'Bahan Baku': return Icons.shopping_basket_outlined;
      case 'Gas & BBM': return Icons.local_gas_station_outlined;
      case 'Listrik & Air': return Icons.bolt_outlined;
      case 'Gaji': return Icons.people_outline;
      case 'Sewa': return Icons.home_outlined;
      default: return Icons.receipt_outlined;
    }
  }
}
