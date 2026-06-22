import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_management_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().loadKasir();
    });
  }

  void _showAddKasirSheet() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tambah Kasir', style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), color: AppColors.textMedium),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input_username'),
                  controller: usernameCtrl,
                  decoration: _inputDecoration('Username', Icons.person_outline),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input_password'),
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: _inputDecoration('Password', Icons.lock_outline),
                  validator: (v) => v == null || v.length < 4 ? 'Minimal 4 karakter' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    key: const Key('btn_simpan_kasir'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final prov = context.read<UserManagementProvider>();
                      final err = await prov.addKasir(username: usernameCtrl.text.trim(), password: passwordCtrl.text);
                      if (!ctx.mounted) return;
                      if (err == null) {
                        Navigator.pop(ctx);
                        _showSnackBar('Kasir berhasil ditambahkan', AppColors.success);
                      } else {
                        _showSnackBar(err, AppColors.error);
                      }
                    },
                    child: Text('Simpan Kasir', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(UserModel kasir) {
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ganti Password', style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), color: AppColors.textMedium),
                  ],
                ),
                Text('Untuk kasir: ${kasir.username}', style: AppFonts.poppins(fontSize: 13, color: AppColors.textLight)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: _inputDecoration('Password Baru', Icons.lock_reset_outlined),
                  validator: (v) => v == null || v.length < 4 ? 'Minimal 4 karakter' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await context.read<UserManagementProvider>().changePassword(kasir.id!, passwordCtrl.text);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _showSnackBar('Password berhasil diubah', AppColors.success);
                    },
                    child: Text('Simpan Password', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(UserModel kasir) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Hapus Akun?', style: AppFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
        content: Text('Apakah Anda yakin ingin menghapus kasir "${kasir.username}"?', style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppFonts.poppins(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await context.read<UserManagementProvider>().deleteKasir(kasir.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Hapus', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppFonts.poppins(fontSize: 13, color: AppColors.textLight),
      prefixIcon: Icon(icon, color: AppColors.textMedium, size: 20),
      filled: true,
      fillColor: AppColors.background,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: AppFonts.poppins()),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manajemen Kasir', style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.5)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('btn_add_kasir'),
        heroTag: 'add_user_hero_tag',
        onPressed: _showAddKasirSheet,
        icon: const Icon(Icons.person_add_outlined),
        label: Text('Tambah Kasir', style: AppFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.primary, width: 1)),
      ),
      body: Consumer<UserManagementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.kasirList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: AppColors.textLight.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Belum ada kasir', style: AppFonts.poppins(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: provider.kasirList.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final kasir = provider.kasirList[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(kasir.username.substring(0, 1).toUpperCase(),
                            style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kasir.username, style: AppFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
                          Text('Kasir', style: AppFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.key_outlined, size: 18),
                          color: AppColors.textMedium,
                          onPressed: () => _showChangePasswordSheet(kasir),
                          tooltip: 'Ganti Password',
                          splashRadius: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          onPressed: () => _confirmDelete(kasir),
                          tooltip: 'Hapus Kasir',
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
