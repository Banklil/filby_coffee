import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/staff_service.dart';
import 'spoof_audit_screen.dart';

const _tnum = [FontFeature.tabularFigures()];
const _danger = Color(0xFFE53935);
const _warn = Color(0xFFE6A23C);

String _kip(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// ໜ້າຈັດການພະນັກງານຂອງເຈົ້າຂອງຮ້ານ — ລາຍຊື່ · ເວລາ · ເງິນເດືອນ.
class StaffHubScreen extends StatefulWidget {
  const StaffHubScreen({super.key});

  @override
  State<StaffHubScreen> createState() => _StaffHubScreenState();
}

class _StaffHubScreenState extends State<StaffHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<dynamic> _staff = const [];
  Map<String, dynamic>? _geo;
  Map<String, dynamic>? _attendance;
  Map<String, dynamic>? _payroll;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      StaffAdmin.list(),
      StaffAdmin.geofence(),
      StaffAdmin.attendance(),
      StaffAdmin.payroll(),
    ]);
    if (!mounted) return;
    setState(() {
      _staff = (results[0] as List?) ?? const [];
      _geo = results[1] as Map<String, dynamic>?;
      _attendance = results[2] as Map<String, dynamic>?;
      _payroll = results[3] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.notoSansLao(fontSize: 13)),
      backgroundColor: error ? _danger : FilbyColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        title: Text('ພະນັກງານ',
            style: GoogleFonts.notoSerifLao(
                fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            tooltip: 'ກວດການປອມພິກັດ',
            icon: const Icon(Icons.gpp_maybe_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SpoofAuditScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: FilbyColors.primary,
          unselectedLabelColor: FilbyColors.textMuted,
          indicatorColor: FilbyColors.primary,
          labelStyle: GoogleFonts.notoSansLao(
              fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'ລາຍຊື່'), Tab(text: 'ເວລາ'), Tab(text: 'ເງິນເດືອນ'),
          ],
        ),
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _staffForm(),
              backgroundColor: FilbyColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1, size: 19),
              label: Text('ເພີ່ມ',
                  style: GoogleFonts.notoSansLao(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FilbyColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [_staffTab(), _attendanceTab(), _payrollTab()],
            ),
    );
  }

  // ── ແທັບ 1: ລາຍຊື່ + ທີ່ຕັ້ງຮ້ານ ──────────────────────────────────
  Widget _staffTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: FilbyColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
        children: [
          _geofenceCard(),
          const SizedBox(height: 16),
          if (_staff.isEmpty)
            _empty('ຍັງບໍ່ມີພະນັກງານ',
                'ກົດປຸ່ມ "ເພີ່ມ" ເພື່ອສ້າງບັນຊີໃຫ້ພະນັກງານ — '
                'ເຂົາຈະໃຊ້ເບີໂທ ແລະ PIN ເຂົ້າສູ່ລະບົບເອງ')
          else
            ..._staff.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _staffCard(s as Map<String, dynamic>),
                )),
        ],
      ),
    );
  }

  Widget _geofenceCard() {
    final ready = _geo?['ready'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ready ? FilbyColors.surface : _warn.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: ready ? FilbyColors.border : _warn.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ready ? Icons.place : Icons.wrong_location_outlined,
                  size: 19, color: ready ? FilbyColors.primary : _warn),
              const SizedBox(width: 9),
              Expanded(
                child: Text(ready ? 'ທີ່ຕັ້ງຮ້ານຕັ້ງແລ້ວ' : 'ຍັງບໍ່ໄດ້ຕັ້ງທີ່ຕັ້ງຮ້ານ',
                    style: GoogleFonts.notoSerifLao(
                        fontSize: 14.5, fontWeight: FontWeight.w700,
                        color: FilbyColors.textPrimary)),
              ),
              if (ready)
                Text('ລັດສະໝີ ${_geo?['radius_m'] ?? 150} ມ',
                    style: GoogleFonts.manrope(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        fontFeatures: _tnum, color: FilbyColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ready
                ? 'ພະນັກງານກົດເຂົ້າວຽກໄດ້ສະເພາະເມື່ອຢູ່ພາຍໃນລັດສະໝີນີ້'
                : 'ຕ້ອງຕັ້ງກ່ອນ ພະນັກງານຈຶ່ງກົດເຂົ້າວຽກໄດ້ — '
                    'ໄປຢືນຢູ່ຮ້ານແລ້ວກົດປຸ່ມລຸ່ມນີ້',
            style: GoogleFonts.notoSansLao(
                fontSize: 12, height: 1.55, color: FilbyColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _setGeofence,
              icon: const Icon(Icons.my_location, size: 16),
              label: Text(ready ? 'ຕັ້ງໃໝ່ຈາກຕຳແໜ່ງປັດຈຸບັນ' : 'ໃຊ້ຕຳແໜ່ງປັດຈຸບັນ',
                  style: GoogleFonts.notoSansLao(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: FilbyColors.primary,
                side: const BorderSide(color: FilbyColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setGeofence() async {
    int radius = (_geo?['radius_m'] as num?)?.toInt() ?? 150;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: FilbyColors.surface,
          title: Text('ລັດສະໝີທີ່ອະນຸຍາດ',
              style: GoogleFonts.notoSerifLao(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: FilbyColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$radius ແມັດ',
                  style: GoogleFonts.manrope(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      fontFeatures: _tnum, color: FilbyColors.primary)),
              Slider(
                value: radius.toDouble(), min: 50, max: 500, divisions: 18,
                activeColor: FilbyColors.primary,
                onChanged: (v) => setD(() => radius = v.round()),
              ),
              Text(
                  'ຮ້ານນ້ອຍໃຊ້ 50–100 ມ. ຕັ້ງກວ້າງເກີນໄປ '
                  'ພະນັກງານກົດຈາກນອກຮ້ານໄດ້.',
                  style: GoogleFonts.notoSansLao(
                      fontSize: 11.5, height: 1.5,
                      color: FilbyColors.textSecondary)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ຍົກເລີກ')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, radius),
                child: const Text('ໃຊ້ຕຳແໜ່ງນີ້')),
          ],
        ),
      ),
    );
    if (picked == null) return;

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _toast('ຕ້ອງອະນຸຍາດການເຂົ້າເຖິງທີ່ຕັ້ງກ່ອນ', error: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 25)),
      );
      final err = await StaffAdmin.setGeofence(
          pos.latitude, pos.longitude, picked);
      if (!mounted) return;
      if (err != null) {
        _toast(err, error: true);
        return;
      }
      _toast('ຕັ້ງທີ່ຕັ້ງຮ້ານແລ້ວ');
      await _load();
    } catch (_) {
      if (mounted) _toast('ອ່ານທີ່ຕັ້ງບໍ່ໄດ້ — ກວດວ່າເປີດ GPS', error: true);
    }
  }

  Widget _staffCard(Map<String, dynamic> s) {
    final hourly = s['pay_type'] == 'hourly';
    return GestureDetector(
      onTap: () => _staffForm(existing: s),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FilbyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FilbyColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: FilbyColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                  (s['name']?.toString() ?? '?').characters.first,
                  style: GoogleFonts.notoSerifLao(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: FilbyColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['name']?.toString() ?? '',
                      style: GoogleFonts.notoSansLao(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: FilbyColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                      [
                        if ((s['role'] ?? '').toString().isNotEmpty) s['role'],
                        s['phone'],
                      ].join(' · '),
                      style: GoogleFonts.notoSansLao(
                          fontSize: 11.5, color: FilbyColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    hourly
                        ? '${_kip(s['hourly_rate'] as num? ?? 0)}/ຊມ'
                        : '${_kip(s['base_salary'] as num? ?? 0)}/ດ',
                    style: GoogleFonts.manrope(
                        fontSize: 12.5, fontWeight: FontWeight.w800,
                        fontFeatures: _tnum, color: FilbyColors.textPrimary)),
                const SizedBox(height: 3),
                Text(hourly ? 'ລາຍຊົ່ວໂມງ' : 'ລາຍເດືອນ',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 10, color: FilbyColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ແທັບ 2: ເວລາເຮັດວຽກ ───────────────────────────────────────────
  Widget _attendanceTab() {
    final items = (_attendance?['items'] as List?) ?? const [];
    if (items.isEmpty) {
      return _empty('ຍັງບໍ່ມີການລົງເວລາ',
          'ເມື່ອພະນັກງານກົດເຂົ້າວຽກ ລາຍການຈະປາກົດຢູ່ນີ້');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: FilbyColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _attendanceRow(items[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _attendanceRow(Map<String, dynamic> a) {
    String clock(String? iso) {
      final d = DateTime.tryParse(iso ?? '')?.toLocal();
      if (d == null) return '—';
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }

    final mins = (a['minutes_worked'] as num?)?.toInt() ?? 0;
    final open = a['clock_out_at'] == null;
    final flags = (a['flags'] as List?) ?? const [];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: flags.isNotEmpty
                ? _warn.withValues(alpha: 0.5)
                : FilbyColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['staff_name']?.toString() ?? '',
                        style: GoogleFonts.notoSansLao(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: FilbyColors.textPrimary)),
                    Text(a['date']?.toString() ?? '',
                        style: GoogleFonts.manrope(
                            fontSize: 11, fontFeatures: _tnum,
                            color: FilbyColors.textMuted)),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                    '${clock(a['clock_in_at'] as String?)} → '
                    '${open ? 'ຍັງບໍ່ອອກ' : clock(a['clock_out_at'] as String?)}',
                    style: GoogleFonts.manrope(
                        fontSize: 11.5, fontFeatures: _tnum,
                        color: open ? _warn : FilbyColors.textSecondary)),
              ),
              Expanded(
                flex: 2,
                child: Text(mins == 0 ? '—' : '${(mins / 60).toStringAsFixed(2)} ຊມ',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.manrope(
                        fontSize: 12.5, fontWeight: FontWeight.w800,
                        fontFeatures: _tnum, color: FilbyColors.textPrimary)),
              ),
            ],
          ),
          if (flags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 13, color: _warn),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(flags.join(' · '),
                      style: GoogleFonts.manrope(
                          fontSize: 10.5, color: _warn)),
                ),
              ],
            ),
          ],
          if (a['in_distance_m'] != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ຫ່າງຈາກຮ້ານ ${a['in_distance_m']} ມ',
                  style: GoogleFonts.notoSansLao(
                      fontSize: 10.5, color: FilbyColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }

  // ── ແທັບ 3: ເງິນເດືອນ ──────────────────────────────────────────────
  Widget _payrollTab() {
    final p = _payroll;
    final items = (p?['items'] as List?) ?? const [];
    final status = p?['status']?.toString() ?? 'draft';

    return RefreshIndicator(
      onRefresh: _load,
      color: FilbyColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [FilbyColors.navy, FilbyColors.navySoft],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('ລວມຈ່າຍເດືອນນີ້',
                          style: GoogleFonts.notoSansLao(
                              fontSize: 12, color: Colors.white70)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                          switch (status) {
                            'paid' => 'ຈ່າຍແລ້ວ',
                            'finalised' => 'ສະຫຼຸບແລ້ວ',
                            _ => 'ຮ່າງ',
                          },
                          style: GoogleFonts.notoSansLao(
                              fontSize: 10.5, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${_kip(p?['total_net'] as num? ?? 0)} ກີບ',
                    style: GoogleFonts.manrope(
                        fontSize: 28, fontWeight: FontWeight.w800,
                        color: Colors.white, fontFeatures: _tnum)),
                Text('${items.length} ຄົນ',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (status == 'draft' && items.isNotEmpty)
            _actionButton('ສະຫຼຸບເງິນເດືອນເດືອນນີ້', Icons.lock_outline, () async {
              final err = await StaffAdmin.finalise();
              if (!mounted) return;
              if (err != null) { _toast(err, error: true); return; }
              _toast('ສະຫຼຸບແລ້ວ — ຕົວເລກຖືກລັອກ');
              await _load();
            })
          else if (status == 'finalised')
            _actionButton('ໝາຍວ່າຈ່າຍແລ້ວ', Icons.payments_outlined, () async {
              final err = await StaffAdmin.markPaid();
              if (!mounted) return;
              if (err != null) { _toast(err, error: true); return; }
              _toast('ບັນທຶກເປັນລາຍຈ່າຍ "ຄ່າແຮງງານ" ໃນບັນຊີຮ້ານແລ້ວ');
              await _load();
            }),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _empty('ຍັງບໍ່ມີພະນັກງານ', 'ເພີ່ມພະນັກງານກ່ອນຈຶ່ງຄິດເງິນເດືອນໄດ້')
          else
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _payslipRow(e as Map<String, dynamic>, status),
                )),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: GoogleFonts.notoSansLao(
                fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: FilbyColors.primary,
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
        ),
      ),
    );
  }

  Widget _payslipRow(Map<String, dynamic> e, String status) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['staff_name']?.toString() ?? '',
                        style: GoogleFonts.notoSansLao(
                            fontSize: 13.5, fontWeight: FontWeight.w700,
                            color: FilbyColors.textPrimary)),
                    Text(
                        '${e['days_worked']} ມື້ · '
                        '${(e['hours_worked'] as num?)?.toStringAsFixed(1) ?? '0'} ຊມ',
                        style: GoogleFonts.notoSansLao(
                            fontSize: 11, color: FilbyColors.textMuted)),
                  ],
                ),
              ),
              Text('${_kip(e['net_pay'] as num? ?? 0)} ກີບ',
                  style: GoogleFonts.manrope(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      fontFeatures: _tnum, color: FilbyColors.textPrimary)),
            ],
          ),
          if (status == 'draft') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _adjustmentForm(e['staff_id'] as int,
                    e['staff_name']?.toString() ?? ''),
                icon: const Icon(Icons.add, size: 15),
                label: Text('ເພີ່ມ / ຫັກ',
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

  Widget _empty(String title, String body) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(Icons.groups_outlined, size: 46, color: FilbyColors.textMuted),
            const SizedBox(height: 14),
            Text(title,
                style: GoogleFonts.notoSerifLao(
                    fontSize: 15.5, fontWeight: FontWeight.w700,
                    color: FilbyColors.textPrimary)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansLao(
                    fontSize: 12.5, height: 1.6,
                    color: FilbyColors.textSecondary)),
          ],
        ),
      );

  // ── ຟອມພະນັກງານ ───────────────────────────────────────────────────
  Future<void> _staffForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final phone = TextEditingController(text: existing?['phone']?.toString() ?? '');
    final pin = TextEditingController();
    final role = TextEditingController(text: existing?['role']?.toString() ?? '');
    final amount = TextEditingController(
        text: isEdit
            ? (existing['pay_type'] == 'hourly'
                    ? existing['hourly_rate']
                    : existing['base_salary'])
                .toString()
            : '');
    String payType = existing?['pay_type']?.toString() ?? 'monthly';
    final formKey = GlobalKey<FormState>();
    bool busy = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: FilbyColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: FilbyColors.surface3,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    Text(isEdit ? 'ແກ້ໄຂພະນັກງານ' : 'ເພີ່ມພະນັກງານ',
                        style: GoogleFonts.notoSerifLao(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            color: FilbyColors.textPrimary)),
                    const SizedBox(height: 16),

                    _tf(name, 'ຊື່ ແລະ ນາມສະກຸນ', Icons.person_outline,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'ກະລຸນາໃສ່ຊື່' : null),
                    _tf(phone, 'ເບີໂທ (ໃຊ້ເຂົ້າສູ່ລະບົບ)', Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validator: (v) => (v ?? '').trim().length < 5
                            ? 'ກະລຸນາໃສ່ເບີໂທ' : null),
                    _tf(pin,
                        isEdit ? 'PIN ໃໝ່ (ວ່າງໄວ້ = ບໍ່ປ່ຽນ)' : 'PIN 4–6 ຕົວເລກ',
                        Icons.lock_outline,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (isEdit && s.isEmpty) return null;
                          if (s.length < 4) return 'PIN ຢ່າງໜ້ອຍ 4 ຕົວເລກ';
                          if (int.tryParse(s) == null) return 'ຕ້ອງເປັນຕົວເລກ';
                          return null;
                        }),
                    _tf(role, 'ໜ້າທີ່ (ຖ້າມີ)', Icons.badge_outlined),

                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _payTab('monthly', 'ລາຍເດືອນ', payType,
                            () => setS(() => payType = 'monthly')),
                        const SizedBox(width: 8),
                        _payTab('hourly', 'ລາຍຊົ່ວໂມງ', payType,
                            () => setS(() => payType = 'hourly')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _tf(amount,
                        payType == 'hourly'
                            ? 'ອັດຕາຕໍ່ຊົ່ວໂມງ (ກີບ)'
                            : 'ເງິນເດືອນ (ກີບ)',
                        Icons.payments_outlined,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(
                              (v ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          return n <= 0 ? 'ກະລຸນາໃສ່ຈຳນວນເງິນ' : null;
                        }),

                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setS(() => busy = true);

                                final amt = int.parse(amount.text
                                    .replaceAll(RegExp(r'[^0-9]'), ''));
                                final body = <String, dynamic>{
                                  'name': name.text.trim(),
                                  'phone': phone.text.trim(),
                                  'role': role.text.trim().isEmpty
                                      ? null : role.text.trim(),
                                  'pay_type': payType,
                                  'base_salary': payType == 'monthly' ? amt : 0,
                                  'hourly_rate': payType == 'hourly' ? amt : 0,
                                };
                                if (pin.text.trim().isNotEmpty) {
                                  body['pin'] = pin.text.trim();
                                }

                                final err = isEdit
                                    ? await StaffAdmin.update(
                                        existing['id'] as int, body)
                                    : await StaffAdmin.create(body);

                                if (!ctx.mounted) return;
                                if (err != null) {
                                  setS(() => busy = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content: Text(err),
                                          backgroundColor: _danger));
                                  return;
                                }
                                Navigator.pop(ctx, true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FilbyColors.primary,
                          foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text(isEdit ? 'ບັນທຶກ' : 'ສ້າງບັນຊີ',
                                style: GoogleFonts.notoSansLao(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final err = await StaffAdmin.deactivate(
                              existing['id'] as int);
                          if (!ctx.mounted) return;
                          if (err != null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(err), backgroundColor: _danger));
                            return;
                          }
                          Navigator.pop(ctx, true);
                        },
                        icon: const Icon(Icons.person_off_outlined, size: 16),
                        label: Text('ປິດການໃຊ້ງານບັນຊີນີ້',
                            style: GoogleFonts.notoSansLao(fontSize: 13)),
                        style: TextButton.styleFrom(foregroundColor: _danger),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      _toast(isEdit ? 'ບັນທຶກແລ້ວ' : 'ສ້າງບັນຊີພະນັກງານແລ້ວ');
      await _load();
    }
  }

  Widget _payTab(String value, String label, String current, VoidCallback onTap) {
    final active = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? FilbyColors.primary.withValues(alpha: 0.1)
                : FilbyColors.surface2,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: active ? FilbyColors.primary : FilbyColors.border,
                width: active ? 1.5 : 1),
          ),
          child: Text(label,
              style: GoogleFonts.notoSansLao(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: active ? FilbyColors.primary : FilbyColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: FilbyColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSansLao(
              fontSize: 12.5, color: FilbyColors.textSecondary),
          prefixIcon: Icon(icon, size: 18, color: FilbyColors.textMuted),
          filled: true,
          fillColor: FilbyColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FilbyColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FilbyColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FilbyColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── ຟອມເງິນເພີ່ມ / ຫັກ ─────────────────────────────────────────────
  Future<void> _adjustmentForm(int staffId, String staffName) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    String kind = 'advance';

    const kinds = {
      'allowance': 'ເງິນອຸດໜູນ', 'bonus': 'ໂບນັດ', 'overtime': 'ລ່ວງເວລາ',
      'advance': 'ເບີກລ່ວງໜ້າ', 'fine': 'ຄ່າປັບ', 'deduction': 'ຫັກອື່ນໆ',
    };

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: FilbyColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: FilbyColors.surface3,
                          borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  Text('ເພີ່ມ / ຫັກ — $staffName',
                      style: GoogleFonts.notoSerifLao(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: FilbyColors.textPrimary)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: kinds.entries.map((e) {
                      final active = e.key == kind;
                      final plus = ['allowance', 'bonus', 'overtime']
                          .contains(e.key);
                      return GestureDetector(
                        onTap: () => setS(() => kind = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? (plus ? FilbyColors.success : _danger)
                                : FilbyColors.surface2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: active
                                    ? Colors.transparent
                                    : FilbyColors.border),
                          ),
                          child: Text(e.value,
                              style: GoogleFonts.notoSansLao(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : FilbyColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _tf(amount, 'ຈຳນວນເງິນ (ກີບ)', Icons.payments_outlined,
                      keyboard: TextInputType.number),
                  _tf(note, 'ເຫດຜົນ (ຖ້າມີ)', Icons.notes_outlined),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final n = int.tryParse(amount.text
                            .replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        if (n <= 0) return;
                        final err = await StaffAdmin.addAdjustment({
                          'staff_id': staffId, 'kind': kind, 'amount': n,
                          'note': note.text.trim().isEmpty
                              ? null : note.text.trim(),
                        });
                        if (!ctx.mounted) return;
                        if (err != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(err), backgroundColor: _danger));
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FilbyColors.primary,
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: Text('ບັນທຶກ',
                          style: GoogleFonts.notoSansLao(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      _toast('ບັນທຶກແລ້ວ');
      await _load();
    }
  }
}
