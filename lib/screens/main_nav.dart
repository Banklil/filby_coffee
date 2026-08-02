import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/cart_manager.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
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
  int _financeTick = 0;

  List<Widget> get _screens => [
        HomeScreen(key: ValueKey('home_$_homeTick')),
        const ProductsScreen(),
        const CartScreen(),
        FinanceScreen(key: ValueKey('finance_$_financeTick')),
        const ProfileScreen(),
      ];

  void _select(int i) => setState(() {
        _currentIndex = i;
        if (i == 0) _homeTick++;
        if (i == 3) _financeTick++;
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
        decoration: const BoxDecoration(
          color: Color(0xEB0E0703),
          border: Border(
            top: BorderSide(color: FilbyColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'ໜ້າຫຼັກ',
                  isActive: _currentIndex == 0,
                  onTap: () => _select(0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: 'ສິນຄ້າ',
                  isActive: _currentIndex == 1,
                  onTap: () => _select(1),
                ),
                _NavItem(
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart,
                  label: 'ສັ່ງຊື້',
                  isActive: _currentIndex == 2,
                  badge: CartManager.instance.count > 0 ? CartManager.instance.count : null,
                  onTap: () => _select(2),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'ລາຍງານ',
                  isActive: _currentIndex == 3,
                  onTap: () => _select(3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'ບັນຊີ',
                  isActive: _currentIndex == 4,
                  onTap: () => _select(4),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? FilbyColors.primary : FilbyColors.textMuted,
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: FilbyColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FilbyColors.bg, width: 1.5),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? FilbyColors.primary : FilbyColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
