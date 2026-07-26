import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'main_nav.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_emailCtrl.text.isEmpty || _nameCtrl.text.isEmpty || _passCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      setState(() => _error = 'ກະລຸນາໃສ່ຂໍ້ມູນໃຫ້ຄົບ');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'ລະຫັດຜ່ານບໍ່ຕົງກັນ');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final err = await AuthService.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text, shopName: _nameCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _SignupSuccessScreen(
          email: _emailCtrl.text.trim(),
          shopName: _nameCtrl.text.trim(),
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.8),
                radius: 1.0,
                colors: [Color(0x1AE8854A), FilbyColors.bg],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, size: 18, color: FilbyColors.textPrimary),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: FilbyColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      'ສ້າງບັນຊີໃໝ່',
                      style: GoogleFonts.notoSerifLao(fontSize: 26, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Filby Coffee · ສຳລັບເຈົ້າຂອງຮ້ານ', style: TextStyle(fontSize: 13, color: FilbyColors.textSecondary)),
                  ),
                  const SizedBox(height: 36),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1AE85A4A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x33E85A4A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Color(0xFFE85A4A)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFE85A4A)))),
                        ],
                      ),
                    ),
                  _SignupField(
                    label: 'Email',
                    hint: 'your@gmail.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),
                  _SignupField(
                    label: 'ຊື່ຮ້ານ',
                    hint: 'ຕົວຢ່າງ: Filby Coffee',
                    controller: _nameCtrl,
                    icon: Icons.store_outlined,
                  ),
                  const SizedBox(height: 14),
                  _SignupField(
                    label: 'ລະຫັດຜ່ານ',
                    hint: '••••••••',
                    controller: _passCtrl,
                    obscure: _obscurePass,
                    icon: Icons.lock_outline,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscurePass = !_obscurePass),
                      child: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: FilbyColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SignupField(
                    label: 'ຢືນຢັນລະຫັດຜ່ານ',
                    hint: '••••••••',
                    controller: _confirmCtrl,
                    obscure: _obscureConfirm,
                    icon: Icons.lock_outline,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: FilbyColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FilbyColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ສ້າງບັນຊີ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: RichText(
                        text: const TextSpan(
                          text: 'ມີບັນຊີແລ້ວ? ',
                          style: TextStyle(color: FilbyColors.textMuted, fontSize: 14),
                          children: [
                            TextSpan(text: 'ເຂົ້າສູ່ລະບົບ', style: TextStyle(color: FilbyColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData icon;
  final Widget? suffix;

  const _SignupField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FilbyColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: FilbyColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FilbyColors.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 18, color: FilbyColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, color: FilbyColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 14, color: FilbyColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (suffix != null) ...[Padding(padding: const EdgeInsets.only(right: 12), child: suffix!)],
            ],
          ),
        ),
      ],
    );
  }
}

class _SignupSuccessScreen extends StatelessWidget {
  final String email;
  final String shopName;
  const _SignupSuccessScreen({required this.email, required this.shopName});

  static const _webUrl = 'https://valiant-ambition-production.up.railway.app/docs';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: FilbyColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, size: 52, color: FilbyColors.success),
              ),
              const SizedBox(height: 24),
              Text('ສ້າງບັນຊີສຳເລັດ!', style: GoogleFonts.notoSerifLao(fontSize: 24, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
              const SizedBox(height: 8),
              Text(shopName, style: const TextStyle(fontSize: 16, color: FilbyColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 13, color: FilbyColors.textSecondary)),
              const SizedBox(height: 32),
              // Web redirect card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FilbyColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FilbyColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.web, size: 18, color: FilbyColors.primary),
                        const SizedBox(width: 8),
                        Text('ຂໍ້ມູນຮ້ານ', style: GoogleFonts.notoSerifLao(fontSize: 14, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ກະລຸນາເຂົ້າ web ເພື່ອ:\n• ກຳນົດທີ່ຢູ່ຮ້ານ\n• ອັບໂຫລດເອກະສານ\n• ສະໝັກສິນເຊື່ອ\n• ເພີ່ມຂໍ້ມູນລາຍລະອຽດ',
                      style: TextStyle(fontSize: 13, color: FilbyColors.textSecondary, height: 1.7),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: _webUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copy URL ແລ້ວ — paste ໃນ browser'), backgroundColor: FilbyColors.primary),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FilbyColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: FilbyColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 14, color: FilbyColors.primary),
                            const SizedBox(width: 6),
                            const Expanded(child: Text('filby-coffee.onrender.com', style: TextStyle(fontSize: 11, color: FilbyColors.primary))),
                            const Icon(Icons.copy, size: 14, color: FilbyColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNav()),
                    (_) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FilbyColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('ເຂົ້າໃຊ້ App ໄດ້ເລີຍ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
