import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'pos_screen.dart';
import 'credit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopName = AuthService.currentUser?.shopName ?? 'ຮ້ານຂອງຂ້ອຍ';

    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.7, -0.9),
                radius: 1.0,
                colors: [Color(0x1AC4963C), FilbyColors.bg],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                _buildHeader(context, shopName),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 20),
                _buildSectionTitle('ທຸ່ມລັດ'),
                const SizedBox(height: 10),
                _buildQuickActions(context),
                const SizedBox(height: 20),
                _buildSectionTitle('ສະຕັອກໃກ້ໝົດ'),
                const SizedBox(height: 10),
                _buildEmptyStock(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String shopName) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ສະບາຍດີ,', style: TextStyle(fontSize: 11, color: FilbyColors.textSecondary)),
            Text(
              shopName,
              style: GoogleFonts.notoSerifLao(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: FilbyColors.textPrimary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: FilbyColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FilbyColors.border),
          ),
          child: const Center(
            child: Icon(Icons.notifications_outlined, size: 18, color: FilbyColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return const Row(
      children: [
        Expanded(child: _StatCard(label: 'ລາຍໄດ້ເດືອນ', value: '—', sub: 'ກີບ')),
        SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'ຍອດສັ່ງຊື້', value: '—', sub: 'ລາຍການ')),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, color: FilbyColors.textSecondary, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            label: 'POS',
            icon: Icons.point_of_sale,
            featured: true,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: _QuickTile(label: 'ສະຫຼຸບ', icon: Icons.bar_chart_outlined)),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickTile(
            label: 'ສິນເຊື່ອ',
            icon: Icons.credit_card_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditScreen())),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: _QuickTile(label: 'ລາຍງານ', icon: Icons.description_outlined)),
      ],
    );
  }

  Widget _buildEmptyStock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FilbyColors.border),
      ),
      child: const Center(
        child: Text(
          'ຍັງບໍ່ມີຂໍ້ມູນສະຕັອກ',
          style: TextStyle(fontSize: 13, color: FilbyColors.textMuted),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? valueColor;

  const _StatCard({required this.label, required this.value, required this.sub, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: FilbyColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: valueColor ?? FilbyColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: FilbyColors.textMuted)),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool featured;
  final VoidCallback? onTap;

  const _QuickTile({required this.label, required this.icon, this.featured = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          gradient: featured
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [FilbyColors.primary, FilbyColors.primaryDeep],
                )
              : null,
          color: featured ? null : FilbyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: featured ? null : Border.all(color: FilbyColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: featured ? Colors.white : FilbyColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: featured ? Colors.white : FilbyColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
