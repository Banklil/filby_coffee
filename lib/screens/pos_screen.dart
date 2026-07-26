import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

// ── Data model ─────────────────────────────────────────────────────────────

class PosMenuItem {
  final String id;
  String emoji;
  String name;
  int price;
  String category;
  String? imageBase64;

  PosMenuItem({
    String? id,
    required this.emoji,
    required this.name,
    required this.price,
    this.category = 'ກາເຟ',
    this.imageBase64,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Uint8List? get imageBytes =>
      imageBase64 != null ? base64Decode(imageBase64!) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'name': name,
        'price': price,
        'category': category,
        'imageBase64': imageBase64,
      };

  factory PosMenuItem.fromJson(Map<String, dynamic> j) => PosMenuItem(
        id: j['id'] as String?,
        emoji: j['emoji'] as String? ?? '☕',
        name: j['name'] as String? ?? '',
        price: (j['price'] as num?)?.toInt() ?? 0,
        category: j['category'] as String? ?? 'ກາເຟ',
        imageBase64: j['imageBase64'] as String?,
      );
}

// ── Screen ──────────────────────────────────────────────────────────────────

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String _catFilter = 'ທັງໝົດ';
  final Map<String, int> _order = {};
  List<PosMenuItem> _menu = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pos_menu_v2');
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => PosMenuItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _menu = list; _loaded = true; });
    } else {
      setState(() { _menu = []; _loaded = true; });
    }
  }

  Future<void> _saveMenu() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'pos_menu_v2', jsonEncode(_menu.map((e) => e.toJson()).toList()));
  }

  List<String> get _cats {
    final cats = <String>['ທັງໝົດ'];
    final seen = <String>{};
    for (final item in _menu) {
      if (item.category.isNotEmpty && seen.add(item.category)) cats.add(item.category);
    }
    return cats;
  }

  List<PosMenuItem> get _filtered =>
      _catFilter == 'ທັງໝົດ' ? _menu : _menu.where((m) => m.category == _catFilter).toList();

  int get _totalItems => _order.values.fold(0, (a, b) => a + b);
  int get _totalPrice => _order.entries.fold(0, (s, e) {
        try {
          return s + _menu.firstWhere((m) => m.id == e.key).price * e.value;
        } catch (_) { return s; }
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

  // ── Add/Edit dialog ───────────────────────────────────────────────────────

  void _showAddEdit(BuildContext context, {PosMenuItem? editing}) {
    final emojiCtrl = TextEditingController(text: editing?.emoji ?? '☕');
    final nameCtrl  = TextEditingController(text: editing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: editing != null ? editing.price.toString() : '');
    final catCtrl   = TextEditingController(text: editing?.category ?? 'ກາເຟ');
    final formKey   = GlobalKey<FormState>();
    Uint8List? pickedBytes = editing?.imageBytes;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: FilbyColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Text(
            editing == null ? 'ເພີ່ມເມນູໃໝ່' : 'ແກ້ໄຂເມນູ',
            style: GoogleFonts.notoSerifLao(
                fontSize: 17, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Image picker ───────────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 65,
                        maxWidth: 400,
                        maxHeight: 400,
                      );
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setDialog(() => pickedBytes = bytes);
                      }
                    },
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FilbyColors.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: pickedBytes != null
                              ? FilbyColors.primary
                              : FilbyColors.border,
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: pickedBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(pickedBytes!, fit: BoxFit.cover),
                                Positioned(
                                  top: 6, right: 6,
                                  child: GestureDetector(
                                    onTap: () => setDialog(() => pickedBytes = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 32, color: FilbyColors.textMuted),
                                SizedBox(height: 6),
                                Text('ເລືອກຮູບ (ຈາກ Gallery)',
                                    style: TextStyle(fontSize: 11, color: FilbyColors.textMuted)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Emoji + Name ───────────────────────────────────────
                  Row(
                    children: [
                      SizedBox(width: 64, child: _Field(ctrl: emojiCtrl, label: 'Emoji', hint: '☕')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          ctrl: nameCtrl,
                          label: 'ຊື່ *',
                          hint: 'Espresso',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'ໃສ່ຊື່' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    ctrl: priceCtrl,
                    label: 'ລາຄາ (ກີບ) *',
                    hint: '15000',
                    type: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.replaceAll(',', '').trim() ?? '');
                      return (n == null || n <= 0) ? 'ໃສ່ລາຄາ' : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _Field(ctrl: catCtrl, label: 'ໝວດ', hint: 'ກາເຟ'),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: FilbyColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FilbyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final name  = nameCtrl.text.trim();
                final price = int.parse(priceCtrl.text.replaceAll(',', '').trim());
                final emoji = emojiCtrl.text.trim().isEmpty ? '☕' : emojiCtrl.text.trim();
                final cat   = catCtrl.text.trim().isEmpty ? 'ກາເຟ' : catCtrl.text.trim();
                final imgB64 = pickedBytes != null ? base64Encode(pickedBytes!) : null;

                setState(() {
                  if (editing == null) {
                    _menu.add(PosMenuItem(
                        emoji: emoji, name: name, price: price,
                        category: cat, imageBase64: imgB64));
                  } else {
                    editing.emoji       = emoji;
                    editing.name        = name;
                    editing.price       = price;
                    editing.category    = cat;
                    editing.imageBase64 = imgB64 ?? editing.imageBase64;
                  }
                });
                _saveMenu();
                Navigator.pop(ctx);
              },
              child: Text(editing == null ? 'ເພີ່ມ' : 'ບັນທຶກ',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, PosMenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FilbyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ລົບເມນູ?',
            style: TextStyle(color: FilbyColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('ລົບ "${item.name}" ອອກຈາກລາຍການ?',
            style: const TextStyle(color: FilbyColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: FilbyColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _order.remove(item.id);
                _menu.remove(item);
              });
              _saveMenu();
              Navigator.pop(ctx);
            },
            child: const Text('ລົບ', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        elevation: 0,
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
        title: Text('POS ຂາຍໜ້າຮ້ານ',
            style: GoogleFonts.notoSerifLao(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          GestureDetector(
            onTap: () => _showAddEdit(context),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: FilbyColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('ເພີ່ມ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: FilbyColors.primary))
          : Stack(
              children: [
                Column(
                  children: [
                    // ── Category tabs ──────────────────────────────────────
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = _cats[i];
                          final sel = _catFilter == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _catFilter = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? FilbyColors.primary : FilbyColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel ? FilbyColors.primary : FilbyColors.border),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : FilbyColors.textSecondary,
                                  )),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Grid ──────────────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.restaurant_menu_outlined,
                                      size: 60, color: FilbyColors.textMuted),
                                  const SizedBox(height: 12),
                                  const Text('ຍັງບໍ່ມີເມນູ',
                                      style: TextStyle(fontSize: 14, color: FilbyColors.textMuted)),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddEdit(context),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('ເພີ່ມເມນູທຳອິດ',
                                        style: TextStyle(fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FilbyColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                  16, 0, 16, _totalItems > 0 ? 110 : 20),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                final qty  = _order[item.id] ?? 0;
                                return _MenuTile(
                                  item: item,
                                  qty: qty,
                                  onTap: () => setState(() => _order[item.id] = qty + 1),
                                  onEdit: () => _showAddEdit(context, editing: item),
                                  onDelete: () => _confirmDelete(context, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // ── Order bar ──────────────────────────────────────────────
                if (_totalItems > 0)
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: GestureDetector(
                      onTap: () => _showCheckout(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [FilbyColors.primary, FilbyColors.primaryDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: FilbyColors.primary.withOpacity(0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('$_totalItems',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('ສະຫຼຸບການຂາຍ',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const Spacer(),
                            Text('${_fmt(_totalPrice)} ກີບ',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CheckoutSheet(
        order: Map.from(_order),
        menu: _menu,
        fmt: _fmt,
        onConfirm: () {
          setState(() => _order.clear());
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ຮັບເງິນສຳເລັດ! ✓',
                style: TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: FilbyColors.success,
          ));
        },
        onQtyChange: (id, qty) => setState(() {
          if (qty <= 0) _order.remove(id);
          else _order[id] = qty;
        }),
      ),
    );
  }
}

// ── Menu tile ─────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final PosMenuItem item;
  final int qty;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuTile({
    required this.item,
    required this.qty,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
    final bytes = item.imageBytes;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: qty > 0 ? FilbyColors.warningBg : FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: qty > 0 ? FilbyColors.primary : FilbyColors.border,
            width: qty > 0 ? 1.5 : 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ── Main tap area ─────────────────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image or emoji
                    Expanded(
                      child: Center(
                        child: bytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(bytes,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity),
                              )
                            : Text(item.emoji,
                                style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: FilbyColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${_fmt(item.price)} ກີບ',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FilbyColors.primary)),
                  ],
                ),
              ),
            ),
          ),

          // ── Qty badge (top-left) ──────────────────────────────────────
          if (qty > 0)
            Positioned(
              top: 5, left: 5,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: FilbyColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: FilbyColors.bg, width: 1.5)),
                child: Center(
                  child: Text('$qty',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),

          // ── Action buttons (top-right) ────────────────────────────────
          Positioned(
            top: 3, right: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TileAction(
                  icon: Icons.edit_outlined,
                  color: FilbyColors.primary,
                  onTap: onEdit,
                ),
                const SizedBox(width: 2),
                _TileAction(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFFF4444),
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TileAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType type;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.type = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      style: const TextStyle(color: FilbyColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: FilbyColors.textMuted, fontSize: 11),
        hintText: hint,
        hintStyle: const TextStyle(color: FilbyColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: FilbyColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FilbyColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FilbyColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FilbyColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF4444))),
      ),
    );
  }
}

// ── Checkout sheet ────────────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  final Map<String, int> order;
  final List<PosMenuItem> menu;
  final String Function(int) fmt;
  final VoidCallback onConfirm;
  final void Function(String id, int qty) onQtyChange;

  const _CheckoutSheet({
    required this.order,
    required this.menu,
    required this.fmt,
    required this.onConfirm,
    required this.onQtyChange,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late Map<String, int> _order;

  @override
  void initState() {
    super.initState();
    _order = Map.from(widget.order);
  }

  int get _total => _order.entries.fold(0, (s, e) {
        try {
          return s + widget.menu.firstWhere((m) => m.id == e.key).price * e.value;
        } catch (_) { return s; }
      });

  @override
  Widget build(BuildContext context) {
    final entries = _order.entries
        .where((e) => widget.menu.any((m) => m.id == e.key))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 14),
            decoration: BoxDecoration(
                color: FilbyColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('ສະຫຼຸບຄຳສັ່ງ',
                style: GoogleFonts.notoSerifLao(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FilbyColors.textPrimary)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: entries.map((e) {
                final item = widget.menu.firstWhere((m) => m.id == e.key);
                final qty  = e.value;
                final bytes = item.imageBytes;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: FilbyColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: bytes != null
                            ? Image.memory(bytes, width: 40, height: 40, fit: BoxFit.cover)
                            : Container(
                                width: 40, height: 40,
                                alignment: Alignment.center,
                                color: FilbyColors.surface3,
                                child: Text(item.emoji,
                                    style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: FilbyColors.textPrimary)),
                            Text('${widget.fmt(item.price)} ກີບ',
                                style: const TextStyle(
                                    fontSize: 11, color: FilbyColors.textMuted)),
                          ],
                        ),
                      ),
                      // Qty
                      Row(
                        children: [
                          _QtyBtn(
                            icon: qty == 1 ? Icons.delete_outline : Icons.remove,
                            color: qty == 1
                                ? const Color(0xFFFF4444)
                                : FilbyColors.textMuted,
                            onTap: () {
                              setState(() {
                                if (qty <= 1) _order.remove(e.key);
                                else _order[e.key] = qty - 1;
                              });
                              widget.onQtyChange(e.key, qty - 1);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('$qty',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: FilbyColors.textPrimary)),
                          ),
                          _QtyBtn(
                            icon: Icons.add,
                            color: FilbyColors.primary,
                            onTap: () {
                              setState(() => _order[e.key] = qty + 1);
                              widget.onQtyChange(e.key, qty + 1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text('${widget.fmt(item.price * qty)} ກີບ',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: FilbyColors.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Total + confirm
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: FilbyColors.surface,
              border: Border(top: BorderSide(color: FilbyColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ລວມທັງໝົດ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FilbyColors.textSecondary)),
                    Text('${widget.fmt(_total)} ກີບ',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: FilbyColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _order.isEmpty ? null : widget.onConfirm,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('ຮັບເງິນ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FilbyColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
