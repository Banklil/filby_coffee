import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/cart_manager.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'credit_screen.dart';
import 'finance_screen.dart';
import 'profile_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;
  // Bumped when re-entering a tab to force a data refresh (IndexedStack keeps
  // screens alive, so a new key recreates the screen → initState refetches).
  int _homeTick = 0;
  int _creditTick = 0;
  int _financeTick = 0;

  List<Widget> get _screens => [
        HomeScreen(key: ValueKey('home_$_homeTick')),
        const ProductsScreen(),
        const CartScreen(),
        CreditScreen(key: ValueKey('credit_$_creditTick'), embedded: true),
        FinanceScreen(key: ValueKey('finance_$_financeTick')),
        const ProfileScreen(),
      ];

  void _select(int i) => setState(() {
        _currentIndex = i;
        if (i == 0) _homeTick++;
        if (i == 3) _creditTick++;
        if (i == 4) _financeTick++;
      });

  @override
  void initState() {
    super.initState();
    CartManager.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: FilbyColors.border, width: 1)),
          boxShadow: [
            BoxShadow(color: FilbyColors.navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'ໜ້າຫຼັກ',
                  isActive: _currentIndex == 0,
                  onTap: () => _select(0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'ສິນຄ້າ',
                  isActive: _currentIndex == 1,
                  onTap: () => _select(1),
                ),
                _CenterFab(
                  badge: CartManager.instance.count > 0 ? CartManager.instance.count : null,
                  onTap: () => _select(2),
                ),
                _NavItem(
                  icon: Icons.credit_card_outlined,
                  activeIcon: Icons.credit_card_rounded,
                  label: 'ສິນເຊື່ອ',
                  isActive: _currentIndex == 3,
                  onTap: () => _select(3),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'ລາຍງານ',
                  isActive: _currentIndex == 4,
                  onTap: () => _select(4),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'ບັນຊີ',
                  isActive: _currentIndex == 5,
                  onTap: () => _select(5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? FilbyColors.primary : FilbyColors.textMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elevated circular action in the center of the nav bar (cart / ສັ່ງຊື້).
class _CenterFab extends StatelessWidget {
  final int? badge;
  final VoidCallback onTap;
  const _CenterFab({required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -12),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [FilbyColors.gold, FilbyColors.goldSoft],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: FilbyColors.gold.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shopping_cart_rounded, size: 24, color: FilbyColors.navy),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text('$badge',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
