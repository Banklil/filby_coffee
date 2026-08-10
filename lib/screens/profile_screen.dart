import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/credit_terms.dart';
import 'notifications_screen.dart';
import 'shop_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _credit;
  bool _loadingCredit = true;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadCredit();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    final n = await NotificationBadge.unreadCount();
    if (mounted) setState(() => _unread = n);
  }

  Future<void> _loadCredit() async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/credits/me'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _credit = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          _loadingCredit = false;
        });
        return;
      }
    } catch (_) {
      // ປ່ອຍໃຫ້ບັດສະແດງສະຖານະ "ຍັງບໍ່ມີສິນເຊື່ອ" ແທນການລົ້ມ
    }
    if (mounted) setState(() => _loadingCredit = false);
  }

  /// ບັດສິນເຊື່ອຢູ່ໜ້າບັນຊີ. ເມື່ອກ່ອນ hardcode ເປັນ "—" ຕະຫຼອດ ຈຶ່ງຂັດກັບ
  /// ໜ້າສິນເຊື່ອທີ່ບອກວ່າອະນຸມັດແລ້ວ. ດຽວນີ້ອ່ານແຫຼ່ງດຽວກັນ.
  Widget _creditSummary() {
    if (_loadingCredit) {
      return const SizedBox(
        height: 62,
        child: Center(
          child: SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
        ),
      );
    }

    final c = _credit;
    final approved  = (c?['approved_limit'] as num? ?? 0).toDouble();
    final available = (c?['available'] as num? ?? 0).toDouble();
    final balance   = (c?['balance'] as num? ?? 0).toDouble();
    final needDep   = (c?['required_deposit'] as num? ?? 0).toDouble();
    final awaiting  = c?['awaiting_deposit'] == true;

    final String big, note;
    if (approved <= 0) {
      big = '—';
      note = 'ຍັງບໍ່ມີສິນເຊື່ອ · ສະໝັກໄດ້ໃນແທັບສິນເຊື່ອ';
    } else if (awaiting) {
      big = kip(approved);
      note = 'ອະນຸມັດແລ້ວ · ວາງມັດຈຳ ${kip(needDep)} ກີບ ຈຶ່ງໃຊ້ໄດ້';
    } else {
      big = kip(available);
      note = balance > 0
          ? 'ກີບ ສັ່ງໄດ້ອີກ · ໜີ້ຄ້າງ ${kip(balance)} ກີບ'
          : 'ກີບ ສັ່ງໄດ້ · ບໍ່ມີໜີ້ຄ້າງ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(awaiting ? 'ວົງເງິນທີ່ອະນຸມັດ' : 'ສິນເຊື່ອທີ່ໃຊ້ໄດ້',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
            Text('${CreditPolicy.graceDays} ວັນ ບໍ່ມີດອກ',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: FilbyColors.goldSoft)),
          ],
        ),
        const SizedBox(height: 4),
        Text(big,
          style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: awaiting ? Colors.white54 : Colors.white,
            letterSpacing: -0.5)),
        Text(note, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  void _showPaymentMethods(BuildContext ctx) {
    final c = _credit;
    final available = (c?['available'] as num? ?? 0).toDouble();
    final awaiting = c?['awaiting_deposit'] == true;
    _sheet(ctx, 'ວິທີຊຳລະ', [
      _sheetRow(Icons.payments_outlined, 'ເງິນສົດ',
          'ຈ່າຍຕອນຮັບເຄື່ອງ — ໃຊ້ໄດ້ທຸກເມື່ອ'),
      _sheetRow(Icons.qr_code_2, 'ໂອນຜ່ານ QR',
          'ສະແກນ QR ຂອງບໍລິສັດຕອນສັ່ງ ແລ້ວລໍທີມງານຢືນຢັນ'),
      _sheetRow(
        Icons.credit_card,
        'ສິນເຊື່ອ',
        awaiting
            ? 'ອະນຸມັດແລ້ວ ແຕ່ຕ້ອງວາງມັດຈຳກ່ອນ — ເບິ່ງລາຍລະອຽດໃນແທັບສິນເຊື່ອ'
            : available > 0
                ? 'ສັ່ງໄດ້ອີກ ${kip(available)} ກີບ · '
                    'ຊຳລະໃນ ${CreditPolicy.graceDays} ວັນ ບໍ່ມີດອກເບ້ຍ'
                : 'ຍັງບໍ່ມີວົງເງິນ — ສະໝັກໄດ້ໃນແທັບສິນເຊື່ອ',
      ),
    ]);
  }

  void _showHelp(BuildContext ctx) {
    _sheet(ctx, 'ຊ່ວຍເຫຼືອ', [
      _sheetRow(Icons.support_agent, 'ຕິດຕໍ່ທີມງານ Filby',
          'ມີບັນຫາການສັ່ງຊື້, ການຊຳລະ ຫຼື ສິນເຊື່ອ — ຕິດຕໍ່ພວກເຮົາໄດ້ເລີຍ'),
      _sheetRow(Icons.receipt_long_outlined, 'ເງື່ອນໄຂສິນເຊື່ອ',
          'ຊຳລະໃນ ${CreditPolicy.graceDays} ວັນ ບໍ່ມີດອກເບ້ຍ · '
          'ເກີນນັ້ນຄິດ ${CreditPolicy.monthlyLabel} ຕໍ່ເດືອນ '
          '(${CreditPolicy.dailyLabel} ຕໍ່ມື້)'),
      _sheetRow(Icons.info_outline, 'ລຸ້ນແອັບ', 'Filby v1.0 · 2026'),
    ]);
  }

  void _sheet(BuildContext ctx, String title, List<Widget> rows) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: FilbyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(title,
                  style: GoogleFonts.notoSerifLao(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: FilbyColors.textPrimary)),
              const SizedBox(height: 14),
              ...rows,
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: FilbyColors.surface2,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: FilbyColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.notoSansLao(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FilbyColors.textPrimary)),
                const SizedBox(height: 2),
                Text(body,
                    style: GoogleFonts.notoSansLao(
                        fontSize: 12,
                        height: 1.45,
                        color: FilbyColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final shopName = user?.shopName ?? 'ຮ້ານຂອງຂ້ອຍ';
    final email = user?.email ?? '';
    final initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : 'F';
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 16),
            Text(
              'ບັນຊີ',
              style: GoogleFonts.notoSerifLao(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: FilbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FilbyColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FilbyColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [FilbyColors.primary, FilbyColors.primaryDeep],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.notoSerifLao(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: GoogleFonts.notoSerifLao(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: FilbyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 11, color: FilbyColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Credit summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [FilbyColors.cream, FilbyColors.creamWarm],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _creditSummary(),
            ),
            const SizedBox(height: 16),
            // Menu group 1
            _MenuGroup(
              items: [
                _MenuRowData(
                  icon: Icons.store_outlined,
                  label: 'ຂໍ້ມູນຮ້ານ',
                  onTap: (ctx) async {
                    await Navigator.push(ctx,
                        MaterialPageRoute(builder: (_) => const ShopInfoScreen()));
                    // ຊື່ຮ້ານອາດປ່ຽນ — ແຕ້ມໃໝ່ໃຫ້ບັດຂ້າງເທິງຕົງກັນ
                    if (mounted) setState(() {});
                  },
                ),
                _MenuRowData(
                  icon: Icons.credit_card_outlined,
                  label: 'ວິທີຊຳລະ',
                  onTap: (ctx) async => _showPaymentMethods(ctx),
                ),
                _MenuRowData(
                  icon: Icons.notifications_outlined,
                  label: 'ການເຕືອນ',
                  badge: _unread,
                  onTap: (ctx) async {
                    await Navigator.push(ctx,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    if (mounted) setState(() => _unread = 0);
                  },
                ),
                const _MenuRowData(
                    icon: Icons.language_outlined, label: 'ພາສາ', value: 'ລາວ'),
              ],
            ),
            const SizedBox(height: 10),
            _MenuGroup(
              items: [
                _MenuRowData(
                  icon: Icons.help_outline,
                  label: 'ຊ່ວຍເຫຼືອ',
                  onTap: (ctx) async => _showHelp(ctx),
                ),
                const _MenuRowData(
                    icon: Icons.logout, label: 'ອອກຈາກລະບົບ', isDestructive: true),
              ],
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Filby v1.0 · 2026',
                style: TextStyle(fontSize: 11, color: FilbyColors.textMuted),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _MenuRowData {
  final IconData icon;
  final String label;
  final String? value;
  final bool isDestructive;

  /// ສິ່ງທີ່ຈະເກີດຂຶ້ນເມື່ອກົດ. ຖ້າ null = ຟີເຈີຍັງບໍ່ພ້ອມ — ແຖວຈະເປັນສີຈາງ
  /// ແລະ ບອກຜູ້ໃຊ້ຢ່າງຈະແຈ້ງ ແທນທີ່ຈະກົດແລ້ວງຽບໆ.
  final Future<void> Function(BuildContext)? onTap;

  /// ຈຳນວນທີ່ຍັງບໍ່ໄດ້ອ່ານ — 0 ຫຼື null = ບໍ່ສະແດງ
  final int? badge;

  const _MenuRowData({
    required this.icon,
    required this.label,
    this.value,
    this.isDestructive = false,
    this.onTap,
    this.badge,
  });

  bool get enabled => onTap != null || isDestructive;
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuRowData> items;

  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              _MenuRow(data: e.value),
              if (!isLast) const Divider(color: FilbyColors.border, height: 1, indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final _MenuRowData data;

  const _MenuRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final dim = !data.enabled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (data.isDestructive) {
          await AuthService.signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacementNamed('/login');
          }
          return;
        }
        if (data.onTap != null) {
          await data.onTap!(context);
          return;
        }
        // ບໍ່ປ່ອຍໃຫ້ກົດແລ້ວງຽບໆ — ບອກໄປເລີຍວ່າຍັງບໍ່ພ້ອມ
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${data.label} — ຍັງບໍ່ເປີດໃຫ້ໃຊ້ເທື່ອ'),
          backgroundColor: FilbyColors.navy,
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: FilbyColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                data.icon,
                size: 15,
                color: data.isDestructive
                    ? const Color(0xFFE85A4A)
                    : dim
                        ? FilbyColors.textMuted
                        : FilbyColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: data.isDestructive
                      ? const Color(0xFFE85A4A)
                      : dim
                          ? FilbyColors.textMuted
                          : FilbyColors.textPrimary,
                ),
              ),
            ),
            if ((data.badge ?? 0) > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${data.badge}',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(width: 6),
            ],
            if (data.value != null) ...[
              Text(data.value!, style: const TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
              const SizedBox(width: 4),
            ],
            if (dim)
              Text('ໄວໆນີ້',
                  style: GoogleFonts.notoSansLao(
                      fontSize: 10.5, color: FilbyColors.textMuted))
            else
              const Icon(Icons.chevron_right, size: 16, color: FilbyColors.textMuted),
          ],
        ),
      ),
    );
  }
}
