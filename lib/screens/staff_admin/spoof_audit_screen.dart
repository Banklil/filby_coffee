import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/staff_service.dart';

const _tnum = [FontFeature.tabularFigures()];
const _danger = Color(0xFFE53935);
const _warn = Color(0xFFE6A23C);

/// ກວດວ່າພະນັກງານໃຊ້ແອັບປອມພິກັດບໍ.
///
/// ຢ່າສັບສົນ: ການກົດຢູ່ບ່ອນເກົ່າຊ້ຳໆ **ບໍ່ແມ່ນ** ຂໍ້ສົງໄສ — ເຮັດວຽກຮ້ານດຽວກັນ
/// ຕ້ອງກົດບ່ອນເກົ່າຢູ່ແລ້ວ. ສັນຍານແທ້ຄື GPS **ບໍ່ແກວ່ງເລີຍ**.
class SpoofAuditScreen extends StatefulWidget {
  const SpoofAuditScreen({super.key});

  @override
  State<SpoofAuditScreen> createState() => _SpoofAuditScreenState();
}

class _SpoofAuditScreenState extends State<SpoofAuditScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await StaffAdmin.audit(days: _days);
    if (mounted) setState(() { _data = d; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final items = (_data?['items'] as List?) ?? const [];
    final high = (_data?['high_risk'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        title: Text('ກວດການປອມພິກັດ',
            style: GoogleFonts.notoSerifLao(
                fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        actions: [
          PopupMenuButton<int>(
            initialValue: _days,
            onSelected: (v) { setState(() => _days = v); _load(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('7 ມື້')),
              PopupMenuItem(value: 30, child: Text('30 ມື້')),
              PopupMenuItem(value: 90, child: Text('90 ມື້')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text('$_days ມື້',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: FilbyColors.primary)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FilbyColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: FilbyColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  _explainer(high),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    _empty()
                  else
                    ...items.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _card(e as Map<String, dynamic>),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _explainer(int high) {
    final bad = high > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bad ? _danger.withValues(alpha: 0.08) : FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: bad ? _danger.withValues(alpha: 0.4) : FilbyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bad ? Icons.gpp_maybe_rounded : Icons.verified_user_outlined,
                  size: 20, color: bad ? _danger : FilbyColors.success),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                    bad ? 'ພົບ $high ຄົນທີ່ໜ້າສົງໄສ' : 'ຍັງບໍ່ພົບຂໍ້ສົງໄສ',
                    style: GoogleFonts.notoSerifLao(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: FilbyColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ການກົດຢູ່ບ່ອນເກົ່າຊ້ຳໆບໍ່ແມ່ນເລື່ອງຜິດປົກກະຕິ — ເຮັດວຽກຮ້ານດຽວກັນ '
            'ຕ້ອງກົດບ່ອນເກົ່າຢູ່ແລ້ວ. ສິ່ງທີ່ລະບົບເບິ່ງແມ່ນ '
            'ພິກັດ "ນິ້ງເກີນໄປ" — GPS ຈິງແກວ່ງ 5–30 ແມັດທຸກຄັ້ງ, '
            'ແອັບປອມສົ່ງຄ່າດຽວກັນເປັນະເປັນ.',
            style: GoogleFonts.notoSansLao(
                fontSize: 12, height: 1.6, color: FilbyColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Text('ຍັງບໍ່ມີພະນັກງານ ຫຼື ຍັງບໍ່ມີການລົງເວລາ',
              style: GoogleFonts.notoSansLao(
                  fontSize: 13, color: FilbyColors.textMuted)),
        ),
      );

  Widget _card(Map<String, dynamic> a) {
    final verdict = a['verdict']?.toString() ?? 'low';
    final (color, label) = switch (verdict) {
      'high' => (_danger, 'ໜ້າສົງໄສສູງ'),
      'medium' => (_warn, 'ຄວນເບິ່ງເພີ່ມ'),
      'low' => (FilbyColors.success, 'ປົກກະຕິ'),
      'insufficient' => (FilbyColors.textMuted, 'ຂໍ້ມູນຍັງໜ້ອຍ'),
      _ => (FilbyColors.textMuted, 'ຍັງບໍ່ມີການກົດ'),
    };
    final reasons = (a['reasons'] as List?) ?? const [];
    final punches = (a['punches'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: verdict == 'high'
                ? _danger.withValues(alpha: 0.45)
                : FilbyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a['staff_name']?.toString() ?? '—',
                    style: GoogleFonts.notoSerifLao(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: FilbyColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(label,
                    style: GoogleFonts.notoSansLao(
                        fontSize: 10.5, fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          if (punches > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _metric('ກົດທັງໝົດ', '$punches ຄັ້ງ'),
                _metric('ພິກັດຕ່າງກັນ',
                    '${a['unique_points'] ?? 0}/$punches'),
                _metric('ການແກວ່ງ',
                    '${(a['spread_m'] as num?)?.toStringAsFixed(1) ?? '0'} ມ',
                    highlight: (a['spread_m'] as num? ?? 99) < 3),
              ],
            ),
          ],
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: FilbyColors.border),
            const SizedBox(height: 10),
            ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 5, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.toString(),
                            style: GoogleFonts.notoSansLao(
                                fontSize: 12, height: 1.5,
                                color: FilbyColors.textSecondary)),
                      ),
                    ],
                  ),
                )),
          ],
          if (punches > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showPoints(a),
                icon: const Icon(Icons.my_location, size: 15),
                label: Text('ເບິ່ງພິກັດແຕ່ລະຄັ້ງ',
                    style: GoogleFonts.notoSansLao(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: FilbyColors.primary,
                    padding: EdgeInsets.zero),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.notoSansLao(
                  fontSize: 10.5, color: FilbyColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 13.5, fontWeight: FontWeight.w800,
                  fontFeatures: _tnum,
                  color: highlight ? _danger : FilbyColors.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _showPoints(Map<String, dynamic> a) async {
    final pts = await StaffAdmin.auditPoints(a['staff_id'] as int, days: _days);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: FilbyColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8, expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: FilbyColors.surface3,
                  borderRadius: BorderRadius.circular(999)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text('ພິກັດຂອງ ${a['staff_name']}',
                        style: GoogleFonts.notoSerifLao(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: FilbyColors.textPrimary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _ph('ວັນທີ', 3), _ph('ພິກັດ', 5), _ph('ຄວາມແມ່ນຢຳ', 2),
              ]),
            ),
            const Divider(height: 14),
            Expanded(
              child: (pts == null || pts.isEmpty)
                  ? Center(
                      child: Text('ບໍ່ມີຂໍ້ມູນ',
                          style: GoogleFonts.notoSansLao(
                              fontSize: 13, color: FilbyColors.textMuted)))
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: pts.length,
                      itemBuilder: (_, i) {
                        final p = pts[i] as Map<String, dynamic>;
                        final acc = (p['accuracy_m'] as num?)?.toDouble();
                        final bad = acc != null && acc <= 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(p['date']?.toString() ?? '',
                                    style: GoogleFonts.manrope(
                                        fontSize: 11.5, fontFeatures: _tnum,
                                        color: FilbyColors.textPrimary)),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                    '${(p['lat'] as num?)?.toStringAsFixed(6)}, '
                                    '${(p['lng'] as num?)?.toStringAsFixed(6)}',
                                    style: GoogleFonts.manrope(
                                        fontSize: 11, fontFeatures: _tnum,
                                        color: FilbyColors.textSecondary)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    acc == null ? '—' : '${acc.toStringAsFixed(0)} ມ',
                                    style: GoogleFonts.manrope(
                                        fontSize: 11.5, fontFeatures: _tnum,
                                        fontWeight:
                                            bad ? FontWeight.w800 : FontWeight.w500,
                                        color: bad
                                            ? _danger
                                            : FilbyColors.textSecondary)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t,
            style: GoogleFonts.notoSansLao(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                color: FilbyColors.textMuted)),
      );
}
