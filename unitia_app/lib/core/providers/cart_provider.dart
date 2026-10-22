import 'package:flutter/foundation.dart';
import '../models/cause.dart';
import '../models/order.dart';
import '../models/restaurant.dart';

class CartItem {
  final String menuItemId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  OrderItem toOrderItem() => OrderItem(
        menuItemId: menuItemId,
        name: name,
        price: price,
        quantity: quantity,
      );
}

class CartProvider extends ChangeNotifier {
  Restaurant? _restaurant;
  final List<CartItem> _items = [];
  Cause? _selectedCause;
  String? _selectedCity;

  Restaurant? get restaurant => _restaurant;
  List<CartItem> get items => List.unmodifiable(_items);
  Cause? get selectedCause => _selectedCause;
  String? get selectedCity => _selectedCity;

  void setCity(String? city) {
    _selectedCity = city;
    notifyListeners();
  }

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get donationAmount =>
      _restaurant != null ? subtotal * (_restaurant!.donationPercentage / 100) : 0.0;

  int quantityOf(String menuItemId) =>
      _items.where((i) => i.menuItemId == menuItemId).fold(0, (_, i) => i.quantity);

  void setRestaurant(Restaurant r) {
    if (_restaurant?.id != r.id) _items.clear();
    _restaurant = r;
    notifyListeners();
  }

  void add(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final existing = _items.cast<CartItem?>().firstWhere(
          (i) => i?.menuItemId == id,
          orElse: () => null,
        );
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(CartItem(
        menuItemId: id,
        name: item['name'] as String,
        price: (item['price'] as num).toDouble(),
        quantity: 1,
      ));
    }
    notifyListeners();
  }

  void remove(String menuItemId) {
    final idx = _items.indexWhere((i) => i.menuItemId == menuItemId);
    if (idx == -1) return;
    if (_items[idx].quantity > 1) {
      _items[idx].quantity--;
    } else {
      _items.removeAt(idx);
    }
    notifyListeners();
  }

  void selectCause(Cause cause) {
    _selectedCause = cause;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _restaurant = null;
    _selectedCause = null;
    notifyListeners();
  }
}
