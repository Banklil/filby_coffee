import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/credit_terms.dart';

enum _CreditState { loading, noApp, pending, approved, rejected, active }

class CreditScreen extends StatefulWidget {
  /// ເມື່ອຢູ່ໃນແທັບຂອງເມນູລຸ່ມ ບໍ່ມີໜ້າໃຫ້ຖອຍກັບ ຈຶ່ງເຊື່ອງປຸ່ມຍ້ອນກັບ.
  final bool embedded;
  const CreditScreen({super.key, this.embedded = false});
  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  _CreditState _state = _CreditState.loading;
  Map<String, dynamic>? _application;
  Map<String, dynamic>? _credit;   // ຈາກ /api/credits/me

  // Apply form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _idCardCtrl   = TextEditingController();
  final _bizCtrl      = TextEditingController();
  final _incomeCtrl   = TextEditingController();
  double _amount      = 1000000;
  String _purpose     = 'ຊື້ໝັ້ນກາເຟ';
  bool _submitting    = false;
  bool _agreedToTerms = false;

  final List<String> _purposes = ['ຊື້ໝັ້ນກາເຟ', 'ອຸປະກອນ', 'ຮ້ານ', 'ອື່ນໆ'];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _idCardCtrl.dispose(); _bizCtrl.dispose(); _incomeCtrl.dispose();
    super.dispose();
  }

  String _fmt(double n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// ວົງເງິນຈິງມາຈາກ /api/credits/me — ບໍ່ແມ່ນຈາກໃບສະໝັກ. ຮ້ານອາດໄດ້ຮັບວົງເງິນ
  /// ຈາກຝ່າຍບໍລິຫານໂດຍກົງ ໂດຍບໍ່ມີໃບສະໝັກໃນລະບົບ.
  Future<void> _loadCredit() async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/credits/me'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        _credit = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {
      // ບໍ່ເປັນຫຍັງ — ຄ່ອຍໄປສະແດງຕາມສະຖານະໃບສະໝັກແທນ
    }
  }

  bool get _hasFacility {
    final c = _credit;
    if (c == null) return false;
    return (c['effective_limit'] as num? ?? 0) > 0 ||
           (c['balance'] as num? ?? 0) > 0 ||
           (c['held'] as num? ?? 0) > 0;
  }

  Future<void> _loadStatus() async {
    setState(() => _state = _CreditState.loading);
    await _loadCredit();

    // ມີວົງເງິນ ຫຼື ມີໜີ້ຢູ່ແລ້ວ → ສະແດງບັນຊີ ບໍ່ຕ້ອງສົນໃຈໃບສະໝັກ
    if (_hasFacility) {
      if (mounted) setState(() => _state = _CreditState.active);
      return;
    }

    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/credit/applications'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final List apps = jsonDecode(utf8.decode(res.bodyBytes));
        if (apps.isEmpty) {
          setState(() => _state = _CreditState.noApp);
        } else {
          // Use the latest application
          final app = apps.first as Map<String, dynamic>;
          _application = app;
          final status = app['status'] as String? ?? 'pending';
          setState(() {
            _state = status == 'approved'
                ? _CreditState.approved
                : status == 'rejected'
                    ? _CreditState.rejected
                    : _CreditState.pending;
          });
        }
      } else {
        setState(() => _state = _CreditState.noApp);
      }
    } catch (_) {
      setState(() => _state = _CreditState.noApp);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ກະລຸນາອ່ານ ແລະ ຍອມຮັບເງື່ອນໄຂກ່ອນສົ່ງຄຳຂໍ'),
        backgroundColor: FilbyColors.navy,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/credit/applications'),
        headers: headers,
        body: jsonEncode({
          'full_name':      _nameCtrl.text.trim(),
          'phone':          _phoneCtrl.text.trim(),
          'id_card':        _idCardCtrl.text.trim(),
          'business_name':  _bizCtrl.text.trim().isEmpty ? null : _bizCtrl.text.trim(),
          'amount':         _amount,
          'purpose':        _purpose,
          'monthly_income': double.tryParse(_incomeCtrl.text.trim()),
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final app = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() { _application = app; _state = _CreditState.pending; _submitting = false; });
      } else {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        throw Exception(body['detail'] ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'), backgroundColor: const Color(0xFFE74C3C),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : GestureDetector(
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
        title: const Text('ສິນເຊື່ອ'),
        actions: [
          if (_state != _CreditState.loading)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStatus),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _CreditState.loading:
        return const Center(child: CircularProgressIndicator(color: FilbyColors.primary));

      case _CreditState.active:
        return _buildActive();

      case _CreditState.noApp:
        return _buildApplyForm();

      case _CreditState.pending:
        return _buildPending();

      case _CreditState.approved:
        return _buildApproved();

      case _CreditState.rejected:
        return _buildRejected();
    }
  }

  // ── 0. ບັນຊີສິນເຊື່ອທີ່ໃຊ້ງານຢູ່ ────────────────────────────────────
  Widget _buildActive() {
    final c = _credit!;
    final available = (c['available'] as num? ?? 0).toDouble();
    final limit     = (c['effective_limit'] as num? ?? 0).toDouble();
    final balance   = (c['balance'] as num? ?? 0).toDouble();
    final held      = (c['held'] as num? ?? 0).toDouble();
    final deposit   = (c['deposit'] as num? ?? 0).toDouble();
    final status    = c['credit_status'] as String? ?? 'good';
    final dueDate   = c['next_due_date'] as String?;
    final daysLeft  = c['days_until_due'] as int?;
    final usedRatio = limit > 0 ? ((balance + held) / limit).clamp(0.0, 1.0) : 0.0;

    return RefreshIndicator(
      onRefresh: _loadStatus,
      color: FilbyColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── ວົງເງິນຄົງເຫຼືອ ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [FilbyColors.navy, FilbyColors.navySoft],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('ວົງເງິນທີ່ສັ່ງໄດ້ອີກ',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${_fmt(available)} ກີບ',
                  style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: usedRatio.toDouble(),
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(
                      usedRatio > 0.85 ? const Color(0xFFEF8A7A) : FilbyColors.gold),
                  ),
                ),
                const SizedBox(height: 6),
                Text('ໃຊ້ໄປ ${_fmt(balance + held)} ຈາກ ${_fmt(limit)} ກີບ',
                  style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),

          // ── ວັນຄົບກຳນົດ ─────────────────────────────────────────
          if (dueDate != null) ...[
            const SizedBox(height: 14),
            _dueBanner(dueDate, daysLeft),
          ],

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _statCard('ໜີ້ຄ້າງຊຳລະ', balance,
                  Icons.receipt_long_outlined,
                  balance > 0 ? FilbyColors.gold : FilbyColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('ຈອງໄວ້ (ລໍສົ່ງເຄື່ອງ)', held,
                  Icons.inventory_2_outlined, FilbyColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          _statCard('ເງິນມັດຈຳທີ່ວາງໄວ້', deposit,
              Icons.lock_outline, FilbyColors.primary, wide: true),

          const SizedBox(height: 20),
          CreditTermsCard(exampleAmount: balance > 0 ? balance : (limit > 0 ? limit : 2000000)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final map = {
      'good':      ('ປົກກະຕິ',      const Color(0xFF6EE7A8)),
      'watch':     ('ໃກ້ຄົບກຳນົດ',  FilbyColors.goldSoft),
      'on_hold':   ('ລະງັບການສັ່ງ', const Color(0xFFEF8A7A)),
      'suspended': ('ບັນຊີຖືກລະງັບ', const Color(0xFFEF8A7A)),
      'defaulted': ('ຜິດນັດຊຳລະ',   const Color(0xFFEF8A7A)),
    };
    final (label, color) = map[status] ?? ('ປົກກະຕິ', const Color(0xFF6EE7A8));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _dueBanner(String dueDate, int? daysLeft) {
    final overdue = daysLeft != null && daysLeft < 0;
    final soon    = daysLeft != null && daysLeft >= 0 && daysLeft <= 7;
    final color   = overdue ? const Color(0xFFE53935)
                  : soon    ? FilbyColors.gold
                            : FilbyColors.success;
    final text = daysLeft == null
        ? 'ຄົບກຳນົດ $dueDate'
        : overdue
            ? 'ເກີນກຳນົດມາ ${-daysLeft} ມື້ — ກຳລັງຄິດດອກເບ້ຍ ${CreditPolicy.monthlyLabel}/ເດືອນ'
            : daysLeft == 0
                ? 'ຄົບກຳນົດ ມື້ນີ້'
                : 'ຄົບກຳນົດ ອີກ $daysLeft ມື້ ($dueDate)';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(overdue ? Icons.error_outline : Icons.event_outlined,
              size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: TextStyle(
                fontSize: 12.5, height: 1.4,
                fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, double value, IconData icon, Color color,
      {bool wide = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(fontSize: 10.5, color: FilbyColors.textMuted)),
                const SizedBox(height: 2),
                Text('${_fmt(value)} ກີບ',
                  style: TextStyle(
                    fontSize: wide ? 15 : 13.5,
                    fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Apply Form ─────────────────────────────────────────────────
  Widget _buildApplyForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [FilbyColors.navy, FilbyColors.navySoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.credit_card, color: FilbyColors.primary, size: 32),
                const SizedBox(height: 12),
                Text('ສະໝັກສິນເຊື່ອ',
                  style: GoogleFonts.notoSerifLao(fontSize: 20, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
                const SizedBox(height: 4),
                Text('ກວດສອບ 1-3 ວັນທຳການ · ບໍ່ມີດອກເບ້ຍ ${CreditPolicy.graceDays} ວັນ',
                  style: const TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _field('ຊື່-ນາມສະກຸນ', _nameCtrl, hint: 'ທ. ສົມສາ ດາລາວົງ'),
          _field('ເບີໂທ', _phoneCtrl, hint: '020xxxxxxxx', type: TextInputType.phone),
          _field('ເລກບັດປະຈຳຕົວ', _idCardCtrl, hint: '0000000000000'),
          _field('ຊື່ທຸລະກິດ (ຖ້າມີ)', _bizCtrl, hint: 'ຮ້ານກາເຟ...', required: false),
          _field('ລາຍຮັບ/ເດືອນ (ກີບ)', _incomeCtrl,
            hint: '5000000', type: TextInputType.number, required: false),

          const SizedBox(height: 16),
          const Text('ວົງເງິນທີ່ຕ້ອງການ', style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
          const SizedBox(height: 6),
          Text(_fmt(_amount) + ' ກີບ',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: FilbyColors.primary)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FilbyColors.primary,
              inactiveTrackColor: FilbyColors.surface2,
              thumbColor: FilbyColors.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _amount, min: 500000, max: 10000000, divisions: 19,
              onChanged: (v) => setState(() => _amount = v),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('500,000', style: TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
              Text('10,000,000', style: TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
            ],
          ),

          const SizedBox(height: 20),
          const Text('ຈຸດປະສົງ', style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _purposes.map((p) {
              final active = p == _purpose;
              return GestureDetector(
                onTap: () => setState(() => _purpose = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? FilbyColors.cream : FilbyColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? FilbyColors.cream : FilbyColors.border),
                  ),
                  child: Text(p,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? FilbyColors.bg : FilbyColors.textSecondary,
                    )),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),
          CreditTermsCard(exampleAmount: _amount),

          const SizedBox(height: 16),
          _agreeCheckbox(),

          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: FilbyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('ສົ່ງຄຳຂໍ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _agreeCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _agreedToTerms ? FilbyColors.primary : FilbyColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreedToTerms
                    ? FilbyColors.primary
                    : FilbyColors.borderStrong,
                width: 1.5,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.notoSansLao(
                  fontSize: 12.5,
                  height: 1.5,
                  color: FilbyColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'ຂ້າພະເຈົ້າໄດ້ອ່ານ ແລະ ຍອມຮັບ '),
                  TextSpan(
                    text: 'ເງື່ອນໄຂການໃຊ້ສິນເຊື່ອ',
                    style: const TextStyle(
                      color: FilbyColors.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' ລວມທັງການຄິດດອກເບ້ຍ ${CreditPolicy.monthlyLabel} ຕໍ່ເດືອນ '
                        'ຖ້າຊຳລະຊ້າກວ່າ ${CreditPolicy.graceDays} ມື້',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType type = TextInputType.text, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: FilbyColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            style: const TextStyle(color: FilbyColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: FilbyColors.textMuted, fontSize: 13),
              filled: true, fillColor: FilbyColors.surface,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'ກະລຸນາໃສ່ $label' : null
                : null,
          ),
        ],
      ),
    );
  }

  // ── 2. Pending ────────────────────────────────────────────────────
  Widget _buildPending() {
    final amount = (_application?['amount'] as num?)?.toDouble() ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: FilbyColors.warningBg,
                shape: BoxShape.circle,
                border: Border.all(color: FilbyColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.hourglass_top_rounded, size: 40, color: FilbyColors.primary),
            ),
            const SizedBox(height: 20),
            Text('ກຳລັງລໍຖ້າການອະນຸມັດ',
              style: GoogleFonts.notoSerifLao(fontSize: 20, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
            const SizedBox(height: 8),
            Text('ວົງເງິນທີ່ຂໍ: ${_fmt(amount)} ກີບ',
              style: const TextStyle(fontSize: 14, color: FilbyColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
              'ທີມງານ Filby Coffee ກຳລັງກວດສອບຄຳຂໍຂອງທ່ານ\nໃຊ້ເວລາ 1-3 ວັນທຳການ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: FilbyColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _loadStatus,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('ກວດສອບສະຖານະ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FilbyColors.primary,
                side: const BorderSide(color: FilbyColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Approved ───────────────────────────────────────────────────
  Widget _buildApproved() {
    final amount = (_application?['approved_limit'] as num?)?.toDouble()
        ?? (_application?['amount'] as num?)?.toDouble()
        ?? 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [FilbyColors.cream, FilbyColors.creamWarm],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.verified, color: Color(0xFF6EE7A8), size: 18),
                SizedBox(width: 6),
                Text('ອະນຸມັດແລ້ວ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6EE7A8))),
              ]),
              const SizedBox(height: 12),
              Text(_fmt(amount),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              Text('ວົງເງິນສິນເຊື່ອ · ຊຳລະພາຍໃນ ${CreditPolicy.graceDays} ວັນ ບໍ່ມີດອກເບ້ຍ',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FilbyColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FilbyColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ສິດທິປະໂຫຍດ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
              const SizedBox(height: 10),
              const _BenefitRow(icon: Icons.check_circle, text: 'ສ່ງ order ໄດ້ທັນທີ'),
              _BenefitRow(
                icon: Icons.check_circle,
                text: 'ຊຳລະພາຍໃນ ${CreditPolicy.graceDays} ວັນ ບໍ່ມີດອກເບ້ຍ',
              ),
              const _BenefitRow(icon: Icons.check_circle, text: 'ສາມາດ top-up ວົງເງິນໄດ້'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CreditTermsCard(exampleAmount: amount > 0 ? amount : 2000000),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── 4. Rejected ───────────────────────────────────────────────────
  Widget _buildRejected() {
    final note = _application?['reviewer_note'] as String?;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.cancel_rounded, size: 42, color: Color(0xFFE53935)),
            ),
            const SizedBox(height: 20),
            Text('ຄຳຂໍຖືກປະຕິເສດ',
              style: GoogleFonts.notoSerifLao(fontSize: 20, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB71C1C), height: 1.4)),
              ),
            ],
            const SizedBox(height: 8),
            const Text('ທ່ານສາມາດສະໝັກໃໝ່ໄດ້ຫຼັງ 30 ວັນ',
              style: TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _application = null;
                  _state = _CreditState.noApp;
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FilbyColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('ສະໝັກໃໝ່', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: FilbyColors.success),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
        ],
      ),
    );
  }
}
