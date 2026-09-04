import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// ບັນຊີພະນັກງານ — ເກັບ token ແຍກຈາກເຈົ້າຂອງຮ້ານ ເພື່ອບໍ່ໃຫ້ການ login
/// ຂອງຝ່າຍໜຶ່ງໄປທັບ session ຂອງອີກຝ່າຍໃນເຄື່ອງດຽວກັນ.
class StaffAuth {
  static const _tokenKey = 'staff_token';
  static const _base = AuthService.baseUrl;

  static Map<String, dynamic>? _me;
  static Map<String, dynamic>? get me => _me;

  static Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<bool> isLoggedIn() async {
    if (await token() == null) return false;
    return await loadMe() == null;
  }

  static Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await token()}',
      };

  /// ຄືນ null ຖ້າສຳເລັດ ຫຼື ຂໍ້ຄວາມຜິດພາດເປັນພາສາລາວ.
  static Future<String?> login(String phone, String pin) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/api/staff/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': phone.trim(), 'pin': pin}))
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, body['access_token']);
        _me = body['staff'] as Map<String, dynamic>;
        return null;
      }
      return body['detail']?.toString() ?? 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ';
    } catch (_) {
      return 'ເຊື່ອມຕໍ່ບໍ່ໄດ້ ກະລຸນາກວດອິນເຕີເນັດ';
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _me = null;
  }

  static Future<String?> loadMe() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/staff/me'), headers: await _headers())
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        _me = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return null;
      }
      await logout();
      return 'ເຊສຊັນໝົດອາຍຸ ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່';
    } catch (_) {
      return 'ເຊື່ອມຕໍ່ບໍ່ໄດ້';
    }
  }

  /// ຜົນການກົດເຂົ້າ/ອອກ. [error] ເປັນ null ຖ້າສຳເລັດ.
  static Future<({String? error, int? distanceM, Map<String, dynamic>? data})>
      punch(String action, {double? lat, double? lng, double? accuracy}) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/api/staff/$action'),
              headers: await _headers(),
              body: jsonEncode({'lat': lat, 'lng': lng, 'accuracy': accuracy}))
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        return (error: null, distanceM: null, data: body as Map<String, dynamic>);
      }
      // ຢູ່ນອກລັດສະໝີ — server ສົ່ງໄລຍະທາງມານຳ ເພື່ອບອກວ່າໄກເທົ່າໃດ
      final detail = body['detail'];
      if (detail is Map) {
        return (
          error: detail['message']?.toString() ?? 'ກົດບໍ່ໄດ້',
          distanceM: (detail['distance_m'] as num?)?.toInt(),
          data: null,
        );
      }
      return (
        error: detail?.toString() ?? 'ກົດບໍ່ໄດ້',
        distanceM: null,
        data: null
      );
    } catch (_) {
      return (error: 'ເຊື່ອມຕໍ່ບໍ່ໄດ້', distanceM: null, data: null);
    }
  }

  static Future<Map<String, dynamic>?> attendance({int? year, int? month}) async {
    final q = year != null ? '?year=$year&month=$month' : '';
    return await _get('/api/staff/attendance$q') as Map<String, dynamic>?;
  }

  static Future<List<dynamic>?> payslips() async =>
      await _get('/api/staff/payslips') as List<dynamic>?;

  static Future<dynamic> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: await _headers())
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }
}

/// ຝັ່ງເຈົ້າຂອງຮ້ານ — ຈັດການພະນັກງານ, ເວລາ, ເງິນເດືອນ ແລະ ການກວດພິກັດ.
class StaffAdmin {
  static const _base = AuthService.baseUrl;

  static Future<List<dynamic>?> list({bool includeInactive = false}) async =>
      await _get('/api/shop/staff?include_inactive=$includeInactive')
          as List<dynamic>?;

  static Future<String?> create(Map<String, dynamic> body) =>
      _send('POST', '/api/shop/staff', body);

  static Future<String?> update(int id, Map<String, dynamic> body) =>
      _send('PATCH', '/api/shop/staff/$id', body);

  static Future<String?> deactivate(int id) =>
      _send('DELETE', '/api/shop/staff/$id', null);

  static Future<Map<String, dynamic>?> geofence() async =>
      await _get('/api/shop/staff/geofence') as Map<String, dynamic>?;

  static Future<String?> setGeofence(double lat, double lng, int radius) =>
      _send('PUT', '/api/shop/staff/geofence',
          {'lat': lat, 'lng': lng, 'radius_m': radius});

  static Future<Map<String, dynamic>?> attendance({int? year, int? month}) async {
    final q = year != null ? '?year=$year&month=$month' : '';
    return await _get('/api/shop/staff/attendance$q') as Map<String, dynamic>?;
  }

  static Future<String?> editAttendance(int id, Map<String, dynamic> body) =>
      _send('PATCH', '/api/shop/staff/attendance/$id', body);

  static Future<Map<String, dynamic>?> payroll({int? year, int? month}) async {
    final q = year != null ? '?year=$year&month=$month' : '';
    return await _get('/api/shop/staff/payroll$q') as Map<String, dynamic>?;
  }

  static Future<String?> addAdjustment(Map<String, dynamic> body) =>
      _send('POST', '/api/shop/staff/adjustments', body);

  static Future<String?> finalise({int? year, int? month}) {
    final q = year != null ? '?year=$year&month=$month' : '';
    return _send('POST', '/api/shop/staff/payroll/finalise$q', null);
  }

  static Future<String?> markPaid({int? year, int? month}) {
    final q = year != null ? '?year=$year&month=$month' : '';
    return _send('POST', '/api/shop/staff/payroll/pay$q', null);
  }

  static Future<Map<String, dynamic>?> audit({int days = 30}) async =>
      await _get('/api/shop/staff/audit?days=$days') as Map<String, dynamic>?;

  static Future<List<dynamic>?> auditPoints(int staffId, {int days = 30}) async =>
      await _get('/api/shop/staff/audit/$staffId/points?days=$days')
          as List<dynamic>?;

  static Future<dynamic> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: await AuthService.authHeaders())
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _send(
      String method, String path, Map<String, dynamic>? body) async {
    try {
      final headers = await AuthService.authHeaders();
      final uri = Uri.parse('$_base$path');
      final payload = body == null ? null : jsonEncode(body);

      late final http.Response res;
      switch (method) {
        case 'POST':
          res = await http
              .post(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 30));
        case 'PATCH':
          res = await http
              .patch(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 30));
        case 'PUT':
          res = await http
              .put(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 30));
        default:
          res = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
      }

      if (res.statusCode >= 200 && res.statusCode < 300) return null;
      try {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        return d['detail']?.toString() ?? 'ບໍ່ສຳເລັດ (${res.statusCode})';
      } catch (_) {
        return 'ບໍ່ສຳເລັດ (${res.statusCode})';
      }
    } catch (_) {
      return 'ເຊື່ອມຕໍ່ບໍ່ໄດ້';
    }
  }
}
