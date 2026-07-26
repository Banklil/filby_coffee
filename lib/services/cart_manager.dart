import 'package:flutter/foundation.dart';

class CartItem {
  final int productId;
  final String name;
  final String emoji;
  final int price;
  final String unit;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.emoji,
    required this.price,
    required this.unit,
    required this.qty,
  });
}

class CartManager extends ChangeNotifier {
  static final CartManager instance = CartManager._();
  CartManager._();

  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.qty);
  int get subtotal => _items.values.fold(0, (s, i) => s + i.price * i.qty);

  int qty(int productId) => _items[productId]?.qty ?? 0;

  void add(int id, String name, String emoji, int price, String unit) {
    if (_items.containsKey(id)) {
      _items[id]!.qty++;
    } else {
      _items[id] = CartItem(productId: id, name: name, emoji: emoji, price: price, unit: unit, qty: 1);
    }
    notifyListeners();
  }

  void remove(int id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.qty > 1) {
      _items[id]!.qty--;
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
