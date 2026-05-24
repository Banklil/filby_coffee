import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _catIndex = 0;
  final Map<String, int> _cart = {};

  final List<String> _cats = ['ທັງໝົດ', 'ອາຣາບິກາ', 'ເຣນາສຕ້າ', 'ອຸປະກອນ'];

  final List<_Product> _products = const [
    _Product(emoji: '☕', name: 'ກໍ່ລະແວກ ອາຣາບິກາ', cat: 'ອາຣາບິກາ', price: 95000, unit: 'ກິໂລ'),
    _Product(emoji: '☕', name: 'ກາເຟ ເຣນາສຕ້າ', cat: 'ເຣນາສຕ້າ', price: 65000, unit: 'ກິໂລ'),
    _Product(emoji: '🫘', name: 'ກໍ່ລະແວກ ຊາດຄ', cat: 'ອາຣາບິກາ', price: 120000, unit: 'ກິໂລ'),
    _Product(emoji: '🥛', name: 'ນົມຂາ້ວ UHT', cat: 'ອຸປະກອນ', price: 18000, unit: 'ລິດ'),
    _Product(emoji: '🍫', name: 'ຊັອກໂກແລດຝຸ່ນ', cat: 'ອຸປະກອນ', price: 45000, unit: 'ກິໂລ'),
    _Product(emoji: '🧁', name: 'ນ້ຳຕານທໍລານີ', cat: 'ອຸປະກອນ', price: 12000, unit: 'ກິໂລ'),
  ];

  List<_Product> get _filtered {
    if (_catIndex == 0) return _products;
    return _products.where((p) => p.cat == _cats[_catIndex]).toList();
  }

  int get _cartTotal => _cart.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ສິນຄ້າທັງໝົດ',
                    style: GoogleFonts.notoSerifLao(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: FilbyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SearchBar(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _catIndex == i ? FilbyColors.bg : FilbyColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final p = _filtered[i];
                  final qty = _cart[p.name] ?? 0;
                  return _ProductCard(
                    product: p,
                    qty: qty,
                    onAdd: () => setState(() => _cart[p.name] = (qty) + 1),
                    onRemove: qty > 0
                        ? () => setState(() {
                              if (qty == 1) {
                                _cart.remove(p.name);
                              } else {
                                _cart[p.name] = qty - 1;
                              }
                            })
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _cartTotal > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              backgroundColor: FilbyColors.primary,
              label: Text(
                'ໄປຕະກ້ວາ ($_cartTotal)',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            )
          : null,
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FilbyColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: FilbyColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 13, color: FilbyColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາສິນຄ້າ...',
                hintStyle: TextStyle(fontSize: 13, color: FilbyColors.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Product {
  final String emoji;
  final String name;
  final String cat;
  final int price;
  final String unit;

  const _Product({
    required this.emoji,
    required this.name,
    required this.cat,
    required this.price,
    required this.unit,
  });
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _ProductCard({
    required this.product,
    required this.qty,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [FilbyColors.surface2, FilbyColors.surface3],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Center(
                child: Text(product.emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(product.cat, style: const TextStyle(fontSize: 9, color: FilbyColors.textMuted)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatNum(product.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FilbyColors.primary,
                          ),
                        ),
                        Text(
                          'ກີບ/${product.unit}',
                          style: const TextStyle(fontSize: 9, color: FilbyColors.textMuted),
                        ),
                      ],
                    ),
                    qty == 0
                        ? GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: FilbyColors.cream,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.add, size: 16, color: FilbyColors.bg),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              GestureDetector(
                                onTap: onRemove,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: FilbyColors.surface3,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.remove, size: 12, color: FilbyColors.textPrimary),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              GestureDetector(
                                onTap: onAdd,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: FilbyColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
