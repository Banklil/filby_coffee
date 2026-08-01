import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _periodIndex = 1;
  final List<String> _periods = ['ມື້ນີ້', 'ອາທິດນີ້', 'ເດືອນນີ້'];
  static const List<String> _periodKeys = ['day', 'week', 'month'];

  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await AuthService.fetchSummary(_periodKeys[_periodIndex]);
    if (mounted) setState(() { _summary = s; _loading = false; });
  }

  // Convert the API weekly series into normalized bar data (fractions 0..1).
  List<_DayData> get _chartData {
    final weekly = (_summary?['weekly'] as List?) ?? const [];
    if (weekly.isEmpty) {
      return const [
        _DayData('ຈ', 0, 0), _DayData('ອ', 0, 0), _DayData('ພ', 0, 0),
        _DayData('ພຫ', 0, 0), _DayData('ສຸ', 0, 0), _DayData('ສ', 0, 0),
        _DayData('ອາ', 0, 0),
      ];
    }
    double maxV = 1;
    for (final d in weekly) {
      final inc = (d['income'] as num?)?.toDouble() ?? 0;
      final exp = (d['expense'] as num?)?.toDouble() ?? 0;
      if (inc > maxV) maxV = inc;
      if (exp > maxV) maxV = exp;
    }
    return weekly.map<_DayData>((d) {
      final inc = (d['income'] as num?)?.toDouble() ?? 0;
      final exp = (d['expense'] as num?)?.toDouble() ?? 0;
      return _DayData((d['label'] as String?) ?? '', inc / maxV, exp / maxV);
    }).toList();
  }

  double get _income => (_summary?['income'] as num?)?.toDouble() ?? 0;
  double get _expense => (_summary?['expense'] as num?)?.toDouble() ?? 0;
  double get _netProfit => (_summary?['net_profit'] as num?)?.toDouble() ?? 0;
  int get _salesCount => (_summary?['sales_count'] as num?)?.toInt() ?? 0;

  String _fmt(num n0) {
    final s = n0.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  List<Widget> _buildTopItems() {
    final items = (_summary?['top_items'] as List?) ?? const [];
    if (items.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_loading ? '…' : 'ຍັງບໍ່ມີຂໍ້ມູນ',
                style: const TextStyle(fontSize: 13, color: FilbyColors.textMuted)),
          ),
        ),
      ];
    }
    final maxRev = items.fold<double>(1, (m, e) {
      final r = (e['revenue'] as num?)?.toDouble() ?? 0;
      return r > m ? r : m;
    });
    return [
      for (int i = 0; i < items.length; i++)
        _TopItem(
          rank: i + 1,
          name: (items[i]['name'] as String?) ?? '—',
          amount: '${_fmt((items[i]['revenue'] as num?)?.toDouble() ?? 0)} ກີບ',
          percent: ((items[i]['revenue'] as num?)?.toDouble() ?? 0) / maxRev,
        ),
    ];
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
                      onTap: () { setState(() => _periodIndex = i); _load(); },
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
                  const Row(
                    children: [
                      Text('ກຳໄລສຸດທິ', style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loading
                        ? '…'
                        : (_summary == null ? '—' : _fmt(_netProfit)),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _netProfit < 0 ? const Color(0xFFEF4444) : FilbyColors.success,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    _summary == null ? 'ກີບ · ຍັງບໍ່ມີຂໍ້ມູນ' : 'ກີບ · ຂາຍ ${_salesCount} ລາຍການ',
                    style: const TextStyle(fontSize: 11, color: FilbyColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: FilbyColors.border, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SplitItem(
                          icon: Icons.arrow_downward,
                          iconBg: FilbyColors.successBg,
                          iconColor: FilbyColors.success,
                          label: 'ລາຍຮັບ',
                          value: _summary == null ? '—' : _fmt(_income),
                        ),
                      ),
                      Expanded(
                        child: _SplitItem(
                          icon: Icons.arrow_upward,
                          iconBg: FilbyColors.warningBg,
                          iconColor: FilbyColors.primary,
                          label: 'ລາຍຈ່າຍ',
                          value: _summary == null ? '—' : _fmt(_expense),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ສິນຄ້າຂາຍດີ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
                  const SizedBox(height: 14),
                  ..._buildTopItems(),
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
