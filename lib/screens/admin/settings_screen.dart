import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/setting_model.dart';
import '../../services/database_helper.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../providers/user_management_provider.dart';
import '../../providers/product_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String adminUsername;
  const SettingsScreen({super.key, required this.adminUsername});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl      = TextEditingController();
  final _alamatCtrl    = TextEditingController();
  final _teleponCtrl   = TextEditingController();
  final _deskripsiCtrl = TextEditingController();

  bool _isLoading  = true;
  bool _isSaving   = false;


  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() {
    _namaCtrl.dispose(); _alamatCtrl.dispose();
    _teleponCtrl.dispose(); _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final settings  = await _db.getAllSettings();
    if (mounted) {
      setState(() {
        _namaCtrl.text      = settings[SettingKeys.namaToko]      ?? '';
        _alamatCtrl.text    = settings[SettingKeys.alamatToko]    ?? '';
        _teleponCtrl.text   = settings[SettingKeys.teleponToko]   ?? '';
        _deskripsiCtrl.text = settings[SettingKeys.deskripsiToko] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await _db.saveAllSettings({
      SettingKeys.namaToko:      _namaCtrl.text.trim(),
      SettingKeys.alamatToko:    _alamatCtrl.text.trim(),
      SettingKeys.teleponToko:   _teleponCtrl.text.trim(),
      SettingKeys.deskripsiToko: _deskripsiCtrl.text.trim(),
    });
    SupabaseService().pushSettings();
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pengaturan disimpan', style: AppFonts.poppins()),
        backgroundColor: AppColors.success,
      ));
    }
  }

  bool _isSyncing = false;

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    await SupabaseService().syncData();
    await _loadData();
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sinkronisasi selesai!'), backgroundColor: AppColors.success),
      );
      // Refresh providers
      try {
        context.read<UserManagementProvider>().loadKasir();
        context.read<ProductProvider>().loadProducts();
      } catch (_) {}
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Keluar?', style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text('Apakah Anda yakin ingin logout?', style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppFonts.poppins(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false),
            child: Text('Logout', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) { Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Pengaturan', style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.5)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.border, height: 1),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                // ── Profile Section ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            widget.adminUsername.substring(0, 1).toUpperCase(),
                            style: AppFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.adminUsername, style: AppFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Owner', style: AppFonts.poppins(fontSize: 10, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section label ─────────────────────────────────
                Text('Informasi Usaha', style: AppFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 12),

                // ── Form Card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _formField(key: const Key('s_nama'), controller: _namaCtrl,
                            label: 'Nama Usaha',
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null),
                        const SizedBox(height: 16),
                        _formField(key: const Key('s_desc'), controller: _deskripsiCtrl,
                            label: 'Tagline / Deskripsi'),
                        const SizedBox(height: 16),
                        _formField(key: const Key('s_addr'), controller: _alamatCtrl,
                            label: 'Alamat', maxLines: 2),
                        const SizedBox(height: 16),
                        _formField(key: const Key('s_phone'), controller: _teleponCtrl,
                            label: 'Nomor Telepon',
                            type: TextInputType.phone),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity, height: 44,
                          child: ElevatedButton(
                            key: const Key('save_settings'),
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Simpan Perubahan', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Sync Data ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sinkronisasi Cloud', style: AppFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Text('Kirim data transaksi lokal ke Supabase dan ambil pembaruan data menu dari perangkat lain.', style: AppFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _syncData,
                          icon: _isSyncing ? const SizedBox.shrink() : Icon(Icons.cloud_sync, size: 20),
                          label: _isSyncing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Sinkronisasi Sekarang', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Logout ────────────────────────────────────────
                InkWell(
                  key: const Key('logout_tile'),
                  onTap: () => _showLogoutDialog(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout_outlined, color: AppColors.error, size: 20),
                        const SizedBox(width: 16),
                        Expanded(child: Text('Keluar (Logout)', style: AppFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error))),
                        Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
      ),
    );
  }

  Widget _formField({
    required Key key,
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMedium)),
        const SizedBox(height: 6),
        TextFormField(
          key: key,
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          style: AppFonts.poppins(fontSize: 14, color: AppColors.textDark),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
