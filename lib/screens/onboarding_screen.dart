import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'main_nav.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_OnbData> _pages = const [
    _OnbData(
      title: 'ຊື້ກ່ອນ ຈ່າຍທຳຫຼັງ',
      subtitle: 'ສິນເຊື່ອ 30 ວັນ ສຳລັບລູກຄ້າຂາຈຳ',
      amount: '5,000,000',
      icon: Icons.credit_card,
    ),
    _OnbData(
      title: 'POS ຂາຍງ່າຍ ໄວ',
      subtitle: 'ເລືອກເມນູ ສະຫຼຸບ ຮັບເງິນ ໃນ 3 tap',
      amount: '1,250,000',
      icon: Icons.point_of_sale,
    ),
    _OnbData(
      title: 'ສະຫຼຸບການເງິນ',
      subtitle: 'ລາຍໄດ້ ລາຍຈ່າຍ ກຳໄລ ທຸກວັນ',
      amount: '6,300,000',
      icon: Icons.bar_chart,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToMain();
    }
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNav()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.8),
                radius: 1.2,
                colors: [Color(0x1AE8854A), FilbyColors.bg],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _LogoBadge(),
                          const SizedBox(width: 10),
                          Text(
                            'Filby Coffee',
                            style: GoogleFonts.notoSerifLao(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: FilbyColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _goToMain,
                        child: const Text(
                          'ຂ້າມ',
                          style: TextStyle(
                            fontSize: 13,
                            color: FilbyColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _OnbPage(data: _pages[i]),
                  ),
                ),

                // Dots + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active ? FilbyColors.primary : FilbyColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FilbyColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _page < _pages.length - 1 ? 'ຕໍ່ໄປ' : 'ເລີ່ມໃຊ້ງານ',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _OnbData {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;

  const _OnbData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });
}

class _OnbPage extends StatelessWidget {
  final _OnbData data;

  const _OnbPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Credit card illustration
          Stack(
            alignment: Alignment.center,
            children: [
              // Back card
              Transform.rotate(
                angle: -0.12,
                child: Container(
                  width: 200,
                  height: 126,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [FilbyColors.cream, FilbyColors.creamWarm],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'FILBY CREDIT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: FilbyColors.primaryDeep,
                      ),
                    ),
                  ),
                ),
              ),
              // Front card
              Transform.rotate(
                angle: 0.10,
                child: Container(
                  width: 220,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FilbyColors.primarySoft,
                        FilbyColors.primary,
                        FilbyColors.primaryDeep,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: FilbyColors.primary.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(data.icon, color: Colors.white70, size: 22),
                      const Spacer(),
                      const Text(
                        'AVAILABLE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.amount,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'ກີບ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: GoogleFonts.notoSerifLao(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: FilbyColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: FilbyColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FilbyColors.primary, FilbyColors.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
