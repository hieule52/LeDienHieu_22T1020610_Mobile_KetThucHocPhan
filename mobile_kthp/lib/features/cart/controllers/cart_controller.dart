import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../../../data/models/product.dart';

class CartController extends ChangeNotifier {
  final Map<int, CartItem> _items = {}; // key = productId

  List<CartItem> get items => _items.values.toList();

  int get totalQty => _items.values.fold(0, (sum, e) => sum + e.qty);

  num get totalPrice => _items.values.fold(0, (sum, e) => sum + e.lineTotal);

  void add(Product p, {int qty = 1}) {
    final existing = _items[p.id];
    if (existing != null) {
      existing.qty += qty;
    } else {
      _items[p.id] = CartItem(product: p, qty: qty);
    }
    notifyListeners();
  }

  void inc(int productId) {
    final item = _items[productId];
    if (item == null) return;
    item.qty += 1;
    notifyListeners();
  }

  void dec(int productId) {
    final item = _items[productId];
    if (item == null) return;
    item.qty -= 1;
    if (item.qty <= 0) _items.remove(productId);
    notifyListeners();
  }

  void remove(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
