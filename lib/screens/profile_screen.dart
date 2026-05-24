import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                        'ລ',
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
                          'ຮ້ານ ລຳຄາ ກາເຟ',
                          style: GoogleFonts.notoSerifLao(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: FilbyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ສະມາຊິກຕັ້ງແຕ່ 2025',
                          style: TextStyle(fontSize: 11, color: FilbyColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: FilbyColors.warningBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '★ ລູກຄ້າໂດດ',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FilbyColors.primary),
                          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ສິນເຊື່ອທີ່ໃຊ້ໄດ້', style: TextStyle(fontSize: 11, color: Color(0x8C140A05))),
                      Text('30 ວັນ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FilbyColors.primaryDeep)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '3,150,000',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: FilbyColors.bg, letterSpacing: -0.5),
                  ),
                  const Text('ກີບ', style: TextStyle(fontSize: 12, color: Color(0x8C140A05))),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 1850000 / 5000000,
                      backgroundColor: Color(0x1A140A05),
                      valueColor: AlwaysStoppedAnimation(FilbyColors.primaryDeep),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ໃຊ້ໄປ: 1,850,000', style: TextStyle(fontSize: 10, color: Color(0x8C140A05))),
                      Text('ສູງສຸດ: 5,000,000', style: TextStyle(fontSize: 10, color: Color(0x8C140A05))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Menu group 1
            const _MenuGroup(
              items: [
                _MenuRowData(icon: Icons.store_outlined, label: 'ຂໍ້ມູນຮ້ານ'),
                _MenuRowData(icon: Icons.credit_card_outlined, label: 'ວິທີຊຳລະ', value: '···· 4218'),
                _MenuRowData(icon: Icons.notifications_outlined, label: 'ການເຕືອນ'),
                _MenuRowData(icon: Icons.language_outlined, label: 'ພາສາ', value: 'ລາວ'),
              ],
            ),
            const SizedBox(height: 10),
            const _MenuGroup(
              items: [
                _MenuRowData(icon: Icons.help_outline, label: 'ຊ່ວຍເຫຼືອ'),
                _MenuRowData(icon: Icons.logout, label: 'ອອກຈາກລະບົບ', isDestructive: true),
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

  const _MenuRowData({
    required this.icon,
    required this.label,
    this.value,
    this.isDestructive = false,
  });
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
    return GestureDetector(
      onTap: () {},
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
                color: data.isDestructive ? const Color(0xFFE85A4A) : FilbyColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: data.isDestructive ? const Color(0xFFE85A4A) : FilbyColors.textPrimary,
                ),
              ),
            ),
            if (data.value != null) ...[
              Text(data.value!, style: const TextStyle(fontSize: 12, color: FilbyColors.textMuted)),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right, size: 16, color: FilbyColors.textMuted),
          ],
        ),
      ),
    );
  }
}
