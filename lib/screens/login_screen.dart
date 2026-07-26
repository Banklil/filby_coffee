import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'main_nav.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _showForgotPassword(BuildContext context) async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    String? msg;
    bool sending = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: FilbyColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ລືມລະຫັດ', style: TextStyle(color: FilbyColors.textPrimary, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ໃສ່ email ຂອງທ່ານ ພວກເຮົາຈະສົ່ງລິ້ງ reset ໄປໃຫ້', style: TextStyle(fontSize: 13, color: FilbyColors.textSecondary)),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: FilbyColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'your@gmail.com',
                  hintStyle: const TextStyle(color: FilbyColors.textMuted),
                  filled: true,
                  fillColor: FilbyColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: FilbyColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (msg != null) ...[
                const SizedBox(height: 10),
                Text(msg!, style: TextStyle(fontSize: 12, color: msg!.startsWith('ສົ່ງ') ? FilbyColors.primary : const Color(0xFFE85A4A))),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: FilbyColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: sending ? null : () async {
                if (emailCtrl.text.isEmpty) return;
                setS(() { sending = true; msg = null; });
                final err = await AuthService.forgotPassword(emailCtrl.text.trim());
                setS(() {
                  sending = false;
                  msg = err ?? 'ສົ່ງ email reset ລະຫັດແລ້ວ ກວດກ່ອງຈົດໝາຍຂອງທ່ານ';
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: FilbyColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('ສົ່ງ'),
            ),
          ],
        ),
      ),
    );
    emailCtrl.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'ກະລຸນາໃສ່ email ແລະ ລະຫັດຜ່ານ');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNav()));
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
                center: Alignment(0.6, -0.8),
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
                  const SizedBox(height: 56),
                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: FilbyColors.primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'ເຂົ້າສູ່ລະບົບ',
                      style: GoogleFonts.notoSerifLao(fontSize: 26, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Filby Coffee · ສຳລັບເຈົ້າຂອງຮ້ານ', style: TextStyle(fontSize: 13, color: FilbyColors.textSecondary)),
                  ),
                  const SizedBox(height: 40),
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
                  _AuthField(
                    label: 'Email',
                    hint: 'your@gmail.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),
                  _AuthField(
                    label: 'ລະຫັດຜ່ານ',
                    hint: '••••••••',
                    controller: _passCtrl,
                    obscure: _obscure,
                    icon: Icons.lock_outline,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: FilbyColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _showForgotPassword(context),
                      child: const Text('ລືມລະຫັດ?', style: TextStyle(fontSize: 13, color: FilbyColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FilbyColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ເຂົ້າສູ່ລະບົບ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: RichText(
                        text: const TextSpan(
                          text: 'ຍັງບໍ່ມີບັນຊີ? ',
                          style: TextStyle(color: FilbyColors.textMuted, fontSize: 14),
                          children: [
                            TextSpan(text: 'ສ້າງບັນຊີໃໝ່', style: TextStyle(color: FilbyColors.primary, fontWeight: FontWeight.w700)),
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

class _AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData icon;
  final Widget? suffix;

  const _AuthField({
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
