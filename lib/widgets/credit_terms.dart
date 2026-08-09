import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// ນະໂຍບາຍສິນເຊື່ອ — ແກ້ຄ່າຢູ່ບ່ອນນີ້ບ່ອນດຽວ ແລ້ວທຸກໜ້າຈະປ່ຽນຕາມ.
class CreditPolicy {
  /// ຈຳນວນມື້ທີ່ບໍ່ຄິດດອກເບ້ຍ ນັບຈາກວັນຮັບເຄື່ອງ.
  static const int graceDays = 30;

  /// ດອກເບ້ຍຫຼັງພົ້ນກຳນົດ — ຄິດເປັນຕໍ່ເດືອນ.
  static const double monthlyRate = 0.03;

  /// ຊ້າເກີນນີ້ → ສັ່ງເຄື່ອງໃໝ່ບໍ່ໄດ້ຈົນກວ່າຈະຊຳລະ.
  static const int blockAfterDays = 15;

  /// ຊ້າເກີນນີ້ → ລະງັບບັນຊີ ແລະ ສົ່ງເລື່ອງໃຫ້ຝ່າຍຕິດຕາມໜີ້.
  static const int suspendAfterDays = 45;

  /// ມັດຈຳທີ່ຕ້ອງວາງ ຄິດເປັນ % ຂອງວົງເງິນ.
  static const double depositPercent = 0.50;

  /// ດອກເບ້ຍຕໍ່ມື້ — ໃຊ້ຄິດຕົວຈິງ ເພື່ອໃຫ້ຈ່າຍໄວແລ້ວດອກໜ້ອຍລົງ.
  static double get dailyRate => monthlyRate / 30;

  static String get monthlyLabel {
    // 0.03 * 100 ໃຫ້ 3.0000000000000004 — ປັດກ່ອນ ບໍ່ດັ່ງນັ້ນຈະອອກເປັນ "3.0%"
    final pct = (monthlyRate * 1000).round() / 10;
    return pct == pct.truncateToDouble()
        ? '${pct.toInt()}%'
        : '${pct.toStringAsFixed(1)}%';
  }

  static String get dailyLabel => '${(dailyRate * 100).toStringAsFixed(2)}%';

  static String get depositLabel =>
      '${(depositPercent * 100).toStringAsFixed(0)}%';

  /// ດອກເບ້ຍທີ່ຕ້ອງຈ່າຍ ຖ້າຊຳລະໃນມື້ທີ [dayPaid] ນັບຈາກວັນຮັບເຄື່ອງ.
  static int interestFor(num principal, int dayPaid) {
    final lateDays = dayPaid - graceDays;
    if (lateDays <= 0) return 0;
    return (principal * dailyRate * lateDays).round();
  }
}

String kip(num n) {
  final s = n.round().abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ─────────────────────────────────────────────────────────────────────
// ບັດສະຫຼຸບເງື່ອນໄຂ — ໃສ່ໃນໜ້າສະໝັກ ແລະ ໜ້າອະນຸມັດແລ້ວ
// ─────────────────────────────────────────────────────────────────────

class CreditTermsCard extends StatelessWidget {
  /// ຍອດຕົວຢ່າງທີ່ໃຊ້ສະແດງການຄິດດອກ. ຖ້າບໍ່ໃສ່ ຈະໃຊ້ 2,000,000.
  final num exampleAmount;

  const CreditTermsCard({super.key, this.exampleAmount = 2000000});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 18, color: FilbyColors.primary),
              const SizedBox(width: 8),
              Text(
                'ເງື່ອນໄຂ ແລະ ດອກເບ້ຍ',
                style: GoogleFonts.notoSerifLao(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: FilbyColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ອ່ານໃຫ້ເຂົ້າໃຈກ່ອນໃຊ້ສິນເຊື່ອ',
            style: GoogleFonts.notoSansLao(
              fontSize: 12,
              color: FilbyColors.textMuted,
            ),
          ),

          const SizedBox(height: 18),
          const _GraceTimeline(),

          const SizedBox(height: 18),
          _ExampleBlock(amount: exampleAmount),

          const SizedBox(height: 16),
          const _RuleList(),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showCreditTermsSheet(context),
              icon: const Icon(Icons.article_outlined, size: 16),
              label: Text(
                'ອ່ານເງື່ອນໄຂສະບັບເຕັມ',
                style: GoogleFonts.notoSansLao(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: FilbyColors.primary,
                side: const BorderSide(color: FilbyColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ແຖບເວລາ: ຟຣີ 30 ມື້ → ຫຼັງຈາກນັ້ນຄິດດອກ ──────────────────────────

class _GraceTimeline extends StatelessWidget {
  const _GraceTimeline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 30,
              child: _TimelineSegment(
                title: 'ມື້ 1 – ${CreditPolicy.graceDays}',
                big: '0%',
                caption: 'ບໍ່ມີດອກເບ້ຍ',
                color: FilbyColors.success,
                background: FilbyColors.successBg,
                radius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              flex: 22,
              child: _TimelineSegment(
                title: 'ມື້ ${CreditPolicy.graceDays + 1} ຂຶ້ນໄປ',
                big: CreditPolicy.monthlyLabel,
                caption: 'ຕໍ່ເດືອນ',
                color: FilbyColors.gold,
                background: FilbyColors.warningBg,
                radius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 13, color: FilbyColors.textMuted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'ນັບມື້ຈາກວັນທີ່ຮັບເຄື່ອງ',
                style: GoogleFonts.notoSansLao(
                    fontSize: 11, color: FilbyColors.textMuted),
              ),
            ),
            Text(
              '= ${CreditPolicy.dailyLabel} ຕໍ່ມື້',
              style: GoogleFonts.notoSansLao(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: FilbyColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineSegment extends StatelessWidget {
  final String title;
  final String big;
  final String caption;
  final Color color;
  final Color background;
  final BorderRadius radius;

  const _TimelineSegment({
    required this.title,
    required this.big,
    required this.caption,
    required this.color,
    required this.background,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansLao(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: FilbyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            big,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          Text(
            caption,
            style: GoogleFonts.notoSansLao(
              fontSize: 10.5,
              color: FilbyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ຕົວຢ່າງການຄິດເງິນ ─────────────────────────────────────────────────

class _ExampleBlock extends StatelessWidget {
  final num amount;
  const _ExampleBlock({required this.amount});

  @override
  Widget build(BuildContext context) {
    const late1 = 10;
    const late2 = 30;
    final d1 = CreditPolicy.graceDays;
    final d2 = CreditPolicy.graceDays + late1;
    final d3 = CreditPolicy.graceDays + late2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FilbyColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ຕົວຢ່າງ: ຮັບເຄື່ອງ ${kip(amount)} ກີບ',
            style: GoogleFonts.notoSansLao(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: FilbyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _ExampleRow(
            label: 'ຈ່າຍໃນມື້ທີ $d1',
            sublabel: 'ຕົງກຳນົດ',
            interest: 0,
            total: amount,
            good: true,
          ),
          const Divider(height: 16, color: FilbyColors.border),
          _ExampleRow(
            label: 'ຈ່າຍໃນມື້ທີ $d2',
            sublabel: 'ຊ້າ $late1 ມື້',
            interest: CreditPolicy.interestFor(amount, d2),
            total: amount + CreditPolicy.interestFor(amount, d2),
            good: false,
          ),
          const Divider(height: 16, color: FilbyColors.border),
          _ExampleRow(
            label: 'ຈ່າຍໃນມື້ທີ $d3',
            sublabel: 'ຊ້າ $late2 ມື້',
            interest: CreditPolicy.interestFor(amount, d3),
            total: amount + CreditPolicy.interestFor(amount, d3),
            good: false,
          ),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final int interest;
  final num total;
  final bool good;

  const _ExampleRow({
    required this.label,
    required this.sublabel,
    required this.interest,
    required this.total,
    required this.good,
  });

  @override
  Widget build(BuildContext context) {
    final accent = good ? FilbyColors.success : FilbyColors.gold;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(good ? Icons.check_circle : Icons.access_time_filled,
            size: 15, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansLao(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FilbyColors.textPrimary,
                ),
              ),
              Text(
                sublabel,
                style: GoogleFonts.notoSansLao(
                    fontSize: 10.5, color: FilbyColors.textMuted),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${kip(total)} ກີບ',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: FilbyColors.textPrimary,
              ),
            ),
            Text(
              interest == 0 ? 'ບໍ່ມີດອກເບ້ຍ' : 'ດອກເບ້ຍ ${kip(interest)}',
              style: GoogleFonts.notoSansLao(fontSize: 10.5, color: accent),
            ),
          ],
        ),
      ],
    );
  }
}

// ── ຂໍ້ຄວນຮູ້ ─────────────────────────────────────────────────────────

class _RuleList extends StatelessWidget {
  const _RuleList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RuleRow(
          icon: Icons.savings_outlined,
          text:
              'ຈ່າຍກ່ອນກຳນົດໄດ້ທຸກເມື່ອ ບໍ່ມີຄ່າປັບ ແລະ ດອກເບ້ຍຄິດຕາມມື້ຈິງ',
        ),
        _RuleRow(
          icon: Icons.lock_outline,
          text:
              'ວາງມັດຈຳ ${CreditPolicy.depositLabel} ຂອງວົງເງິນ — ຄືນເຕັມເມື່ອປິດບັນຊີ',
        ),
        _RuleRow(
          icon: Icons.pause_circle_outline,
          text:
              'ຊ້າເກີນ ${CreditPolicy.blockAfterDays} ມື້ ຈະສັ່ງເຄື່ອງໃໝ່ບໍ່ໄດ້ຈົນກວ່າຈະຊຳລະ',
        ),
        _RuleRow(
          icon: Icons.block_outlined,
          text:
              'ຊ້າເກີນ ${CreditPolicy.suspendAfterDays} ມື້ ບັນຊີຈະຖືກລະງັບ',
          warn: true,
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warn;
  const _RuleRow({required this.icon, required this.text, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 15,
              color: warn ? FilbyColors.gold : FilbyColors.textMuted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansLao(
                fontSize: 12,
                height: 1.45,
                color: FilbyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// ເງື່ອນໄຂສະບັບເຕັມ
// ─────────────────────────────────────────────────────────────────────

void showCreditTermsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: FilbyColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: FilbyColors.surface3,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ເງື່ອນໄຂການໃຊ້ສິນເຊື່ອ',
                    style: GoogleFonts.notoSerifLao(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FilbyColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, size: 20),
                  color: FilbyColors.textMuted,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FilbyColors.border),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              children: [
                const _Clause(
                  n: '1',
                  title: 'ໄລຍະປອດດອກເບ້ຍ',
                  body:
                      'ທ່ານມີເວລາ ${CreditPolicy.graceDays} ມື້ ນັບຈາກວັນທີ່ຮັບເຄື່ອງ '
                      'ເພື່ອຊຳລະເຕັມຈຳນວນ ໂດຍບໍ່ມີດອກເບ້ຍ ແລະ ບໍ່ມີຄ່າທຳນຽມໃດໆ. '
                      'ຖ້າຊຳລະພາຍໃນໄລຍະນີ້ ທ່ານຈ່າຍພຽງລາຄາສິນຄ້າເທົ່ານັ້ນ.',
                ),
                _Clause(
                  n: '2',
                  title: 'ດອກເບ້ຍຫຼັງພົ້ນກຳນົດ',
                  // ໝາຍເຫດ: ບໍ່ໃສ່ const ຍ້ອນອ້າງອີງ getter ຂອງ CreditPolicy
                  body:
                      'ຖ້າຍັງບໍ່ຊຳລະເມື່ອຄົບ ${CreditPolicy.graceDays} ມື້ '
                      'ຈະເລີ່ມຄິດດອກເບ້ຍໃນອັດຕາ ${CreditPolicy.monthlyLabel} ຕໍ່ເດືອນ '
                      '(ເທົ່າກັບ ${CreditPolicy.dailyLabel} ຕໍ່ມື້) ຄິດຈາກຍອດຄ້າງຊຳລະ. '
                      'ດອກເບ້ຍຄິດເປັນລາຍມື້ — ຈ່າຍໄວເທົ່າໃດ ດອກເບ້ຍໜ້ອຍລົງເທົ່ານັ້ນ.',
                ),
                _Clause(
                  n: '3',
                  title: 'ວິທີຄິດດອກເບ້ຍ',
                  body:
                      'ດອກເບ້ຍ = ຍອດຄ້າງ × ${CreditPolicy.dailyLabel} × ຈຳນວນມື້ທີ່ຊ້າ\n\n'
                      'ຕົວຢ່າງ: ຄ້າງ 2,000,000 ກີບ ຊ້າ 10 ມື້\n'
                      '= 2,000,000 × 0.10% × 10 = 20,000 ກີບ\n'
                      'ລວມທີ່ຕ້ອງຈ່າຍ = 2,020,000 ກີບ',
                ),
                _Clause(
                  n: '4',
                  title: 'ການຊຳລະກ່ອນກຳນົດ',
                  body:
                      'ຊຳລະບາງສ່ວນ ຫຼື ເຕັມຈຳນວນກ່ອນກຳນົດໄດ້ທຸກເມື່ອ '
                      'ໂດຍບໍ່ມີຄ່າປັບ. ເງິນທີ່ຊຳລະຈະຖືກນຳໄປຫັກໃບບິນທີ່ເກົ່າທີ່ສຸດກ່ອນ.',
                ),
                _Clause(
                  n: '5',
                  title: 'ເງິນມັດຈຳ',
                  body:
                      'ຕ້ອງວາງມັດຈຳ ${CreditPolicy.depositLabel} ຂອງວົງເງິນທີ່ໄດ້ຮັບອະນຸມັດ. '
                      'ເງິນມັດຈຳຖືກເກັບແຍກຕ່າງຫາກ ບໍ່ໄດ້ນຳໄປຫັກໜີ້ໃນການຊຳລະປົກກະຕິ '
                      'ແລະ ຈະຄືນໃຫ້ເຕັມຈຳນວນເມື່ອທ່ານປິດບັນຊີສິນເຊື່ອ ແລະ ຊຳລະໜີ້ຄົບແລ້ວ '
                      '(ພາຍໃນ 30 ມື້ຫຼັງປິດບັນຊີ).',
                ),
                _Clause(
                  n: '6',
                  title: 'ການລະງັບການສັ່ງຊື້',
                  body:
                      'ຄ້າງຊຳລະເກີນ ${CreditPolicy.blockAfterDays} ມື້ — '
                      'ຈະບໍ່ສາມາດສັ່ງເຄື່ອງດ້ວຍສິນເຊື່ອໄດ້ຈົນກວ່າຈະຊຳລະຍອດຄ້າງ '
                      '(ຍັງສັ່ງດ້ວຍເງິນສົດ ຫຼື QR ໄດ້ຕາມປົກກະຕິ).\n\n'
                      'ຄ້າງຊຳລະເກີນ ${CreditPolicy.suspendAfterDays} ມື້ — '
                      'ບັນຊີສິນເຊື່ອຈະຖືກລະງັບທັງໝົດ ແລະ ຄຳສັ່ງທີ່ຍັງບໍ່ໄດ້ສົ່ງຈະຖືກຍົກເລີກ.',
                ),
                _Clause(
                  n: '7',
                  title: 'ການຜິດນັດຊຳລະ',
                  body:
                      'ຄ້າງຊຳລະເກີນ 60 ມື້ ຖືວ່າຜິດນັດຊຳລະ. ບໍລິສັດມີສິດນຳເງິນມັດຈຳ '
                      'ມາຫັກລົບໜີ້ຄ້າງ ແລະ ດຳເນີນການຕິດຕາມທວງໜີ້ສ່ວນທີ່ຍັງເຫຼືອ.',
                ),
                _Clause(
                  n: '8',
                  title: 'ການທົບທວນວົງເງິນ',
                  body:
                      'ບໍລິສັດຈະທົບທວນວົງເງິນທຸກ 3 ເດືອນ. ຮ້ານທີ່ຊຳລະຕົງເວລາຢ່າງສະໝ່ຳສະເໝີ '
                      'ອາດໄດ້ຮັບການເພີ່ມວົງເງິນ ຫຼື ຫຼຸດອັດຕາມັດຈຳ.',
                ),
                _Clause(
                  n: '9',
                  title: 'ການແຈ້ງເຕືອນ',
                  body:
                      'ທ່ານຈະໄດ້ຮັບການແຈ້ງເຕືອນກ່ອນຄົບກຳນົດ 7 ມື້, ໃນມື້ຄົບກຳນົດ, '
                      'ແລະ ທຸກ 7 ມື້ຫຼັງຈາກນັ້ນຖ້າຍັງບໍ່ຊຳລະ.',
                ),
                const SizedBox(height: 8),
                const _ContactNote(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Clause extends StatelessWidget {
  final String n;
  final String title;
  final String body;
  const _Clause({required this.n, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FilbyColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  n,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: FilbyColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSerifLao(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FilbyColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              body,
              style: GoogleFonts.notoSansLao(
                fontSize: 12.5,
                height: 1.6,
                color: FilbyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactNote extends StatelessWidget {
  const _ContactNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FilbyColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.support_agent, size: 18, color: FilbyColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ມີຄຳຖາມ ຫຼື ຕ້ອງການຂໍຜ່ອນຜັນ? ຕິດຕໍ່ທີມງານກ່ອນຄົບກຳນົດ '
              'ພວກເຮົາຍິນດີຊ່ວຍຫາທາງອອກຮ່ວມກັນ.',
              style: GoogleFonts.notoSansLao(
                fontSize: 12,
                height: 1.5,
                color: FilbyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
