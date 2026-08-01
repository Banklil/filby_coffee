import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';

/// ປະຫວັດການຂາຍ — per-menu sales totals + recent transactions.
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  int _periodIndex = 2;
  static const _periods = ['ມື້ນີ້', 'ອາທິດນີ້', 'ເດືອນນີ້', 'ທັງໝົດ'];
  static const _periodKeys = ['day', 'week', 'month', 'all'];

  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await AuthService.fetchSales(_periodKeys[_periodIndex]);
    if (mounted) setState(() { _data = d; _loading = false; });
  }

  String _fmt(num n0) {
    final s = n0.round().toString();
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

  @override
  Widget build(BuildContext context) {
    final byItem = (_data?['by_item'] as List?) ?? const [];
    final recent = (_data?['recent'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        elevation: 0,
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
        title: Text('ປະຫວັດການຂາຍ',
            style: GoogleFonts.notoSerifLao(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: FilbyColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 4),
            _periodTabs(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: FilbyColors.primary)),
              )
            else ...[
              _sectionTitle('ຂາຍຕາມເມນູ'),
              const SizedBox(height: 10),
              _byItemCard(byItem),
              const SizedBox(height: 20),
              _sectionTitle('ລາຍການຂາຍລ່າສຸດ'),
              const SizedBox(height: 10),
              _recentCard(recent),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 12, color: FilbyColors.textSecondary, fontWeight: FontWeight.w600));

  Widget _periodTabs() {
    return Row(
      children: List.generate(_periods.length, (i) {
        final active = i == _periodIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _periods.length - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: () { setState(() => _periodIndex = i); _load(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 34,
                decoration: BoxDecoration(
                  color: active ? FilbyColors.cream : FilbyColors.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: active ? FilbyColors.cream : FilbyColors.border),
                ),
                child: Center(
                  child: Text(_periods[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? FilbyColors.bg : FilbyColors.textSecondary,
                      )),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _byItemCard(List items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilbyColors.border),
      ),
      child: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('ຍັງບໍ່ມີການຂາຍ',
                    style: TextStyle(fontSize: 13, color: FilbyColors.textMuted)),
              ),
            )
          : Column(
              children: [
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((it['name'] as String?) ?? '—',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: FilbyColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text('${_fmt((it['qty'] as num?) ?? 0)} ຈອກ',
                                  style: const TextStyle(fontSize: 11, color: FilbyColors.textMuted)),
                            ],
                          ),
                        ),
                        Text('${_fmt((it['revenue'] as num?) ?? 0)} ກີບ',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FilbyColors.primary)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _recentCard(List recent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilbyColors.border),
      ),
      child: recent.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('ຍັງບໍ່ມີລາຍການ',
                    style: TextStyle(fontSize: 13, color: FilbyColors.textMuted)),
              ),
            )
          : Column(
              children: [
                for (final s in recent) _recentRow(s as Map<String, dynamic>),
              ],
            ),
    );
  }

  Widget _recentRow(Map<String, dynamic> s) {
    final items = (s['items'] as List?) ?? const [];
    final label = items
        .whereType<Map>()
        .map((it) => '${it['name']}×${it['qty']}')
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: FilbyColors.surface2, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.receipt_long_outlined, size: 16, color: FilbyColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.isEmpty ? 'ຂາຍ' : label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: FilbyColors.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(_time(s['created_at'] as String?),
                    style: const TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${_fmt((s['amount'] as num?) ?? 0)} ກີບ',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
        ],
      ),
    );
  }
}
