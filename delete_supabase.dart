import 'package:supabase/supabase.dart';

void main() async {
  print('Menghubungkan ke Supabase...');
  final supabase = SupabaseClient(
    'https://jrruipuhczfzbmldxpil.supabase.co',
    'sb_publishable__WM2TyNszoAW2-fr2d_PVw_ZcXUYf3V',
  );

  try {
    print('Menghapus data transaction_details...');
    await supabase.from('transaction_details').delete().neq('id', 0);
    
    print('Menghapus data transactions...');
    await supabase.from('transactions').delete().neq('id', 0);

    print('Berhasil! Semua transaksi telah dihapus dari Supabase.');
  } catch (e) {
    print('Terjadi kesalahan: $e');
  }
}
