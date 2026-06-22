import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _showProductDialog({ProductModel? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.namaMenu ?? '');
    final priceCtrl = TextEditingController(
        text: product != null ? product.harga.toInt().toString() : '');
    final categoryCtrl =
        TextEditingController(text: product?.kategori ?? 'Nasi Goreng');
    final formKey = GlobalKey<FormState>();
    
    String? currentImagePath = product?.imagePath;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEdit ? 'Edit Menu' : 'Tambah Menu Baru',
                          style: AppFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 20),
                      
                      // Area Pilih Gambar
                      Center(
                        child: InkWell(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setDialogState(() {
                                currentImagePath = pickedFile.path;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                              image: currentImagePath != null && File(currentImagePath!).existsSync()
                                  ? DecorationImage(
                                      image: FileImage(File(currentImagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: currentImagePath == null || !File(currentImagePath!).existsSync()
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.textMedium),
                                      const SizedBox(height: 4),
                                      Text('Foto', style: AppFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (currentImagePath != null)
                        Center(
                          child: TextButton(
                            onPressed: () => setDialogState(() => currentImagePath = null),
                            child: Text('Hapus Foto', style: AppFonts.poppins(color: AppColors.error, fontSize: 11)),
                          ),
                        ),
                      const SizedBox(height: 16),

                      TextFormField(
                        key: const Key('input_nama_menu'),
                        controller: nameCtrl,
                        decoration: _dialogInputDecoration(label: 'Nama Menu'),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('input_harga_menu'),
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _dialogInputDecoration(label: 'Harga (Rp)'),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: const Key('input_kategori_menu'),
                        initialValue: categoryCtrl.text,
                        decoration: _dialogInputDecoration(label: 'Kategori'),
                        dropdownColor: AppColors.surface,
                        items: const [
                          DropdownMenuItem(
                              value: 'Nasi Goreng', child: Text('Nasi Goreng')),
                          DropdownMenuItem(value: 'Mie', child: Text('Mie')),
                          DropdownMenuItem(value: 'Minuman', child: Text('Minuman')),
                          DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                        ],
                        onChanged: (val) {
                          if (val != null) categoryCtrl.text = val;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Batal',
                                style: AppFonts.poppins(color: AppColors.textMedium)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            key: const Key('btn_simpan_menu'),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              
                              String? savedImagePath = currentImagePath;
                              // Jika image baru dipilih (ada di temporary dir), copy ke app docs
                              if (currentImagePath != null && currentImagePath != product?.imagePath) {
                                try {
                                  final appDir = await getApplicationDocumentsDirectory();
                                  final fileName = p.basename(currentImagePath!);
                                  // Tambah timestamp agar unik
                                  final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
                                  final savedImage = await File(currentImagePath!).copy(p.join(appDir.path, uniqueName));
                                  savedImagePath = savedImage.path;
                                } catch (e) {
                                  debugPrint('Gagal menyimpan gambar: $e');
                                }
                              }

                              final pModel = ProductModel(
                                id: product?.id,
                                namaMenu: nameCtrl.text.trim(),
                                harga: double.parse(priceCtrl.text),
                                kategori: categoryCtrl.text,
                                isActive: product?.isActive ?? true,
                                imagePath: savedImagePath,
                              );

                              final prov = ctx.read<ProductProvider>();
                              if (isEdit) {
                                await prov.updateProduct(pModel);
                              } else {
                                await prov.addProduct(pModel);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Text('Simpan',
                                style: AppFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Hapus Menu?',
            style: AppFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark)),
        content: Text(
            'Apakah Anda yakin ingin menghapus "${product.namaMenu}"? Data tidak dapat dikembalikan.',
            style: AppFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: AppFonts.poppins(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await context.read<ProductProvider>().deleteProduct(product.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Hapus',
                style: AppFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Menu',
            style: AppFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.5)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('btn_add_product'),
        heroTag: 'add_product_hero_tag',
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: Text('Menu Baru',
            style: AppFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.primary, width: 1)),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 48, color: AppColors.textLight.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada menu',
                    style: AppFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Klik tombol di bawah untuk menambah menu',
                    style: AppFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: provider.products.length,
            separatorBuilder: (ctx, gap) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final product = provider.products[index];
              return _ProductCard(
                product: product,
                onEdit: () => _showProductDialog(product: product),
                onDelete: () => _confirmDelete(product),
                onToggle: () => provider.toggleActive(product),
              );
            },
          );
        },
      ),
    );
  }

  InputDecoration _dialogInputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppFonts.poppins(fontSize: 13, color: AppColors.textLight),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final inactive = !product.isActive;
    return Opacity(
      opacity: inactive ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: inactive ? AppColors.background : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.namaMenu,
                        style: AppFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (inactive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('NONAKTIF',
                              style: AppFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        product.kategori,
                        style: AppFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        _formatCurrency(product.harga),
                        style: AppFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  key: Key('toggle_${product.id}'),
                  value: product.isActive,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.surface,
                  inactiveTrackColor: AppColors.border,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.textMedium,
                  onPressed: onEdit,
                  splashRadius: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  onPressed: onDelete,
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
