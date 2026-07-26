import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class ShopInfoScreen extends StatelessWidget {
  const ShopInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        title: Text('ຂໍ້ມູນຮ້ານ', style: GoogleFonts.notoSerifLao(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Shop logo
          Center(
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: FilbyColors.primary.withValues(alpha: 0.2), blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(items: [
            _InfoRow(label: 'ຊື່ຮ້ານ', value: user?.shopName ?? '—'),
            _InfoRow(label: 'Email', value: user?.email ?? '—'),
            _InfoRow(label: 'ລະຫັດຮ້ານ', value: '#${user?.id ?? '—'}'),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FilbyColors.warningBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FilbyColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: FilbyColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ເພື່ອແກ້ໄຂຂໍ້ມູນຮ້ານ ກະລຸນາເຂົ້າ web dashboard ຂອງ Filby Coffee',
                    style: TextStyle(fontSize: 12, color: FilbyColors.textSecondary),
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

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) => Column(
          children: [
            _InfoRowWidget(row: e.value),
            if (e.key < items.length - 1) const Divider(color: FilbyColors.border, height: 1, indent: 16),
          ],
        )).toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
}

class _InfoRowWidget extends StatelessWidget {
  final _InfoRow row;
  const _InfoRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(row.label, style: const TextStyle(fontSize: 13, color: FilbyColors.textSecondary)),
          Text(row.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FilbyColors.textPrimary)),
        ],
      ),
    );
  }
}
