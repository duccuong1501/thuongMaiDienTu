import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../models/coupon_model.dart';
import 'checkout_screen.dart';
import '../auth/login_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isValidatingCoupon = false;
  String _couponError = '';

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = '';
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);

      CouponModel? coupon = await orderService.validateCoupon(
        code,
        cart.subtotal,
      );

      if (coupon == null || !coupon.isValid) {
        setState(() {
          _couponError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn';
        });
      } else {
        // Calculate discount amount
        double discountAmount =
            cart.subtotal * (coupon.discountPercentage / 100);

        // Apply coupon to cart
        cart.applyCoupon(code, discountAmount);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã áp dụng mã giảm giá thành công')),
        );

        // Clear coupon field
        _couponController.clear();
      }
    } catch (e) {
      setState(() {
        _couponError = 'Lỗi: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isValidatingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.removeCoupon();
  }

  void _proceedToCheckout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Giỏ hàng của bạn đang trống')));
      return;
    }

    if (authService.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CheckoutScreen()),
      );
    } else {
      // Ask user to login or continue as guest
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Đăng nhập'),
              content: Text(
                'Bạn cần đăng nhập để tiếp tục thanh toán. Bạn muốn đăng nhập ngay?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CheckoutScreen()),
                    );
                  },
                  child: Text('Tiếp tục không đăng nhập'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('Đăng nhập'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giỏ hàng')),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              // Cart items list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(item, index);
                  },
                ),
              ),

              // Cart summary
              _buildCartSummary(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy thêm sản phẩm vào giỏ hàng để tiếp tục',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/products');
            },
            child: Text('Tiếp tục mua sắm'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                child:
                    item.image.isNotEmpty
                        ? Image.network(item.image, fit: BoxFit.cover)
                        : Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, size: 40),
                        ),
              ),
            ),
            SizedBox(width: 16),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variant != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Phiên bản: ${item.variant}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  SizedBox(height: 4),
                  Text(
                    '${_formatCurrency(item.price)}đ',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed:
                                  item.quantity > 1
                                      ? () {
                                        final cart = Provider.of<CartProvider>(
                                          context,
                                          listen: false,
                                        );
                                        cart.updateQuantity(
                                          index,
                                          item.quantity - 1,
                                        );
                                      }
                                      : null,
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              iconSize: 16,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.quantity}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                final cart = Provider.of<CartProvider>(
                                  context,
                                  listen: false,
                                );
                                cart.updateQuantity(index, item.quantity + 1);
                              },
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              iconSize: 16,
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          final cart = Provider.of<CartProvider>(
                            context,
                            listen: false,
                          );
                          cart.removeItem(index);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Coupon code
          if (cart.couponCode == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã giảm giá',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      errorText: _couponError.isNotEmpty ? _couponError : null,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValidatingCoupon ? null : _validateCoupon,
                  child:
                      _isValidatingCoupon
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text('Áp dụng'),
                ),
              ],
            ),
            SizedBox(height: 16),
          ] else ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã giảm giá: ${cart.couponCode}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Giảm ${_formatCurrency(cart.discount)}đ',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: _removeCoupon,
                ),
              ],
            ),
            SizedBox(height: 16),
          ],

          // Cart totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tạm tính:'),
              Text('${_formatCurrency(cart.subtotal)}đ'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thuế (10%):'),
              Text('${_formatCurrency(cart.tax)}đ'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí vận chuyển:'),
              Text('${_formatCurrency(cart.shipping)}đ'),
            ],
          ),
          if (cart.discount > 0) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giảm giá:'),
                Text(
                  '-${_formatCurrency(cart.discount)}đ',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ],
          if (cart.loyaltyPointsUsed > 0) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Điểm sử dụng:'),
                Text(
                  '-${_formatCurrency(cart.loyaltyPointsUsed.toDouble())}đ',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ],
          Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${_formatCurrency(cart.total)}đ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _proceedToCheckout,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text('Tiến hành thanh toán'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
