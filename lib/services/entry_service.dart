import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// ລາຍຮັບ-ລາຍຈ່າຍທີ່ຮ້ານບັນທຶກເອງ.
class ShopEntry {
  final int id;
  final String type; // income | expense
  final String category;
  final int amount;
  final String? note;
  final String entryDate; // yyyy-MM-dd

  const ShopEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.entryDate,
    this.note,
  });

  bool get isIncome => type == 'income';

  factory ShopEntry.fromJson(Map<String, dynamic> j) => ShopEntry(
        id: j['id'] as int,
        type: j['type'] as String,
        category: j['category'] as String,
        amount: (j['amount'] as num).toInt(),
        note: j['note'] as String?,
        entryDate: (j['entry_date'] as String?) ?? '',
      );
}

class EntryPage {
  final List<ShopEntry> items;
  final int income;
  final int expense;
  const EntryPage(this.items, this.income, this.expense);

  int get net => income - expense;
}

class EntryService {
  static const _base = AuthService.baseUrl;

  /// ໝວດທີ່ server ອະນຸຍາດ — cache ໄວ້ ບໍ່ຕ້ອງດຶງຊ້ຳ
  static Map<String, List<String>>? _categories;

  static Future<Map<String, List<String>>> categories() async {
    if (_categories != null) return _categories!;
    try {
      final headers = await AuthService.authHeaders();
      final res = await http
          .get(Uri.parse('$_base/api/shop/entries/categories'), headers: headers)
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final m = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        _categories = m.map((k, v) =>
            MapEntry(k, (v as List).map((e) => e.toString()).toList()));
        return _categories!;
      }
    } catch (_) {
      // ໃຊ້ຄ່າສຳຮອງ ເພື່ອໃຫ້ບັນທຶກໄດ້ແມ່ນຕອນເນັດບໍ່ດີ
    }
    return const {
      'income': ['ລາຍຮັບອື່ນໆ'],
      'expense': ['ລາຍຈ່າຍອື່ນໆ'],
    };
  }

  static Future<EntryPage?> list({String period = 'month'}) async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http
          .get(Uri.parse('$_base/api/shop/entries?period=$period'),
              headers: headers)
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) return null;
      final d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return EntryPage(
        (d['items'] as List).map((e) => ShopEntry.fromJson(e)).toList(),
        (d['income'] as num).toInt(),
        (d['expense'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// ຄືນ null ຖ້າສຳເລັດ ຫຼື ຂໍ້ຄວາມຜິດພາດ.
  static Future<String?> create({
    required String type,
    required String category,
    required int amount,
    String? note,
    String? entryDate,
  }) async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http
          .post(Uri.parse('$_base/api/shop/entries'),
              headers: headers,
              body: jsonEncode({
                'type': type,
                'category': category,
                'amount': amount,
                if (note != null && note.isNotEmpty) 'note': note,
                if (entryDate != null) 'entry_date': entryDate,
              }))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 201 || res.statusCode == 200) return null;
      return _err(res);
    } catch (_) {
      return 'ເຊື່ອມຕໍ່ບໍ່ໄດ້ ກະລຸນາກວດອິນເຕີເນັດ';
    }
  }

  static Future<String?> update(int id,
      {String? category, int? amount, String? note, String? entryDate}) async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http
          .patch(Uri.parse('$_base/api/shop/entries/$id'),
              headers: headers,
              body: jsonEncode({
                if (category != null) 'category': category,
                if (amount != null) 'amount': amount,
                if (note != null) 'note': note,
                if (entryDate != null) 'entry_date': entryDate,
              }))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) return null;
      return _err(res);
    } catch (_) {
      return 'ເຊື່ອມຕໍ່ບໍ່ໄດ້';
    }
  }

  static Future<String?> remove(int id) async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http
          .delete(Uri.parse('$_base/api/shop/entries/$id'), headers: headers)
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) return null;
      return _err(res);
    } catch (_) {
      return 'ເຊື່ອມຕໍ່ບໍ່ໄດ້';
    }
  }

  static String _err(http.Response res) {
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      return d['detail']?.toString() ?? 'ບໍ່ສຳເລັດ (${res.statusCode})';
    } catch (_) {
      return 'ບໍ່ສຳເລັດ (${res.statusCode})';
    }
  }
}
