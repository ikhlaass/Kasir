import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_fonts.dart';

class CartSectionWidget extends StatelessWidget {
  final Function(CartProvider) onSaveOrder;
  final Function(BuildContext, CartProvider) onPay;

  const CartSectionWidget({
    super.key,
    required this.onSaveOrder,
    required this.onPay,
  });

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

  void _confirmClearCart(BuildContext context, CartProvider cart) {
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
              style: AppFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.error,
                        onPressed: () => _confirmClearCart(context, cart),
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
                              onPressed: () => onSaveOrder(cart),
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
                                if (MediaQuery.of(context).size.width < 950) {
                                  Navigator.pop(context);
                                }
                                onPay(context, cart);
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
}
