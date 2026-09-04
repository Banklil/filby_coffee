import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/staff_service.dart';

const _navy = Color(0xFF17233F);
const _gold = Color(0xFFC9A24B);
const _ok = Color(0xFF14B36A);
const _tnum = [FontFeature.tabularFigures()];

String _kip(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

const _months = [
  'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
  'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
];

String _monthLabel(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  if (d == null) return '—';
  return '${_months[d.month - 1]} ${d.year}';
}

/// ພະນັກງານເບິ່ງເງິນເດືອນຂອງຕົນເອງ — ຍ້ອນຫຼັງໄດ້ທຸກເດືອນ.
class StaffPayslipsScreen extends StatefulWidget {
  const StaffPayslipsScreen({super.key});

  @override
  State<StaffPayslipsScreen> createState() => _StaffPayslipsScreenState();
}

class _StaffPayslipsScreenState extends State<StaffPayslipsScreen> {
  List<dynamic>? _slips;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StaffAuth.payslips();
    if (mounted) setState(() { _slips = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: _gold,
          backgroundColor: Colors.white,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                  children: [
                    Text('ເງິນເດືອນຂອງຂ້ອຍ',
                        style: GoogleFonts.notoSerifLao(
                            fontSize: 21, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('ສະແດງສະເພາະເດືອນທີ່ຮ້ານສະຫຼຸບແລ້ວ',
                        style: GoogleFonts.notoSansLao(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6))),
                    const SizedBox(height: 18),
                    if ((_slips ?? []).isEmpty) _empty()
                    else
                      ...(_slips!).map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _slipCard(s as Map<String, dynamic>),
                          )),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _empty() => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 40, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text('ຍັງບໍ່ມີໃບເງິນເດືອນ',
                style: GoogleFonts.notoSerifLao(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text('ຈະປາກົດຂຶ້ນເມື່ອຮ້ານສະຫຼຸບເງິນເດືອນຂອງເດືອນນັ້ນແລ້ວ',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansLao(
                    fontSize: 12, height: 1.55,
                    color: Colors.white.withValues(alpha: 0.6))),
          ],
        ),
      );

  Widget _slipCard(Map<String, dynamic> s) {
    final paid = s['status'] == 'paid';
    final lines = (s['lines'] as List?) ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          title: Row(
            children: [
              Expanded(
                child: Text(_monthLabel(s['period'] as String?),
                    style: GoogleFonts.notoSerifLao(
                        fontSize: 15.5, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: (paid ? _ok : _gold).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: (paid ? _ok : _gold).withValues(alpha: 0.55)),
                ),
                child: Text(paid ? 'ຈ່າຍແລ້ວ' : 'ລໍຈ່າຍ',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 10.5, fontWeight: FontWeight.w700,
                        color: paid ? _ok : _gold)),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${_kip(s['net_pay'] as num? ?? 0)} ກີບ',
                    style: GoogleFonts.manrope(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: Colors.white, fontFeatures: _tnum)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${s['days_worked']} ມື້ · '
                    '${(s['hours_worked'] as num?)?.toStringAsFixed(1) ?? '0'} ຊມ',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            ...lines.map((l) => _line(l as Map<String, dynamic>)),
            const SizedBox(height: 8),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            _line({'label': 'ລວມສຸດທິ', 'amount': s['net_pay']}, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _line(Map<String, dynamic> l, {bool bold = false}) {
    final amt = (l['amount'] as num?) ?? 0;
    final neg = amt < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(l['label']?.toString() ?? '',
                style: GoogleFonts.notoSansLao(
                    fontSize: 12.5, height: 1.5,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: Colors.white
                        .withValues(alpha: bold ? 1 : 0.78))),
          ),
          const SizedBox(width: 12),
          Text('${neg ? '−' : ''}${_kip(amt)}',
              style: GoogleFonts.manrope(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: neg ? const Color(0xFFEF8A7A) : Colors.white,
                  fontFeatures: _tnum)),
        ],
      ),
    );
  }
}
