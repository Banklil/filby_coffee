import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/auth_service.dart';

/// ດຶງຈຳນວນທີ່ຍັງບໍ່ໄດ້ອ່ານ ໃຫ້ໜ້າອື່ນສະແດງເປັນຈຸດແດງ.
class NotificationBadge {
  static Future<int> unreadCount() async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/shop/notifications/unread-count'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body)['unread_count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {
      // ບໍ່ມີສັນຍານກໍ່ບໍ່ຕ້ອງສະແດງຈຸດແດງ
    }
    return 0;
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/shop/notifications'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception('ໂຫຼດບໍ່ສຳເລັດ (${res.statusCode})');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _items = body['items'] as List<dynamic>? ?? [];
        _loading = false;
      });

      // ເປີດເບິ່ງແລ້ວຖືວ່າອ່ານແລ້ວ — ບໍ່ຕ້ອງລໍຜົນ
      final h2 = await AuthService.authHeaders();
      unawaited(http.post(
        Uri.parse('${AuthService.baseUrl}/api/shop/notifications/seen'),
        headers: h2,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'ໂຫຼດການເຕືອນບໍ່ໄດ້ — ກວດອິນເຕີເນັດແລ້ວລອງໃໝ່';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilbyColors.bg,
      appBar: AppBar(
        backgroundColor: FilbyColors.bg,
        title: Text('ການເຕືອນ',
            style: GoogleFonts.notoSerifLao(
                fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: FilbyColors.primary));
    }
    if (_error != null) {
      return _empty(Icons.wifi_off_rounded, 'ເກີດຂໍ້ຜິດພາດ', _error!,
          retry: true);
    }
    if (_items.isEmpty) {
      return _empty(Icons.notifications_none_rounded, 'ບໍ່ມີການເຕືອນ',
          'ເມື່ອມີໃບບິນໃກ້ຄົບກຳນົດ, ຄຳສັ່ງມີຄວາມຄືບໜ້າ '
          'ຫຼື ເມັດກາເຟໃກ້ໝົດ ພວກເຮົາຈະແຈ້ງໃຫ້ຢູ່ນີ້');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: FilbyColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _card(_items[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _empty(IconData icon, String title, String body, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                  color: FilbyColors.surface2, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: FilbyColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: GoogleFonts.notoSerifLao(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: FilbyColors.textPrimary)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansLao(
                    fontSize: 13, height: 1.5, color: FilbyColors.textSecondary)),
            if (retry) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('ລອງໃໝ່'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FilbyColors.primary,
                  side: const BorderSide(color: FilbyColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> n) {
    final severity = n['severity'] as String? ?? 'info';
    final unread = n['unread'] == true;
    final (color, icon) = switch (severity) {
      'danger' => (const Color(0xFFE53935), Icons.error_outline),
      'warning' => (FilbyColors.gold, Icons.access_time_rounded),
      'success' => (FilbyColors.success, Icons.check_circle_outline),
      _ => (FilbyColors.primary, Icons.info_outline),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FilbyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: unread ? color.withValues(alpha: 0.45) : FilbyColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n['title'] as String? ?? '',
                        style: GoogleFonts.notoSansLao(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: FilbyColors.textPrimary,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8, top: 3),
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n['body'] as String? ?? '',
                  style: GoogleFonts.notoSansLao(
                      fontSize: 12,
                      height: 1.45,
                      color: FilbyColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  _ago(n['created_at'] as String?),
                  style: GoogleFonts.notoSansLao(
                      fontSize: 10.5, color: FilbyColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ago(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final d = DateTime.now().toUtc().difference(t.toUtc());
    if (d.isNegative) {
      final days = (-d.inDays);
      if (days >= 1) return 'ອີກ $days ມື້';
      return 'ໄວໆນີ້';
    }
    if (d.inMinutes < 1) return 'ຫາກໍ່ນີ້';
    if (d.inMinutes < 60) return '${d.inMinutes} ນາທີກ່ອນ';
    if (d.inHours < 24) return '${d.inHours} ຊົ່ວໂມງກ່ອນ';
    if (d.inDays < 30) return '${d.inDays} ມື້ກ່ອນ';
    return '${(d.inDays / 30).floor()} ເດືອນກ່ອນ';
  }
}
