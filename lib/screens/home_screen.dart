import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'pos_screen.dart';
import 'credit_screen.dart';
import 'products_screen.dart';
import 'sales_history_screen.dart';

// ── Filby Coffee palette (from logo): deep navy + gold on light ──────────────
const _navy = Color(0xFF17233F);
const _navyGrad = Color(0xFF2A4272);
const _gold = Color(0xFFC9A24B);
const _goldSoft = Color(0xFFE6C877);
const _lightBg = Color(0xFFF2F4F7);
const _card = Color(0xFFFFFFFF);
const _textDark = Color(0xFF17233F);
const _muted = Color(0xFF8A93A6);
const _green = Color(0xFF14B36A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _summary;
  List _recent = const [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AuthService.fetchSummary('month'),
      AuthService.fetchSales('week'),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as Map<String, dynamic>?;
      final sales = results[1] as Map<String, dynamic>?;
      _recent = (sales?['recent'] as List?) ?? const [];
      _loading = false;
    });
  }

  String _fmt(num n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _time(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  num get _income => (_summary?['income'] as num?) ?? 0;
  num get _count => (_summary?['sales_count'] as num?) ?? 0;
  double get _kg => (_summary?['bean_balance_kg'] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final shopName = AuthService.currentUser?.shopName ?? 'ຮ້ານຂອງຂ້ອຍ';

    return Scaffold(
      backgroundColor: _lightBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _navy,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              _hero(context, shopName),
              const SizedBox(height: 18),
              _sectionTitle('ພາບລວມ'),
              const SizedBox(height: 10),
              _overviewCards(),
              const SizedBox(height: 20),
              _sectionTitle('ທຸ່ມລັດ'),
              const SizedBox(height: 10),
              _quickActions(context),
              const SizedBox(height: 20),
              Row(
                children: [
                  _sectionTitle('ລາຍການຂາຍລ່າສຸດ'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
                    child: Row(
                      children: const [
                        Text('ເບິ່ງທັງໝົດ',
                            style: TextStyle(fontSize: 12, color: _gold, fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right, size: 16, color: _gold),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _recentList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero balance card ─────────────────────────────────────────────────────
  Widget _hero(BuildContext context, String shopName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navyGrad],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _navy.withOpacity(0.30), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.hardEdge,
                child: Image.asset('assets/logo.jpeg', fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ສະບາຍດີ,',
                        style: TextStyle(fontSize: 11, color: Colors.white70)),
                    Text(shopName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSerifLao(
                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.notifications_none_rounded, size: 19, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('ລາຍໄດ້ເດືອນນີ້',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_loading ? '…' : _fmt(_income),
                  style: GoogleFonts.manrope(
                      fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('ກີບ', style: TextStyle(fontSize: 13, color: _goldSoft, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _heroBtn(
                  label: 'ຂາຍ POS',
                  icon: Icons.point_of_sale_rounded,
                  filled: true,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PosScreen()));
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _heroBtn(
                  label: 'ສັ່ງເມັດ',
                  icon: Icons.local_shipping_outlined,
                  filled: false,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProductsScreen()));
                    _load();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBtn({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(colors: [_gold, _goldSoft])
              : null,
          color: filled ? null : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? _navy : Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? _navy : Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Overview stat cards ───────────────────────────────────────────────────
  Widget _overviewCards() {
    final lowStock = _kg <= 1.0;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.receipt_long_rounded,
            iconColor: _gold,
            label: 'ຍອດຂາຍ',
            value: _loading ? '…' : '${_fmt(_count)}',
            sub: 'ລາຍການ',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: lowStock ? Icons.warning_amber_rounded : Icons.coffee_rounded,
            iconColor: lowStock ? const Color(0xFFEF4444) : _navy,
            label: 'ເມັດກາເຟເຫຼືອ',
            value: _loading ? '…' : _kg.toStringAsFixed(2),
            sub: 'ກິໂລ',
            valueColor: lowStock ? const Color(0xFFEF4444) : _textDark,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: GoogleFonts.manrope(
                      fontSize: 20, fontWeight: FontWeight.w800, color: valueColor ?? _textDark)),
              const SizedBox(width: 4),
              Text(sub, style: const TextStyle(fontSize: 10, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    final items = [
      (_qi('POS', Icons.point_of_sale_rounded, () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
        _load();
      })),
      _qi('ສະຫຼຸບ', Icons.bar_chart_rounded, () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SalesHistoryScreen()))),
      _qi('ສິນເຊື່ອ', Icons.credit_card_rounded, () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CreditScreen()))),
      _qi('ລາຍງານ', Icons.description_rounded, null),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _qi(String label, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: _navy),
            const SizedBox(height: 7),
            Text(label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _textDark)),
          ],
        ),
      ),
    );
  }

  // ── Recent transactions ───────────────────────────────────────────────────
  Widget _recentList() {
    if (_loading) {
      return _wrapCard(const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: _navy, strokeWidth: 2)),
      ));
    }
    if (_recent.isEmpty) {
      return _wrapCard(const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(child: Text('ຍັງບໍ່ມີການຂາຍ', style: TextStyle(fontSize: 13, color: _muted))),
      ));
    }
    return _wrapCard(Column(
      children: [
        for (int i = 0; i < _recent.length && i < 8; i++) ...[
          _recentRow(_recent[i] as Map<String, dynamic>),
          if (i < _recent.length - 1 && i < 7)
            const Divider(height: 18, thickness: 1, color: Color(0xFFEEF0F3)),
        ],
      ],
    ));
  }

  Widget _wrapCard(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _recentRow(Map<String, dynamic> s) {
    final items = (s['items'] as List?) ?? const [];
    final label = items
        .whereType<Map>()
        .map((it) => '${it['name']}×${it['qty']}')
        .join(', ');
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: _green.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_downward_rounded, size: 18, color: _green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.isEmpty ? 'ຂາຍໜ້າຮ້ານ' : label,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
              const SizedBox(height: 2),
              Text(_time(s['created_at'] as String?),
                  style: const TextStyle(fontSize: 11, color: _muted)),
            ],
          ),
        ),
        Text('+${_fmt((s['amount'] as num?) ?? 0)}',
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: _green)),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark));
}
