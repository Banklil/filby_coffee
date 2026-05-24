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
  static const String baseUrl = 'https://filbycoffee-production.up.railway.app';

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
      ).timeout(const Duration(seconds: 10));
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
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveToken(body['access_token']);
        _currentUser = AuthUser.fromJson(body['user']);
        return null;
      }
      return body['detail'] ?? 'Login ບໍ່ສຳເລັດ';
    } on Exception {
      return 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server ກະລຸນາກວດ internet';
    }
  }

  static Future<String?> signUpWithEmail(String email, String password, {String shopName = 'ຮ້ານຂອງຂ້ອຍ'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/shop/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'shop_name': shopName}),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveToken(body['access_token']);
        _currentUser = AuthUser.fromJson(body['user']);
        return null;
      }
      return body['detail'] ?? 'ສ້າງບັນຊີບໍ່ສຳເລັດ';
    } catch (_) {
      return 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server ກະລຸນາກວດ internet';
    }
  }

  static Future<void> signOut() async {
    await _clearToken();
  }

  static Future<http.Response> httpGet(Uri uri, Map<String, String> headers) async {
    return http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
