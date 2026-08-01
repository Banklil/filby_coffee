import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final int id;
  final String email;
  final String shopName;

  const AuthUser({required this.id, required this.email, required this.shopName});

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'],
        email: j['email'],
        shopName: j['shop_name'] ?? 'ຮ້ານຂອງຂ້ອຍ',
      );
}

class AuthService {
  static const String baseUrl = 'https://valiant-ambition-production.up.railway.app';

  static AuthUser? _currentUser;
  static AuthUser? get currentUser => _currentUser;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _currentUser = null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    if (token == null) return false;
    final err = await loadCurrentUser();
    return err == null;
  }

  static Future<String?> loadCurrentUser() async {
    final token = await _getToken();
    if (token == null) return 'ກະລຸນາ Login ກ່ອນ';
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/shop/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) {
        _currentUser = AuthUser.fromJson(jsonDecode(res.body));
        return null;
      }
      await _clearToken();
      return 'Session ໝົດອາຍຸ ກະລຸນາ Login ໃໝ່';
    } catch (_) {
      return 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server';
    }
  }

  static Future<String?> signInWithEmail(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/shop/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 90));
      if (res.headers['content-type']?.contains('application/json') != true) {
        return 'HTTP ${res.statusCode} — server returned non-JSON (wrong URL?)';
      }
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveToken(body['access_token']);
        _currentUser = AuthUser.fromJson(body['user']);
        return null;
      }
      return body['detail'] ?? 'Login ບໍ່ສຳເລັດ (${res.statusCode})';
    } on TimeoutException {
      return 'Server ໃຊ້ເວລາດົນ — ລອງໃໝ່ອີກຄັ້ງ';
    } on Exception catch (e) {
      return 'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}';
    }
  }

  static Future<String?> signUpWithEmail(String email, String password, {String shopName = 'ຮ້ານຂອງຂ້ອຍ'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/shop/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'shop_name': shopName}),
      ).timeout(const Duration(seconds: 90));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveToken(body['access_token']);
        _currentUser = AuthUser.fromJson(body['user']);
        return null;
      }
      return body['detail'] ?? 'ສ້າງບັນຊີບໍ່ສຳເລັດ';
    } on TimeoutException {
      return 'Server ໃຊ້ເວລາດົນ — ລອງໃໝ່ອີກຄັ້ງ';
    } on Exception catch (e) {
      return 'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}';
    }
  }

  static Future<String?> forgotPassword(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/shop/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 90));
      if (res.headers['content-type']?.contains('application/json') != true) {
        return 'HTTP ${res.statusCode}';
      }
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return null;
      return body['detail'] ?? 'ສົ່ງຄຳຂໍບໍ່ສຳເລັດ (${res.statusCode})';
    } on TimeoutException {
      return 'Server ໃຊ້ເວລາດົນ — ລອງໃໝ່ອີກຄັ້ງ';
    } on Exception catch (e) {
      return 'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}';
    }
  }

  static Future<bool> checkEmailVerified() async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/shop/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['is_verified'] == true || body['email_verified'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> resendVerificationEmail() async {
    final token = await _getToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/shop/resend-verification'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) return null;
      if (res.headers['content-type']?.contains('application/json') == true) {
        final body = jsonDecode(res.body);
        return body['detail'] ?? 'ສົ່ງ email ໃໝ່ບໍ່ສຳເລັດ';
      }
      return 'ສົ່ງ email ໃໝ່ບໍ່ສຳເລັດ (${res.statusCode})';
    } on TimeoutException {
      return 'Server ໃຊ້ເວລາດົນ — ລອງໃໝ່ອີກຄັ້ງ';
    } on Exception catch (e) {
      return 'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}';
    }
  }

  /// Remaining coffee-bean stock for the shop, in kilograms. Null on failure.
  static Future<double?> fetchBeanStock() async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/shop/stock'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['bean_balance_kg'] as num?)?.toDouble() ?? 0;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Record a POS sale: deduct [beansKg] of beans and log the sale amount/items.
  /// Returns the new balance + whether stock was insufficient, or null on error.
  static Future<({double balanceKg, bool insufficient})?> posSale(
    double beansKg, {
    double totalPrice = 0,
    List<Map<String, dynamic>>? items,
  }) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/shop/pos-sale'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'beans_kg': beansKg,
          'total_price': totalPrice,
          if (items != null) 'items': items,
        }),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (
          balanceKg: (body['bean_balance_kg'] as num?)?.toDouble() ?? 0,
          insufficient: body['insufficient'] == true,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Income / expense / net-profit + weekly + best-sellers for the shop.
  /// [period] is "day", "week", or "month". Null on failure.
  static Future<Map<String, dynamic>?> fetchSummary(String period) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/shop/summary?period=$period'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sales history: per-menu totals (`by_item`) + recent transactions (`recent`).
  /// [period] is "day", "week", "month", or "all". Null on failure.
  static Future<Map<String, dynamic>?> fetchSales(String period) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/shop/sales?period=$period'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _clearToken();
  }

  static Future<http.Response> httpGet(Uri uri, Map<String, String> headers) async {
    return http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
