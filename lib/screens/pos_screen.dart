import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  int _catIndex = 0;
  final Map<String, int> _order = {};

  final List<String> _cats = ['ທັງໝົດ', 'ກາເຟຮ້ອນ', 'ກາເຟເຢັນ', 'ຊາ'];

  final List<_MenuItem> _menu = const [
    _MenuItem(emoji: '☕', name: 'Espresso', price: 15000),
    _MenuItem(emoji: '🥛', name: 'Latte', price: 22000),
    _MenuItem(emoji: '🫖', name: 'Mocha', price: 25000),
    _MenuItem(emoji: '🧊', name: 'Iced Americano', price: 20000),
    _MenuItem(emoji: '🍵', name: 'ຊາຂຽວ', price: 18000),
    _MenuItem(emoji: '🧋', name: 'Bubble Tea', price: 28000),
    _MenuItem(emoji: '☕', name: 'Cappuccino', price: 23000),
    _MenuItem(emoji: '🍫', name: 'Hot Chocolate', price: 22000),
  ];

  int get _totalItems => _order.values.fold(0, (a, b) => a + b);
  int get _totalPrice => _order.entries.fold(0, (s, e) {
        final item = _menu.firstWhere((m) => m.name == e.key);
        return s + item.price * e.value;
      });

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FilbyColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FilbyColors.border),
            ),
            child: const Icon(Icons.chevron_left, color: FilbyColors.textPrimary),
          ),
        ),
        title: const Text('POS ຂາຍໜ້າຮ້ານ'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Stats
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _PosStatCard(
                        label: 'ຍອດຂາຍມື້ນີ້',
                        value: '1,250,000 ກີບ',
                        valueColor: FilbyColors.success,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _PosStatCard(
                        label: 'ຈຳນວນໃບ',
                        value: '47 ໃບ',
                        valueColor: FilbyColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Category tabs
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _catIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _catIndex == i ? FilbyColors.cream : FilbyColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _catIndex == i ? FilbyColors.cream : FilbyColors.border,
                        ),
                      ),
                      child: Text(
                        _cats[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _catIndex == i ? FilbyColors.bg : FilbyColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Menu grid
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, _totalItems > 0 ? 110 : 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _menu.length,
                  itemBuilder: (_, i) {
                    final item = _menu[i];
                    final qty = _order[item.name] ?? 0;
                    return GestureDetector(
                      onTap: () => setState(() => _order[item.name] = qty + 1),
                      child: _MenuTile(item: item, qty: qty),
                    );
                  },
                ),
              ),
            ],
          ),
          // Order bar
          if (_totalItems > 0)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => _showCheckout(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [FilbyColors.primary, FilbyColors.primaryDeep],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: FilbyColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$_totalItems',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ສະຫຼຸບການຂາຍ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        '${_fmt(_totalPrice)} ກີບ',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCheckout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FilbyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CheckoutSheet(
        order: _order,
        menu: _menu,
        total: _totalPrice,
        onConfirm: () {
          setState(() => _order.clear());
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ຮັບເງິນສຳເລັດ!', style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: FilbyColors.success,
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final String emoji;
  final String name;
  final int price;

  const _MenuItem({required this.emoji, required this.name, required this.price});
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final int qty;

  const _MenuTile({required this.item, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qty > 0 ? FilbyColors.primary.withOpacity(0.3) : FilbyColors.border,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 28)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FilbyColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(item.price)} ກີບ',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FilbyColors.primary),
                  ),
                ],
              ),
            ],
          ),
          if (qty > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: FilbyColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: FilbyColors.bg, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$qty',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
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

class _PosStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _PosStatCard({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: FilbyColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

class _CheckoutSheet extends StatelessWidget {
  final Map<String, int> order;
  final List<_MenuItem> menu;
  final int total;
  final VoidCallback onConfirm;

  const _CheckoutSheet({
    required this.order,
    required this.menu,
    required this.total,
    required this.onConfirm,
  });

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final entries = order.entries.toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ສະຫຼຸບຄຳສັ່ງ',
            style: GoogleFonts.notoSerifLao(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FilbyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map((e) {
            final item = menu.firstWhere((m) => m.name == e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.emoji} ${item.name} x${e.value}',
                      style: const TextStyle(fontSize: 13, color: FilbyColors.textPrimary)),
                  Text('${_fmt(item.price * e.value)} ກີບ',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FilbyColors.textPrimary)),
                ],
              ),
            );
          }),
          const Divider(color: FilbyColors.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ລວມ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
              Text('${_fmt(total)} ກີບ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: FilbyColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: FilbyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('ຮັບເງິນ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
