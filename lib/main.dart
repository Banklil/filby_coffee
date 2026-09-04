import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav.dart';
import 'services/auth_service.dart';
import 'services/staff_service.dart';
import 'screens/staff/staff_login_screen.dart';
import 'screens/staff/staff_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FilbyApp());
}

class FilbyApp extends StatelessWidget {
  const FilbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filby Coffee',
      theme: filbyTheme(),
      debugShowCheckedModeBanner: false,
      // ແອັບນີ້ອອກແບບມາສຳລັບມືຖື ແຕ່ເສີບເປັນເວັບນຳ. ຖ້າບໍ່ຈຳກັດຄວາມກວ້າງ
      // ທຸກແຖວຈະຢືດເຕັມຈໍ 2500px ຈົນອ່ານບໍ່ໄດ້. ບີບໄວ້ກາງຈໍແທນ.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ColoredBox(
          color: FilbyColors.bgDeep,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(color: FilbyColors.bg, child: child),
            ),
          ),
        );
      },
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/staff-login': (_) => const StaffLoginScreen(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // ກວດບັນຊີພະນັກງານກ່ອນ — ສອງຝ່າຍໃຊ້ token ຄົນລະອັນ
    if (await StaffAuth.isLoggedIn()) {
      if (mounted) setState(() { _loading = false; _isStaff = true; });
      return;
    }
    final loggedIn = await AuthService.isLoggedIn();
    if (mounted) setState(() { _loading = false; _loggedIn = loggedIn; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: FilbyColors.bg,
        body: Center(child: CircularProgressIndicator(color: FilbyColors.primary)),
      );
    }
    if (_isStaff) return const StaffShell();
    return _loggedIn ? const MainNav() : const LoginScreen();
  }
}
