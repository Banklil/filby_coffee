import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/cart_manager.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _catIndex = 0;
  List<_Product> _products = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  final List<String> _cats = ['ທັງໝົດ', 'ອາຣາບິກາ', 'ເຣນາສຕ້າ', 'ອຸປະກອນ'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    CartManager.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProducts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await AuthService.authHeaders();
      final res = await AuthService.httpGet(
        Uri.parse('${AuthService.baseUrl}/api/shop/products'),
        headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _products = data.map((j) => _Product.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'ດາວໂຫຼດສິນຄ້າລົ້ມເຫລວ'; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server'; });
    }
  }

  List<_Product> get _filtered {
    var list = _catIndex == 0
        ? _products
        : _products.where((p) => p.category == _cats[_catIndex]).toList();
    if (_search.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  int get _cartTotal => CartManager.instance.count;

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
                  Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: FilbyColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FilbyColors.border),
                            ),
                            child: const Icon(Icons.chevron_left, color: FilbyColors.textPrimary),
                          ),
                        ),
                      ],
                      Text(
                        'ສິນຄ້າທັງໝົດ',
                        style: GoogleFonts.notoSerifLao(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: FilbyColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loadProducts,
                        child: const Icon(Icons.refresh, size: 20, color: FilbyColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SearchBar(onChanged: (v) => setState(() => _search = v)),
                ],
              ),
            ),
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
                      border: Border.all(color: _catIndex == i ? FilbyColors.cream : FilbyColors.border),
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _cartTotal > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              backgroundColor: FilbyColors.primary,
              label: Text('ໄປຕະກ້ວາ ($_cartTotal)', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: FilbyColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: FilbyColors.textMuted),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: FilbyColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(backgroundColor: FilbyColors.primary, foregroundColor: Colors.white),
              child: const Text('ລອງໃໝ່'),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return const Center(
        child: Text('ບໍ່ມີສິນຄ້າ', style: TextStyle(color: FilbyColors.textMuted, fontSize: 14)),
      );
    }
    return GridView.builder(
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
        final qty = CartManager.instance.qty(p.id);
        return _ProductCard(
          product: p,
          qty: qty,
          onAdd: () => setState(() => CartManager.instance.add(p.id, p.name, p.emoji, p.price, p.unit)),
          onRemove: qty > 0
              ? () => setState(() => CartManager.instance.remove(p.id))
              : null,
        );
      },
    );
  }
}


class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 18, color: FilbyColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: FilbyColors.textPrimary),
              decoration: const InputDecoration(
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
  final int id;
  final String name;
  final String category;
  final int price;
  final String unit;
  final double stock;
  final String? imageUrl;

  const _Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.stock,
    this.imageUrl,
  });

  factory _Product.fromJson(Map<String, dynamic> j) => _Product(
        id: j['id'],
        name: j['name'],
        category: j['category'] ?? 'ອື່ນໆ',
        price: j['price'],
        unit: j['unit'] ?? 'ກິໂລ',
        stock: (j['stock_qty'] ?? 0).toDouble(),
        imageUrl: j['image_url'],
      );

  String get emoji {
    switch (category.toLowerCase()) {
      case 'ອາຣາບິກາ': return '☕';
      case 'ເຣນາສຕ້າ': return '☕';
      case 'ອຸປະກອນ': return '🛒';
      default: return '📦';
    }
  }
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _ProductCard({required this.product, required this.qty, required this.onAdd, this.onRemove});

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
              child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 42))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product.category, style: const TextStyle(fontSize: 9, color: FilbyColors.textMuted)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmt(product.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.primary)),
                        Text('ກີບ/${product.unit}', style: const TextStyle(fontSize: 9, color: FilbyColors.textMuted)),
                      ],
                    ),
                    qty == 0
                        ? GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: FilbyColors.cream, borderRadius: BorderRadius.circular(8)),
                              child: const Center(child: Icon(Icons.add, size: 16, color: FilbyColors.bg)),
                            ),
                          )
                        : Row(
                            children: [
                              GestureDetector(onTap: onRemove, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: FilbyColors.surface3, borderRadius: BorderRadius.circular(6)), child: const Center(child: Icon(Icons.remove, size: 12, color: FilbyColors.textPrimary)))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('$qty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                              GestureDetector(onTap: onAdd, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: FilbyColors.primary, borderRadius: BorderRadius.circular(6)), child: const Center(child: Icon(Icons.add, size: 12, color: Colors.white)))),
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
