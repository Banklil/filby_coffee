import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'pos_screen.dart';
import 'credit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.7, -0.9),
                radius: 1.0,
                colors: [Color(0x1AE8854A), FilbyColors.bg],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildAlertCard(context),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 20),
                _buildSectionTitle('ທຸ່ມລັດ'),
                const SizedBox(height: 10),
                _buildQuickActions(context),
                const SizedBox(height: 20),
                _buildSectionTitle('ສະຕັອກໃກ້ໝົດ'),
                const SizedBox(height: 10),
                _buildStockList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [FilbyColors.primary, FilbyColors.primaryDeep],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('f', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ສະບາຍດີ,', style: TextStyle(fontSize: 11, color: FilbyColors.textSecondary)),
            Text(
              'ຮ້ານ ລຳຄາ ກາເຟ',
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
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.notifications_outlined, size: 18, color: FilbyColors.textPrimary),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: FilbyColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: FilbyColors.bg, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FilbyColors.cream, FilbyColors.creamWarm],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ ການເຕືອນອັດສະລິດ',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FilbyColors.primaryDeep),
          ),
          const SizedBox(height: 4),
          Text(
            'ກາເຟຈະໝົດໃນ 3 ມື້',
            style: GoogleFonts.notoSerifLao(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FilbyColors.bg,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'ຄວນສັ່ງໃຫ້ທ່ານໝ 8 ກິໂລ',
            style: TextStyle(fontSize: 11, color: Color(0x8C140A05)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: FilbyColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              elevation: 0,
            ),
            child: const Text('ສັ່ງຊື້ດ່ວນ →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return const Row(
      children: [
        Expanded(child: _StatCard(label: 'ລາຍໄດ້ເດືອນ', value: '3,945,000', sub: '↑ 12%', subColor: FilbyColors.success)),
        SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'ສິນເຊື່ອໃຊ້ໄດ້', value: '3,150,000', sub: '/ 5M ກີບ', valueColor: FilbyColors.primary)),
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

  Widget _buildStockList() {
    return const Column(
      children: [
        _StockItem(emoji: '☕', name: 'ກໍ່ລະແວກ ອາຣາບິກາ', amount: '4 kg', percent: 0.35),
        SizedBox(height: 8),
        _StockItem(emoji: '🥛', name: 'ນົມຂາ້ວ', amount: '3 L', percent: 0.20),
        SizedBox(height: 8),
        _StockItem(emoji: '🍫', name: 'ຊັອກໂກແລດ', amount: '500g', percent: 0.55),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? subColor;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.subColor,
    this.valueColor,
  });

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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor ?? FilbyColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: subColor ?? FilbyColors.textMuted),
          ),
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

  const _QuickTile({
    required this.label,
    required this.icon,
    this.featured = false,
    this.onTap,
  });

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

class _StockItem extends StatelessWidget {
  final String emoji;
  final String name;
  final String amount;
  final double percent;

  const _StockItem({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor = percent < 0.3
        ? const Color(0xFFE85A4A)
        : percent < 0.5
            ? FilbyColors.primary
            : FilbyColors.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FilbyColors.surface2,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                      amount,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: FilbyColors.surface3,
                    valueColor: AlwaysStoppedAnimation(barColor),
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
