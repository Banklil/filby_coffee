import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/staff_service.dart';

// Filby navy + gold. ສີສັນຍານແຍກຕ່າງຫາກຈາກສີແບຣນ ເພື່ອບໍ່ໃຫ້ຄວາມໝາຍປົນກັນ.
const _navy = Color(0xFF17233F);
const _gold = Color(0xFFC9A24B);
const _ok = Color(0xFF14B36A);
const _warn = Color(0xFFE6A23C);
const _danger = Color(0xFFE53935);

/// ຕົວເລກທັງໝົດໃຊ້ tabular figures ເພື່ອບໍ່ໃຫ້ຄໍລຳຍັບໄປມາຕອນເລກປ່ຽນ.
const _tnum = [FontFeature.tabularFigures()];

class StaffClockScreen extends StatefulWidget {
  const StaffClockScreen({super.key});

  @override
  State<StaffClockScreen> createState() => _StaffClockScreenState();
}

class _StaffClockScreenState extends State<StaffClockScreen> {
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _month;
  bool _busy = false;
  String? _status;
  bool _statusIsError = false;
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1),
        (_) => mounted ? setState(() => _now = DateTime.now()) : null);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    await StaffAuth.loadMe();
    final m = await StaffAuth.attendance();
    if (mounted) setState(() { _me = StaffAuth.me; _month = m; });
  }

  DateTime? get _shiftStart {
    final open = _me?['open_shift'];
    if (open == null) return null;
    return DateTime.tryParse(open['clock_in_at'] as String)?.toLocal();
  }

  bool get _onShift => _shiftStart != null;

  Future<void> _punch() async {
    setState(() { _busy = true; _status = null; });

    try {
      // ຂໍສິດເຂົ້າເຖິງທີ່ຕັ້ງກ່ອນ — ຖ້າຖືກປະຕິເສດ ບອກໃຫ້ຮູ້ວ່າຕ້ອງເປີດຢູ່ໃສ
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _busy = false;
          _statusIsError = true;
          _status = 'ຕ້ອງອະນຸຍາດການເຂົ້າເຖິງທີ່ຕັ້ງກ່ອນ — '
              'ເປີດໃນການຕັ້ງຄ່າຂອງ browser ແລ້ວລອງໃໝ່';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 25)),
      );

      final r = await StaffAuth.punch(
        _onShift ? 'clock-out' : 'clock-in',
        lat: pos.latitude, lng: pos.longitude, accuracy: pos.accuracy,
      );

      if (!mounted) return;
      if (r.error != null) {
        setState(() { _busy = false; _statusIsError = true; _status = r.error; });
        return;
      }

      await _load();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusIsError = false;
        _status = r.data?['message']?.toString() ?? 'ສຳເລັດ';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusIsError = true;
        _status = 'ອ່ານທີ່ຕັ້ງບໍ່ໄດ້ — ກວດວ່າເປີດ GPS ແລ້ວລອງໃໝ່';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _me?['name']?.toString() ?? '—';
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: _gold,
          backgroundColor: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              _header(name),
              const SizedBox(height: 18),
              _dateTimeCards(),
              const SizedBox(height: 22),
              Center(child: _punchButton()),
              if (_status != null) ...[
                const SizedBox(height: 18),
                _statusBanner(),
              ],
              const SizedBox(height: 22),
              _monthSummary(),
              const SizedBox(height: 16),
              _historyTable(),
            ],
          ),
        ),
      ),
    );
  }

  // ── ຫົວຂໍ້: ຮູບ + ຊື່ + ໜ້າທີ່ + ຮ້ານ ──────────────────────────────
  Widget _header(String name) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: _gold.withValues(alpha: 0.55), width: 2),
          ),
          alignment: Alignment.center,
          child: Text(initial,
              style: GoogleFonts.notoSerifLao(
                  fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSerifLao(
                      fontSize: 19, height: 1.35,
                      fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 3),
              Text(
                [
                  if ((_me?['role'] ?? '').toString().isNotEmpty) _me!['role'],
                  if ((_me?['shop_name'] ?? '').toString().isNotEmpty)
                    _me!['shop_name'],
                ].join(' · '),
                style: GoogleFonts.notoSansLao(
                    fontSize: 12, height: 1.5,
                    color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ວັນທີ + ໂມງແລ່ນ ────────────────────────────────────────────────
  Widget _dateTimeCards() {
    String two(int n) => n.toString().padLeft(2, '0');
    return Row(
      children: [
        Expanded(
          child: _glass(
            icon: Icons.calendar_today_outlined,
            value: '${two(_now.day)}-${two(_now.month)}-${_now.year}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _glass(
            icon: Icons.schedule_rounded,
            value: '${two(_now.hour)}:${two(_now.minute)}:${two(_now.second)}',
          ),
        ),
      ],
    );
  }

  Widget _glass({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: Colors.white, fontFeatures: _tnum)),
        ],
      ),
    );
  }

  // ── ປຸ່ມດຽວ ປ່ຽນຕາມສະຖານະ + ວົງແຫວນນັບເວລາກະ ──────────────────────
  Widget _punchButton() {
    final start = _shiftStart;
    final elapsed = start == null ? Duration.zero : _now.difference(start);
    // ວົງແຫວນເຕັມທີ່ 8 ຊົ່ວໂມງ — ກະປົກກະຕິຂອງຮ້ານກາເຟ
    final progress = (elapsed.inSeconds / (8 * 3600)).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 210, height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_onShift)
                SizedBox(
                  width: 210, height: 210,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation(_gold),
                  ),
                ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _busy ? null : _punch,
                  child: Container(
                    width: 178, height: 178,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _onShift ? Colors.white : _gold,
                      boxShadow: [
                        BoxShadow(
                          color: (_onShift ? Colors.black : _gold)
                              .withValues(alpha: 0.35),
                          blurRadius: 26, offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _busy
                        ? const CircularProgressIndicator(color: _navy)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  _onShift
                                      ? Icons.logout_rounded
                                      : Icons.fingerprint_rounded,
                                  size: 40, color: _navy),
                              const SizedBox(height: 8),
                              Text(_onShift ? 'ກົດອອກວຽກ' : 'ກົດເຂົ້າວຽກ',
                                  style: GoogleFonts.notoSansLao(
                                      fontSize: 16, height: 1.4,
                                      fontWeight: FontWeight.w700,
                                      color: _navy)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_onShift)
          Text(
            'ເຂົ້າວຽກແລ້ວ ${elapsed.inHours} ຊມ '
            '${(elapsed.inMinutes % 60).toString().padLeft(2, '0')} ນທ',
            style: GoogleFonts.notoSansLao(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: _gold, fontFeatures: _tnum),
          )
        else
          Text('ຕ້ອງຢູ່ພາຍໃນຮ້ານຈຶ່ງກົດໄດ້',
              style: GoogleFonts.notoSansLao(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _statusBanner() {
    final c = _statusIsError ? _danger : _ok;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIsError ? Icons.error_outline : Icons.check_circle_outline,
              size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_status!,
                style: GoogleFonts.notoSansLao(
                    fontSize: 12.5, height: 1.5, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── ສະຫຼຸບເດືອນນີ້ ─────────────────────────────────────────────────
  Widget _monthSummary() {
    final hours = (_month?['total_hours'] as num?)?.toDouble() ?? 0;
    final days = (_month?['days_worked'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _stat('ເດືອນນີ້ເຮັດວຽກ', '$days ມື້'),
          Container(width: 1, height: 34,
              color: Colors.white.withValues(alpha: 0.14)),
          _stat('ລວມຊົ່ວໂມງ', '${hours.toStringAsFixed(1)} ຊມ'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.notoSansLao(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: Colors.white, fontFeatures: _tnum)),
          ],
        ),
      );

  // ── ປະຫວັດການກົດ ──────────────────────────────────────────────────
  Widget _historyTable() {
    final items = (_month?['items'] as List?) ?? const [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('ປະຫວັດການລົງເວລາ',
                style: GoogleFonts.notoSerifLao(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withValues(alpha: 0.05),
            child: Row(children: [
              _h('ວັນທີ', 3), _h('ເຂົ້າ', 2), _h('ອອກ', 2), _h('ຊົ່ວໂມງ', 2),
            ]),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('ຍັງບໍ່ມີການລົງເວລາໃນເດືອນນີ້',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.55))),
              ),
            )
          else
            ...items.take(30).map((e) => _row(e as Map<String, dynamic>)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _h(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t,
            style: GoogleFonts.notoSansLao(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.65))),
      );

  Widget _row(Map<String, dynamic> e) {
    String clock(String? iso) {
      if (iso == null) return '—';
      final d = DateTime.tryParse(iso)?.toLocal();
      if (d == null) return '—';
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }

    final mins = (e['minutes_worked'] as num?)?.toInt() ?? 0;
    final open = e['clock_out_at'] == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(e['date']?.toString() ?? '',
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: Colors.white,
                        fontFeatures: _tnum)),
                if (e['edited'] == true) ...[
                  const SizedBox(width: 5),
                  Icon(Icons.edit_outlined, size: 11, color: _warn),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(clock(e['clock_in_at'] as String?),
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontFeatures: _tnum)),
          ),
          Expanded(
            flex: 2,
            child: Text(open ? 'ຍັງບໍ່ອອກ' : clock(e['clock_out_at'] as String?),
                style: open
                    ? GoogleFonts.notoSansLao(fontSize: 11, color: _gold)
                    : GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontFeatures: _tnum)),
          ),
          Expanded(
            flex: 2,
            child: Text(mins == 0 ? '—' : (mins / 60).toStringAsFixed(2),
                style: GoogleFonts.manrope(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFeatures: _tnum)),
          ),
        ],
      ),
    );
  }
}
