import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String? variant;
  int quantity;
  final String image;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.variant,
    required this.quantity,
    required this.image,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'variant': variant,
      'quantity': quantity,
      'image': image,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'],
      name: map['name'],
      price: map['price'],
      variant: map['variant'],
      quantity: map['quantity'],
      image: map['image'],
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  double _subtotal = 0;
  double _tax = 0;
  double _shipping = 0;
  double _discount = 0;
  String? _couponCode;
  int _loyaltyPointsUsed = 0;

  List<CartItem> get items => _items;
  double get subtotal => _subtotal;
  double get tax => _tax;
  double get shipping => _shipping;
  double get discount => _discount;
  double get total =>
      _subtotal + _tax + _shipping - _discount - _loyaltyPointsUsed;
  String? get couponCode => _couponCode;
  int get loyaltyPointsUsed => _loyaltyPointsUsed;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');

      if (cartJson != null) {
        final cartData = json.decode(cartJson);

        _items =
            (cartData['items'] as List)
                .map((item) => CartItem.fromMap(item))
                .toList();

        _subtotal = cartData['subtotal'] ?? 0.0;
        _tax = cartData['tax'] ?? 0.0;
        _shipping = cartData['shipping'] ?? 0.0;
        _discount = cartData['discount'] ?? 0.0;
        _couponCode = cartData['couponCode'];
        _loyaltyPointsUsed = cartData['loyaltyPointsUsed'] ?? 0;

        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cartData = {
        'items': _items.map((item) => item.toMap()).toList(),
        'subtotal': _subtotal,
        'tax': _tax,
        'shipping': _shipping,
        'discount': _discount,
        'couponCode': _couponCode,
        'loyaltyPointsUsed': _loyaltyPointsUsed,
      };

      await prefs.setString('cart', json.encode(cartData));
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void addItem({
    required String productId,
    required String name,
    required double price,
    String? variant,
    required int quantity,
    required String image,
  }) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == productId && item.variant == variant,
    );

    if (existingIndex >= 0) {
      // Item already in cart, update quantity
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item
      _items.add(
        CartItem(
          productId: productId,
          name: name,
          price: price,
          variant: variant,
          quantity: quantity,
          image: image,
        ),
      );
    }

    _calculateTotals();
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length) {
      if (quantity > 0) {
        _items[index].quantity = quantity;
      } else {
        _items.removeAt(index);
      }

      _calculateTotals();
      notifyListeners();
      _saveCart();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _calculateTotals();
      notifyListeners();
      _saveCart();
    }
  }

  void clear() {
    _items = [];
    _subtotal = 0;
    _tax = 0;
    _shipping = 0;
    _discount = 0;
    _couponCode = null;
    _loyaltyPointsUsed = 0;
    notifyListeners();
    _saveCart();
  }

  void applyCoupon(String code, double discountAmount) {
    _couponCode = code;
    _discount = discountAmount;
    notifyListeners();
    _saveCart();
  }

  void removeCoupon() {
    _couponCode = null;
    _discount = 0;
    notifyListeners();
    _saveCart();
  }

  void useLoyaltyPoints(int points) {
    _loyaltyPointsUsed = points;
    notifyListeners();
    _saveCart();
  }

  void _calculateTotals() {
    // Calculate subtotal
    _subtotal = _items.fold(0, (sum, item) => sum + item.total);

    // Calculate tax (e.g., 10%)
    _tax = _subtotal * 0.1;

    // Calculate shipping (e.g., flat rate or based on subtotal)
    if (_subtotal > 1000000) {
      _shipping = 0; // Free shipping for orders over 1,000,000 VND
    } else {
      _shipping = 30000; // Default shipping cost
    }
  }
}
