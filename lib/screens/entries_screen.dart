import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/entry_service.dart';

String _kip(num n) {
  final s = n.round().abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// ບັນຊີລາຍຮັບ-ລາຍຈ່າຍພາຍໃນຮ້ານ.
class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  int _periodIndex = 2;
  static const _periods = ['ມື້ນີ້', 'ອາທິດນີ້', 'ເດືອນນີ້', 'ທັງໝົດ'];
  static const _periodKeys = ['day', 'week', 'month', 'all'];

  EntryPage? _page;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted && _page == null) setState(() => _loading = true);
    final p = await EntryService.list(period: _periodKeys[_periodIndex]);
    if (mounted) setState(() { _page = p; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        title: Text('ລາຍຮັບ - ລາຍຈ່າຍ',
            style: GoogleFonts.notoSerifLao(
                fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: FilbyColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: Text('ບັນທຶກ',
            style: GoogleFonts.notoSansLao(
                fontSize: 14, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: List.generate(_periods.length, (i) {
                final active = i == _periodIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: i < _periods.length - 1 ? 6 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _periodIndex = i; _page = null; });
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? FilbyColors.primary
                              : FilbyColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: active
                                  ? FilbyColors.primary
                                  : FilbyColors.border),
                        ),
                        child: Text(_periods[i],
                            style: GoogleFonts.notoSansLao(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : FilbyColors.textSecondary,
                            )),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_page != null) _totals(_page!),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _totals(EntryPage p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Row(
        children: [
          _totalCell('ລາຍຮັບ', p.income, FilbyColors.success),
          Container(width: 1, height: 32, color: FilbyColors.border),
          _totalCell('ລາຍຈ່າຍ', p.expense, const Color(0xFFE53935)),
          Container(width: 1, height: 32, color: FilbyColors.border),
          _totalCell('ຄົງເຫຼືອ', p.net,
              p.net >= 0 ? FilbyColors.primary : const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _totalCell(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.notoSansLao(
                  fontSize: 11, color: FilbyColors.textMuted)),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(_kip(value),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: FilbyColors.primary));
    }
    final items = _page?.items ?? const <ShopEntry>[];
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                    color: FilbyColors.surface2, shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    size: 32, color: FilbyColors.textMuted),
              ),
              const SizedBox(height: 16),
              Text('ຍັງບໍ່ມີລາຍການ',
                  style: GoogleFonts.notoSerifLao(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FilbyColors.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'ບັນທຶກຄ່າເຊົ່າ, ຄ່າແຮງ, ຄ່ານ້ຳໄຟ ຫຼື ລາຍຮັບອື່ນ '
                'ເພື່ອໃຫ້ກຳໄລສຸດທິຖືກຕ້ອງ',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansLao(
                    fontSize: 12.5,
                    height: 1.5,
                    color: FilbyColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: FilbyColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _row(items[i]),
      ),
    );
  }

  Widget _row(ShopEntry e) {
    final color =
        e.isIncome ? FilbyColors.success : const Color(0xFFE53935);
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(e),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _openForm(existing: e),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: FilbyColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FilbyColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                    e.isIncome
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 16,
                    color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.category,
                        style: GoogleFonts.notoSansLao(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FilbyColors.textPrimary)),
                    const SizedBox(height: 1),
                    Text(
                      [e.entryDate, if (e.note?.isNotEmpty == true) e.note!]
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansLao(
                          fontSize: 11, color: FilbyColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text('${e.isIncome ? '+' : '−'}${_kip(e.amount)}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(ShopEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FilbyColors.surface,
        title: Text('ລຶບລາຍການ',
            style: GoogleFonts.notoSerifLao(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FilbyColors.textPrimary)),
        content: Text('${e.category} · ${_kip(e.amount)} ກີບ',
            style: GoogleFonts.notoSansLao(
                fontSize: 13, color: FilbyColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ຍົກເລີກ')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ລຶບ',
                  style: TextStyle(color: Color(0xFFE53935)))),
        ],
      ),
    );
    if (ok != true) return false;

    final err = await EntryService.remove(e.id);
    if (!mounted) return false;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err), backgroundColor: const Color(0xFFE74C3C)));
      return false;
    }
    await _load();
    return true;
  }

  Future<void> _openForm({ShopEntry? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntryForm(existing: existing),
    );
    if (saved == true) await _load();
  }
}

// ─────────────────────────────────────────────────────────────────────
// ຟອມບັນທຶກ / ແກ້ໄຂ
// ─────────────────────────────────────────────────────────────────────

class _EntryForm extends StatefulWidget {
  final ShopEntry? existing;
  const _EntryForm({this.existing});

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late String _type;
  String? _category;
  late DateTime _date;
  Map<String, List<String>> _cats = const {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _category = e?.category;
    _amountCtrl.text = e != null ? e.amount.toString() : '';
    _noteCtrl.text = e?.note ?? '';
    _date = e != null
        ? (DateTime.tryParse(e.entryDate) ?? DateTime.now())
        : DateTime.now();
    EntryService.categories().then((c) {
      if (mounted) setState(() => _cats = c);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<String> get _options => _cats[_type] ?? const [];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ກະລຸນາເລືອກໝວດ'),
        backgroundColor: FilbyColors.navy,
      ));
      return;
    }
    setState(() => _saving = true);

    final amount = int.parse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final dateStr = '${_date.year.toString().padLeft(4, '0')}-'
        '${_date.month.toString().padLeft(2, '0')}-'
        '${_date.day.toString().padLeft(2, '0')}';

    final err = widget.existing == null
        ? await EntryService.create(
            type: _type,
            category: _category!,
            amount: amount,
            note: _noteCtrl.text.trim(),
            entryDate: dateStr)
        : await EntryService.update(widget.existing!.id,
            category: _category,
            amount: amount,
            note: _noteCtrl.text.trim(),
            entryDate: dateStr);

    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err), backgroundColor: const Color(0xFFE74C3C)));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: FilbyColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: FilbyColors.surface3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(isEdit ? 'ແກ້ໄຂລາຍການ' : 'ບັນທຶກລາຍການ',
                    style: GoogleFonts.notoSerifLao(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: FilbyColors.textPrimary)),
                const SizedBox(height: 16),

                // ປະເພດ — ແກ້ໄຂແລ້ວປ່ຽນປະເພດບໍ່ໄດ້ ເພາະໝວດຜູກກັບປະເພດ
                if (!isEdit)
                  Row(
                    children: [
                      _typeTab('expense', 'ລາຍຈ່າຍ', const Color(0xFFE53935)),
                      const SizedBox(width: 8),
                      _typeTab('income', 'ລາຍຮັບ', FilbyColors.success),
                    ],
                  ),
                if (!isEdit) const SizedBox(height: 16),

                Text('ໝວດ',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FilbyColors.textSecondary)),
                const SizedBox(height: 8),
                if (_options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: FilbyColors.primary),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _options.map((c) {
                      final active = c == _category;
                      return GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? FilbyColors.primary
                                : FilbyColors.surface2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: active
                                    ? FilbyColors.primary
                                    : FilbyColors.border),
                          ),
                          child: Text(c,
                              style: GoogleFonts.notoSansLao(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : FilbyColors.textSecondary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 18),
                Text('ຈຳນວນເງິນ (ກີບ)',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FilbyColors.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: FilbyColors.textPrimary),
                  decoration: _dec('0'),
                  validator: (v) {
                    final digits =
                        (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isEmpty) return 'ກະລຸນາໃສ່ຈຳນວນເງິນ';
                    final n = int.tryParse(digits) ?? 0;
                    if (n <= 0) return 'ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າ 0';
                    if (n > 1000000000) return 'ຈຳນວນເງິນສູງເກີນໄປ';
                    return null;
                  },
                ),

                const SizedBox(height: 14),
                Text('ວັນທີ',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FilbyColors.textSecondary)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: FilbyColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FilbyColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: FilbyColors.textMuted),
                        const SizedBox(width: 10),
                        Text(
                            '${_date.day}/${_date.month}/${_date.year}',
                            style: const TextStyle(
                                fontSize: 14,
                                color: FilbyColors.textPrimary)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Text('ໝາຍເຫດ (ຖ້າມີ)',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FilbyColors.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  maxLength: 500,
                  style: const TextStyle(
                      fontSize: 13.5, color: FilbyColors.textPrimary),
                  decoration: _dec('ເຊັ່ນ ຈ່າຍຄ່າເຊົ່າເດືອນ 8'),
                ),

                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FilbyColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(isEdit ? 'ບັນທຶກການແກ້ໄຂ' : 'ບັນທຶກ',
                            style: GoogleFonts.notoSansLao(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String value, String label, Color color) {
    final active = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = value;
          _category = null;      // ໝວດຜູກກັບປະເພດ ຕ້ອງເລືອກໃໝ່
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : FilbyColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? color : FilbyColors.border,
                width: active ? 1.5 : 1),
          ),
          child: Text(label,
              style: GoogleFonts.notoSansLao(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: active ? color : FilbyColors.textSecondary,
              )),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: FilbyColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: FilbyColors.surface2,
        counterText: '',
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
          borderSide:
              const BorderSide(color: FilbyColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );
}
