import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/staff_service.dart';
import 'staff_shell.dart';

const _navy = Color(0xFF17233F);
const _navyUp = Color(0xFF2A4272);
const _gold = Color(0xFFC9A24B);

/// ພະນັກງານເຂົ້າສູ່ລະບົບດ້ວຍ ເບີໂທ + PIN.
/// ແຍກຈາກໜ້າ login ຂອງເຈົ້າຂອງຮ້ານ ເພາະໃຊ້ຄົນລະຂໍ້ມູນ ແລະ ຄົນລະສິດ.
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });

    final err = await StaffAuth.login(_phone.text, _pin.text);
    if (!mounted) return;

    if (err != null) {
      setState(() { _busy = false; _error = err; });
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StaffShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_navyUp, _navy],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _gold.withValues(alpha: 0.5), width: 2),
                      ),
                      child: const Icon(Icons.fingerprint_rounded,
                          size: 36, color: _gold),
                    ),
                    const SizedBox(height: 20),
                    Text('ເຂົ້າສູ່ລະບົບພະນັກງານ',
                        style: GoogleFonts.notoSerifLao(
                            fontSize: 21, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('ໃຊ້ເບີໂທ ແລະ PIN ທີ່ຮ້ານຕັ້ງໃຫ້',
                        style: GoogleFonts.notoSansLao(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: 28),

                    _field(
                      controller: _phone,
                      label: 'ເບີໂທ',
                      hint: '020xxxxxxxx',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                      validator: (v) => (v ?? '').trim().length < 5
                          ? 'ກະລຸນາໃສ່ເບີໂທ' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller: _pin,
                      label: 'PIN',
                      hint: '••••',
                      icon: Icons.lock_outline,
                      keyboard: TextInputType.number,
                      obscure: _hide,
                      suffix: IconButton(
                        icon: Icon(
                            _hide ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            size: 18, color: Colors.white54),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                      validator: (v) => (v ?? '').length < 4
                          ? 'PIN ຢ່າງໜ້ອຍ 4 ຕົວເລກ' : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Text(_error!,
                            style: GoogleFonts.notoSansLao(
                                fontSize: 12.5, height: 1.5,
                                color: Colors.white)),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _navy,
                          disabledBackgroundColor:
                              _gold.withValues(alpha: 0.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: _navy))
                            : Text('ເຂົ້າສູ່ລະບົບ',
                                style: GoogleFonts.notoSansLao(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
                      child: Text('ເຈົ້າຂອງຮ້ານ? ເຂົ້າສູ່ລະບົບທີ່ນີ້',
                          style: GoogleFonts.notoSansLao(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.72))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSansLao(
            fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        prefixIcon: Icon(icon, size: 19, color: Colors.white54),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
      ),
    );
  }
}
