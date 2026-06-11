import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/cart_manager.dart';

class PaymentScreen extends StatefulWidget {
  final int total;
  final List<CartItem> items;

  const PaymentScreen({super.key, required this.total, required this.items});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0; // 0=QR, 1=Cash
  bool _done = false;
  bool _submitting = false;
  bool _profileLoading = true;

  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/shop/me'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final profile = jsonDecode(utf8.decode(res.bodyBytes));
        if (mounted) {
          _phoneCtrl.text   = profile['phone']   ?? '';
          _addressCtrl.text = profile['address'] ?? '';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _profileLoading = false);
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

  Future<void> _confirmPayment() async {
    final phone   = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ກະລຸນາໃສ່ເບີໂທ'),
        backgroundColor: Color(0xFFE74C3C),
      ));
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ກະລຸນາໃສ່ທີ່ຢູ່ຈັດສົ່ງ'),
        backgroundColor: Color(0xFFE74C3C),
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final headers = await AuthService.authHeaders();
      final payMethod = _method == 0 ? 'qr' : 'cash';

      // Save phone/address to profile in background
      http.patch(
        Uri.parse('${AuthService.baseUrl}/api/shop/profile'),
        headers: headers,
        body: jsonEncode({'phone': phone, 'address': address}),
      ).catchError((_) {});

      for (final item in widget.items) {
        final res = await http.post(
          Uri.parse('${AuthService.baseUrl}/api/orders/beans'),
          headers: headers,
          body: jsonEncode({
            'product_id':       item.productId,
            'product_name':     item.name,
            'quantity':         item.qty.toDouble(),
            'unit':             item.unit,
            'unit_price':       item.price.toDouble(),
            'total_price':      (item.price * item.qty).toDouble(),
            'note':             'ວິທີຈ່າຍ: $payMethod',
            'phone':            phone,
            'delivery_address': address,
          }),
        ).timeout(const Duration(seconds: 30));

        if (res.statusCode != 200 && res.statusCode != 201) {
          final body = jsonDecode(utf8.decode(res.bodyBytes));
          throw Exception(body['detail'] ?? 'ເກີດຂໍ້ຜິດພາດ (${res.statusCode})');
        }
      }

      CartManager.instance.clear();
      if (mounted) setState(() { _done = true; _submitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ສ້າງ order ລົ້ມເຫຼວ: $e'),
          backgroundColor: const Color(0xFFE74C3C),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        backgroundColor: FilbyColors.bg,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: FilbyColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, size: 48, color: FilbyColors.success),
                ),
                const SizedBox(height: 20),
                Text('ຊຳລະສຳເລັດ',
                  style: GoogleFonts.notoSerifLao(fontSize: 22, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
                const SizedBox(height: 8),
                Text('${_fmt(widget.total)} ກີບ',
                  style: const TextStyle(fontSize: 16, color: FilbyColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FilbyColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('ກັບໜ້າຫຼັກ', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        title: Text('ຊຳລະເງິນ',
          style: GoogleFonts.notoSerifLao(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _profileLoading
            ? const Center(child: CircularProgressIndicator(color: FilbyColors.primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Total ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [FilbyColors.navy, FilbyColors.navySoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text('ຍອດທີ່ຕ້ອງຊຳລະ',
                          style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('${_fmt(widget.total)} ກີບ',
                          style: GoogleFonts.manrope(
                            fontSize: 32, fontWeight: FontWeight.w800, color: FilbyColors.primary)),
                        const SizedBox(height: 4),
                        Text('${widget.items.length} ລາຍການ',
                          style: const TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Items summary ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FilbyColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FilbyColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ລາຍການສັ່ງ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FilbyColors.textSecondary)),
                        const SizedBox(height: 8),
                        ...widget.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item.name,
                                style: const TextStyle(fontSize: 13, color: FilbyColors.textPrimary))),
                              Text('${item.qty} ${item.unit}',
                                style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.primary)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Delivery info ──────────────────────────────────
                  const Text('ຂໍ້ມູນຈັດສົ່ງ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: FilbyColors.textSecondary)),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _phoneCtrl,
                    label: 'ເບີໂທຕິດຕໍ່ *',
                    hint: '020xxxxxxxx',
                    icon: Icons.phone_outlined,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _addressCtrl,
                    label: 'ທີ່ຢູ່ຈັດສົ່ງ *',
                    hint: 'ບ້ານ, ເມືອງ, ແຂວງ',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // ── Payment method ─────────────────────────────────
                  const Text('ເລືອກວິທີຊຳລະ',
                    style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _MethodBtn(
                        icon: Icons.qr_code, label: 'QR Code',
                        selected: _method == 0,
                        onTap: () => setState(() => _method = 0))),
                      const SizedBox(width: 10),
                      Expanded(child: _MethodBtn(
                        icon: Icons.money, label: 'ເງິນສົດ',
                        selected: _method == 1,
                        onTap: () => setState(() => _method = 1))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_method == 0) _buildQR() else _buildCash(),

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FilbyColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(
                              _method == 0 ? 'ຂ້ອຍສະແກນແລ້ວ — ຢືນຢັນ' : 'ຢືນຢັນຮັບເງິນສົດ',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FilbyColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(color: FilbyColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: FilbyColors.textMuted, fontSize: 12),
          hintText: hint,
          hintStyle: const TextStyle(color: FilbyColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: FilbyColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQR() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Image.asset('assets/logo.jpeg', width: 80, height: 80),
          const SizedBox(height: 12),
          const Text('FILBY COFFEE',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B2B4B))),
          const Text('PREMIUM COFFEE ROASTERS',
            style: TextStyle(fontSize: 10, color: Color(0xFF1B2B4B))),
          const SizedBox(height: 16),
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1B2B4B), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, size: 120, color: Color(0xFF1B2B4B)),
                Text('ກຳລັງລໍຖ້າ QR ຈາກ Filby',
                  style: TextStyle(fontSize: 10, color: Color(0xFF1B2B4B))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('ສະແກນ QR ເພື່ອໂອນເງິນ',
            style: TextStyle(fontSize: 13, color: Color(0xFF1B2B4B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('BCEL One · LDB · Unitel Money',
            style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _buildCash() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.money, size: 56, color: FilbyColors.success),
          const SizedBox(height: 12),
          Text('${_fmt(widget.total)} ກີບ',
            style: GoogleFonts.manrope(
              fontSize: 28, fontWeight: FontWeight.w800, color: FilbyColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('ກະລຸນາຈ່າຍເງິນສົດໃຫ້ພະນັກງານ',
            style: TextStyle(fontSize: 13, color: FilbyColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('ແລ້ວກົດ "ຢືນຢັນຮັບເງິນສົດ" ດ້ານລຸ່ມ',
            style: TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
        ],
      ),
    );
  }
}

class _MethodBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodBtn({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? FilbyColors.primary : FilbyColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? FilbyColors.primary : FilbyColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: selected ? Colors.white : FilbyColors.textMuted),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : FilbyColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
