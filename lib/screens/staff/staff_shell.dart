import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/staff_service.dart';
import 'staff_clock_screen.dart';
import 'staff_payslips_screen.dart';

const _navy = Color(0xFF17233F);
const _navyDeep = Color(0xFF101A2E);
const _gold = Color(0xFFC9A24B);

/// ແອັບຝັ່ງພະນັກງານ — ມີພຽງສອງໜ້າ ໂດຍເຈດຕະນາ.
/// ບໍ່ມີທາງໄປໜ້າຍອດຂາຍ, ສິນເຊື່ອ ຫຼື ຂໍ້ມູນພະນັກງານຄົນອື່ນ.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;
  int _clockTick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: IndexedStack(
        index: _index,
        children: [
          StaffClockScreen(key: ValueKey('clock_$_clockTick')),
          const StaffPayslipsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _navyDeep,
          border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _tab(0, Icons.fingerprint_rounded, 'ລົງເວລາ'),
                _tab(1, Icons.receipt_long_rounded, 'ເງິນເດືອນ'),
                _logoutTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) {
    final active = _index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _index = i;
          if (i == 0) _clockTick++;   // ກັບມາໜ້າລົງເວລາ = ໂຫຼດຂໍ້ມູນໃໝ່
        }),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22,
                color: active ? _gold : Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.notoSansLao(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: active ? _gold : Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _logoutTab() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              title: Text('ອອກຈາກລະບົບ',
                  style: GoogleFonts.notoSerifLao(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _navy)),
              content: Text('ຕ້ອງເຂົ້າສູ່ລະບົບໃໝ່ຈຶ່ງກົດເວລາໄດ້',
                  style: GoogleFonts.notoSansLao(fontSize: 13)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('ຍົກເລີກ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('ອອກ',
                        style: TextStyle(color: Color(0xFFE53935)))),
              ],
            ),
          );
          if (ok == true && mounted) {
            await StaffAuth.logout();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            }
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded,
                size: 22, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: 4),
            Text('ອອກ',
                style: GoogleFonts.notoSansLao(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}
