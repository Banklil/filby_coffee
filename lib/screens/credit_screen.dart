import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  double _amount = 800000;
  int _purposeIndex = 0;
  final double _maxCredit = 3150000;

  final List<String> _purposes = ['ຊື້ໝັ້ນກາເຟ', 'ອຸປະກອນ', 'ຮັບເງິນສົດ'];

  String _fmt(double n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
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
        title: const Text('ກຳລັງສິນເຊື່ອ'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Credit hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [FilbyColors.cream, FilbyColors.creamWarm],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmt(_maxCredit),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: FilbyColors.bg,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ສິນເຊື່ອທີ່ມີ · ຊຳລະພາຍໃນ 30 ວັນ',
                  style: TextStyle(fontSize: 11, color: Color(0x8C140A05)),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 1850000 / 5000000,
                    backgroundColor: Color(0x1A140A05),
                    valueColor: AlwaysStoppedAnimation(FilbyColors.primaryDeep),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1,850,000', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0x8C140A05))),
                    Text('5,000,000', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0x8C140A05))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount selector
          const Text('ຈຳນວນທີ່ຕ້ອງການ', style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _fmt(_amount),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: FilbyColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text('ກີບ', style: TextStyle(fontSize: 14, color: FilbyColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FilbyColors.primary,
              inactiveTrackColor: FilbyColors.surface2,
              thumbColor: FilbyColors.primary,
              overlayColor: FilbyColors.primary.withOpacity(0.1),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _amount,
              min: 100000,
              max: _maxCredit,
              divisions: 30,
              onChanged: (v) => setState(() => _amount = v),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('100,000', style: TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
              Text('3,150,000', style: TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
            ],
          ),
          const SizedBox(height: 24),

          // Purpose
          const Text('ຈຸດປະສົງ', style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_purposes.length, (i) {
              final active = i == _purposeIndex;
              return GestureDetector(
                onTap: () => setState(() => _purposeIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? FilbyColors.cream : FilbyColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? FilbyColors.cream : FilbyColors.border),
                  ),
                  child: Text(
                    _purposes[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? FilbyColors.bg : FilbyColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Terms box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FilbyColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FilbyColors.primary.withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ເງື່ອນໄຂ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FilbyColors.primary)),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: FilbyColors.success),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ຊຳລະຄືນໃນ 30 ວັນ ບໍ່ມີດອກເບ້ຍ',
                        style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _showSuccess(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: FilbyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('ສ້າງຄຳສັ່ງ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FilbyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: FilbyColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: FilbyColors.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'ສຳເລັດ!',
              style: GoogleFonts.notoSerifLao(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: FilbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ຄຳສັ່ງຊື້ໄດ້ຮັບການຢືນຢັນແລ້ວ\nຊຳລະພາຍໃນ 30 ວັນ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: FilbyColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FilbyColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ກັບໜ້າຫຼັກ', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
