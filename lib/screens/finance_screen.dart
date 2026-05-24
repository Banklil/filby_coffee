import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _periodIndex = 1;
  final List<String> _periods = ['ມື້ນີ້', 'ອາທິດນີ້', 'ເດືອນນີ້'];

  final List<_DayData> _chartData = const [
    _DayData('ຈ', 0.50, 0.18),
    _DayData('ອ', 0.65, 0.22),
    _DayData('ພ', 0.45, 0.28),
    _DayData('ພຫ', 0.75, 0.20),
    _DayData('ສຸ', 0.90, 0.30),
    _DayData('ສ', 0.95, 0.25),
    _DayData('ອາ', 0.70, 0.18),
  ];

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
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 16),
            Text(
              'ສະຫຼຸບການເງິນ',
              style: GoogleFonts.notoSerifLao(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: FilbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Period tabs
            Row(
              children: List.generate(_periods.length, (i) {
                final active = i == _periodIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _periods.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _periodIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 36,
                        decoration: BoxDecoration(
                          color: active ? FilbyColors.cream : FilbyColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: active ? FilbyColors.cream : FilbyColors.border),
                        ),
                        child: Center(
                          child: Text(
                            _periods[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? FilbyColors.bg : FilbyColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Profit card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [FilbyColors.surface, FilbyColors.surface2],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FilbyColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('ກຳໄລສຸດທິ', style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FilbyColors.successBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '↑ +18.5%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FilbyColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '6,300,000',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: FilbyColors.success,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text('ກີບ · ທຽບກັບອາທິດແລ້ວ', style: TextStyle(fontSize: 11, color: FilbyColors.textSecondary)),
                  const SizedBox(height: 16),
                  const Divider(color: FilbyColors.border, height: 1),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: _SplitItem(
                          icon: Icons.arrow_downward,
                          iconBg: FilbyColors.successBg,
                          iconColor: FilbyColors.success,
                          label: 'ລາຍຮັບ',
                          value: '8,450,000',
                        ),
                      ),
                      Expanded(
                        child: _SplitItem(
                          icon: Icons.arrow_upward,
                          iconBg: FilbyColors.warningBg,
                          iconColor: FilbyColors.primary,
                          label: 'ລາຍຈ່າຍ',
                          value: '2,150,000',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FilbyColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FilbyColors.border),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ລາຍວັນ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
                      Row(
                        children: [
                          _Legend(color: FilbyColors.primary, label: 'ຮັບ'),
                          SizedBox(width: 10),
                          _Legend(color: Color(0x66F5E6D3), label: 'ຈ່າຍ'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _chartData.asMap().entries.map((e) {
                        final today = e.key == _chartData.length - 1;
                        return _BarGroup(data: e.value, isToday: today);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Top items
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FilbyColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FilbyColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ສິນຄ້າຂາຍດີ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
                  SizedBox(height: 14),
                  _TopItem(rank: 1, name: 'Latte', amount: '156 ຈອກ', percent: 0.85),
                  _TopItem(rank: 2, name: 'Espresso', amount: '134 ຈອກ', percent: 0.72),
                  _TopItem(rank: 3, name: 'Iced Americano', amount: '98 ຈອກ', percent: 0.53),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _DayData {
  final String label;
  final double income;
  final double expense;

  const _DayData(this.label, this.income, this.expense);
}

class _BarGroup extends StatelessWidget {
  final _DayData data;
  final bool isToday;

  const _BarGroup({required this.data, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 8,
              height: (data.income * 90).clamp(4, 90),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [FilbyColors.primary, FilbyColors.primaryDeep],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 8,
              height: (data.expense * 90).clamp(4, 90),
              decoration: const BoxDecoration(
                color: Color(0x66F5E6D3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          data.label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isToday ? FilbyColors.primary : FilbyColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SplitItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _SplitItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: FilbyColors.textSecondary)),
      ],
    );
  }
}

class _TopItem extends StatelessWidget {
  final int rank;
  final String name;
  final String amount;
  final double percent;

  const _TopItem({required this.rank, required this.name, required this.amount, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank == 1 ? FilbyColors.warningBg : FilbyColors.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: rank == 1 ? FilbyColors.primary : FilbyColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FilbyColors.textPrimary)),
                    Text(amount, style: const TextStyle(fontSize: 11, color: FilbyColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: FilbyColors.surface3,
                    valueColor: const AlwaysStoppedAnimation(FilbyColors.primary),
                    minHeight: 4,
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
