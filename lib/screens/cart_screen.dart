import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/cart_manager.dart';
import 'payment_screen.dart';


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartManager get cart => CartManager.instance;

  @override
  void initState() {
    super.initState();
    CartManager.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  int get subtotal => cart.subtotal;
  int get shipping => cart.count == 0 ? 0 : 25000;
  int get total => subtotal + shipping;

  @override
  Widget build(BuildContext context) {
    final items = cart.items;

    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ຕະກ້ວາຂອງຂ້ອຍ',
                    style: GoogleFonts.notoSerifLao(fontSize: 22, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FilbyColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: FilbyColors.border),
                    ),
                    child: Text('${items.length} ລາຍການ', style: const TextStyle(fontSize: 11, color: FilbyColors.textSecondary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 56, color: FilbyColors.textMuted),
                          SizedBox(height: 12),
                          Text('ຕະກ້ວາຫວ່າງ', style: TextStyle(fontSize: 14, color: FilbyColors.textMuted)),
                          SizedBox(height: 4),
                          Text('ເພີ່ມສິນຄ້າຈາກໜ້າສິນຄ້າ', style: TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 8),
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CartItemCard(
                                item: item,
                                onIncrease: () => setState(() => cart.add(item.productId, item.name, item.emoji, item.price, item.unit)),
                                onDecrease: () => setState(() => cart.remove(item.productId)),
                              ),
                            )),
                        _SummaryCard(subtotal: subtotal, shipping: shipping, total: total),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PaymentScreen(total: total, items: items),
                            )),
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: const Text('ຊຳລະ (QR / ເງິນສົດ)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FilbyColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _CartItemCard({required this.item, required this.onIncrease, required this.onDecrease});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: FilbyColors.surface2, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('${_fmt(item.price)} ກີບ/${item.unit}', style: const TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(item.price * item.qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _QtyBtn(icon: Icons.remove, onTap: onDecrease),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.qty}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                  _QtyBtn(icon: Icons.add, onTap: onIncrease, isPrimary: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _QtyBtn({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: isPrimary ? FilbyColors.primary : FilbyColors.surface3,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: isPrimary ? Colors.white : FilbyColors.textPrimary),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int subtotal;
  final int shipping;
  final int total;
  const _SummaryCard({required this.subtotal, required this.shipping, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        children: [
          _Row(label: 'ລວມສິນຄ້າ', value: subtotal),
          _Row(label: 'ຄ່າຂົນສົ່ງ', value: shipping),
          const Divider(color: FilbyColors.border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ລວມທັງໝົດ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: _fmt(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: FilbyColors.textPrimary)),
                  const TextSpan(text: ' ກີບ', style: TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Row extends StatelessWidget {
  final String label;
  final int value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
          Text('${buf.toString()} ກີບ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
