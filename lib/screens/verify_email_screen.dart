import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'main_nav.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;
  String? _message;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final verified = await AuthService.checkEmailVerified();
      if (!mounted) return;
      if (verified) {
        _pollTimer?.cancel();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNav()));
      }
    });
  }

  Future<void> _checkNow() async {
    setState(() { _checking = true; _message = null; });
    final verified = await AuthService.checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (verified) {
      _pollTimer?.cancel();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNav()));
    } else {
      setState(() => _message = 'ຍັງບໍ່ທັນຢືນຢັນ ກະລຸນາກວດ email ຂອງທ່ານ');
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _message = null; });
    final err = await AuthService.resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _message = err ?? 'ສົ່ງ email ໃໝ່ແລ້ວ ກວດກ່ອງຈົດໝາຍຂອງທ່ານ';
    });
  }

  Future<void> _cancel() async {
    _pollTimer?.cancel();
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                center: Alignment(0.0, -0.8),
                radius: 1.0,
                colors: [Color(0x1AE8854A), FilbyColors.bg],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: FilbyColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: FilbyColors.border),
                    ),
                    child: const Center(
                      child: Text('📧', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'ກວດສອບ Email',
                    style: GoogleFonts.notoSerifLao(fontSize: 24, fontWeight: FontWeight.w700, color: FilbyColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ພວກເຮົາໄດ້ສົ່ງລິ້ງຢືນຢັນໄປຫາ',
                    style: TextStyle(fontSize: 14, color: FilbyColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.email,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FilbyColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ກະລຸນາກົດລິ້ງໃນ email ເພື່ອຢືນຢັນບັນຊີຂອງທ່ານ',
                    style: TextStyle(fontSize: 13, color: FilbyColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FilbyColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FilbyColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: FilbyColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_message!, style: const TextStyle(fontSize: 12, color: FilbyColors.textSecondary))),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _checking ? null : _checkNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FilbyColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _checking
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ຂ້ອຍຢືນຢັນແລ້ວ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _resending ? null : _resend,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: FilbyColors.borderStrong),
                        foregroundColor: FilbyColors.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _resending
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: FilbyColors.primary, strokeWidth: 2))
                          : const Text('ສົ່ງ email ໃໝ່', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _cancel,
                    child: const Text(
                      'ກັບໄປໜ້າ Login',
                      style: TextStyle(fontSize: 13, color: FilbyColors.textMuted, decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FilbyColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FilbyColors.border),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 14, color: FilbyColors.primary),
                            SizedBox(width: 6),
                            Text('ຄຳແນະນຳ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FilbyColors.primary)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• ກວດກ່ອງ Spam / Junk ຖ້າບໍ່ພົບ email\n• ລີ້ງໝົດອາຍຸພາຍໃນ 24 ຊົ່ວໂມງ\n• ກົດ "ສົ່ງ email ໃໝ່" ຖ້າລໍຖ້ານານເກີນໄປ',
                          style: TextStyle(fontSize: 11, color: FilbyColors.textMuted, height: 1.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
