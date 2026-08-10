import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/shop_logo.dart';

class ShopInfoScreen extends StatefulWidget {
  const ShopInfoScreen({super.key});

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addrCtrl;

  bool _saving = false;
  bool _dirty = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final u = AuthService.currentUser;
    _nameCtrl = TextEditingController(text: u?.shopName ?? '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    _addrCtrl = TextEditingController(text: u?.address ?? '');
    for (final c in [_nameCtrl, _phoneCtrl, _addrCtrl]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    final u = AuthService.currentUser;
    final changed = _nameCtrl.text.trim() != (u?.shopName ?? '') ||
        _phoneCtrl.text.trim() != (u?.phone ?? '') ||
        _addrCtrl.text.trim() != (u?.address ?? '');
    if (changed != _dirty) setState(() => _dirty = changed);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final err = await AuthService.updateProfile(
      shopName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (err == null) _dirty = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'ບັນທຶກຂໍ້ມູນຮ້ານແລ້ວ'),
      backgroundColor: err == null ? FilbyColors.success : const Color(0xFFE74C3C),
    ));
  }

  /// ຖາມກ່ອນອອກ ຖ້າຍັງມີການແກ້ໄຂທີ່ບໍ່ທັນບັນທຶກ.
  Future<bool> _confirmLeave() async {
    if (!_dirty || _saving) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FilbyColors.surface,
        title: Text('ຍັງບໍ່ໄດ້ບັນທຶກ',
            style: GoogleFonts.notoSerifLao(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: FilbyColors.textPrimary)),
        content: Text('ອອກເລີຍບໍ? ການປ່ຽນແປງຈະຫາຍໄປ.',
            style: GoogleFonts.notoSansLao(
                fontSize: 13, color: FilbyColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ກັບໄປແກ້ຕໍ່'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ອອກ', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: FilbyColors.bg,
        appBar: AppBar(
          backgroundColor: FilbyColors.bg,
          title: Text('ຂໍ້ມູນຮ້ານ',
              style: GoogleFonts.notoSerifLao(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmLeave() && mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: _logoPicker()),
              const SizedBox(height: 24),

              _field(
                label: 'ຊື່ຮ້ານ',
                controller: _nameCtrl,
                hint: 'ຮ້ານກາເຟຂອງຂ້ອຍ',
                icon: Icons.store_outlined,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'ກະລຸນາໃສ່ຊື່ຮ້ານ';
                  if (s.length < 2) return 'ຊື່ຮ້ານສັ້ນເກີນໄປ';
                  return null;
                },
              ),
              _field(
                label: 'ເບີໂທ',
                controller: _phoneCtrl,
                hint: '020xxxxxxxx',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null; // ບໍ່ບັງຄັບ
                  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length < 8) return 'ເບີໂທບໍ່ຖືກຕ້ອງ';
                  return null;
                },
              ),
              _field(
                label: 'ທີ່ຢູ່ຮ້ານ',
                controller: _addrCtrl,
                hint: 'ບ້ານ, ເມືອງ, ແຂວງ',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 6),
              _readOnlyCard(user),

              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_saving || !_dirty) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FilbyColors.primary,
                    disabledBackgroundColor: FilbyColors.surface3,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: FilbyColors.textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(_dirty ? 'ບັນທຶກ' : 'ບໍ່ມີການປ່ຽນແປງ',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// ຮູບຮ້ານ + ປຸ່ມກ້ອງ. ຫຍໍ້ຮູບຢູ່ client ກ່ອນສົ່ງ ເພື່ອບໍ່ໃຫ້ອັບຮູບ 5 MB
  /// ຂຶ້ນໄປໂດຍບໍ່ຈຳເປັນ ແລະ ບໍ່ໃຫ້ຖານຂໍ້ມູນໃຫຍ່ໂດຍບໍ່ມີເຫດຜົນ.
  Widget _logoPicker() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: FilbyColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20),
            ],
          ),
          child: const ShopLogo(size: 90, radius: 20, fit: BoxFit.cover),
        ),
        if (_uploadingLogo)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                ),
              ),
            ),
          ),
        Positioned(
          right: -6,
          bottom: -6,
          child: GestureDetector(
            onTap: _uploadingLogo ? null : _pickLogo,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: FilbyColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: FilbyColors.bg, width: 3),
              ),
              child: const Icon(Icons.photo_camera_rounded,
                  size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final hasLogo = AuthService.currentUser?.logoUrl != null;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: FilbyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: FilbyColors.primary),
              title: Text('ເລືອກຮູບຈາກເຄື່ອງ',
                  style: GoogleFonts.notoSansLao(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: FilbyColors.primary),
              title: Text('ຖ່າຍຮູບໃໝ່',
                  style: GoogleFonts.notoSansLao(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (hasLogo)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Color(0xFFE53935)),
                title: Text('ລຶບຮູບ ໃຊ້ໂລໂກ້ Filby ແທນ',
                    style: GoogleFonts.notoSansLao(
                        fontSize: 14, color: const Color(0xFFE53935))),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    setState(() => _uploadingLogo = true);
    String? err;

    if (action == 'delete') {
      err = await AuthService.deleteLogo();
    } else {
      final picked = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,          // ໂລໂກ້ບໍ່ຕ້ອງໃຫຍ່ກວ່ານີ້
        maxHeight: 512,
        imageQuality: 82,
      );
      if (picked == null) {
        if (mounted) setState(() => _uploadingLogo = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      err = await AuthService.uploadLogo(bytes, picked.name);
    }

    if (!mounted) return;
    setState(() => _uploadingLogo = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ??
          (action == 'delete' ? 'ລຶບຮູບຮ້ານແລ້ວ' : 'ປ່ຽນຮູບຮ້ານແລ້ວ')),
      backgroundColor:
          err == null ? FilbyColors.success : const Color(0xFFE74C3C),
    ));
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.notoSansLao(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FilbyColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
                color: FilbyColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: FilbyColors.textMuted, fontSize: 13),
              prefixIcon: maxLines == 1
                  ? Icon(icon, size: 18, color: FilbyColors.textMuted)
                  : null,
              filled: true,
              fillColor: FilbyColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FilbyColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FilbyColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: FilbyColors.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Email ແລະ ລະຫັດຮ້ານປ່ຽນເອງບໍ່ໄດ້ — email ຄືຕົວລະບຸບັນຊີ.
  Widget _readOnlyCard(AuthUser? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FilbyColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FilbyColors.border),
      ),
      child: Column(
        children: [
          _roRow('Email', user?.email ?? '—'),
          const Divider(height: 18, color: FilbyColors.border),
          _roRow('ລະຫັດຮ້ານ', '#${user?.id ?? '—'}'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 14, color: FilbyColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ສອງລາຍການນີ້ປ່ຽນເອງບໍ່ໄດ້ — ຕິດຕໍ່ທີມງານ Filby ຖ້າຕ້ອງການແກ້',
                  style: GoogleFonts.notoSansLao(
                      fontSize: 11, height: 1.4, color: FilbyColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.notoSansLao(
                fontSize: 12, color: FilbyColors.textSecondary)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FilbyColors.textPrimary)),
        ),
      ],
    );
  }
}
