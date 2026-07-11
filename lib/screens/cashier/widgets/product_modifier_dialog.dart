import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_fonts.dart';

void showModifierDialog(BuildContext context, ProductModel product) {
  final cart = context.read<CartProvider>();
  final extraProducts = context.read<ProductProvider>().extraProducts;

  String pedasLevel = 'Sedang';
  Map<ProductModel, int> selectedExtras = {};

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateSB) {
        return SafeArea(
          bottom: true,
          child: Container(
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
                      icon: const Icon(Icons.close),
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
                      children: [
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
                    cart.updateNote(product, finalCatatan);

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
        ),
      );
    },
  ),
  );
}
