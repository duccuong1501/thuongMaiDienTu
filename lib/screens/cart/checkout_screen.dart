import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import 'cart_provider.dart';
import '../../models/order_model.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Customer info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Shipping address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // Payment method
  String _paymentMethod = 'cod';

  // Loyalty points
  bool _useLoyaltyPoints = false;
  int _availableLoyaltyPoints = 0;

  bool _isPlacingOrder = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isLoggedIn && authService.userModel != null) {
      final user = authService.userModel!;

      setState(() {
        _nameController.text = user.fullName;
        _emailController.text = user.email;
        _availableLoyaltyPoints = user.loyaltyPoints;

        if (user.addresses.isNotEmpty) {
          final address = user.addresses.first;
          _phoneController.text = address['phone'] ?? '';
          _addressController.text = address['street'] ?? '';
          _cityController.text = address['city'] ?? '';
          _districtController.text = address['district'] ?? '';
          _zipCodeController.text = address['zipCode'] ?? '';
        }
      });
    }
  }

  void _toggleLoyaltyPoints(bool? value) {
    if (value == null) return;

    setState(() {
      _useLoyaltyPoints = value;
    });

    final cart = Provider.of<CartProvider>(context, listen: false);

    if (_useLoyaltyPoints) {
      cart.useLoyaltyPoints(_availableLoyaltyPoints);
    } else {
      cart.useLoyaltyPoints(0);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPlacingOrder = true;
      _error = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      final cart = Provider.of<CartProvider>(context, listen: false);

      // Prepare order items
      List<OrderItem> orderItems =
          cart.items.map((item) {
            return OrderItem(
              productId: item.productId,
              productName: item.name,
              variant: item.variant,
              quantity: item.quantity,
              price: item.price,
              imageUrl: item.image,
            );
          }).toList();

      // Prepare shipping address
      Map<String, dynamic> shippingAddress = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'street': _addressController.text,
        'city': _cityController.text,
        'district': _districtController.text,
        'zipCode': _zipCodeController.text,
        'country': 'Vietnam',
      };

      // Save user address if logged in
      if (authService.isLoggedIn) {
        try {
          // Kiểm tra xem document người dùng có tồn tại không
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(authService.user!.uid)
                  .get();

          if (!userDoc.exists) {
            // Tạo document người dùng mới nếu chưa tồn tại
            await FirebaseFirestore.instance
                .collection('users')
                .doc(authService.user!.uid)
                .set({
                  'id': authService.user!.uid,
                  'email': authService.user!.email,
                  'fullName': _nameController.text,
                  'addresses': [shippingAddress],
                  'loyaltyPoints': 0,
                  'orders': [],
                  'createdAt': Timestamp.now(),
                  'isAdmin': false,
                });
          } else {
            // Cập nhật địa chỉ
            bool addressExists = false;
            List<Map<String, dynamic>> addresses = [];

            if (authService.userModel != null) {
              addresses = List<Map<String, dynamic>>.from(
                authService.userModel!.addresses,
              );

              for (var i = 0; i < addresses.length; i++) {
                if (addresses[i]['street'] == _addressController.text &&
                    addresses[i]['city'] == _cityController.text) {
                  addressExists = true;
                  break;
                }
              }
            }

            if (!addressExists) {
              addresses.add(shippingAddress);

              await authService.updateProfile(_nameController.text, addresses);
            }
          }
        } catch (addressError) {
          print("Lỗi khi lưu địa chỉ: $addressError");
          // Tiếp tục đặt hàng ngay cả khi không thể lưu địa chỉ
        }
      }

      // Create order
      String orderId = await orderService.createOrder(
        userId: authService.isLoggedIn ? authService.user!.uid : 'guest',
        items: orderItems,
        subtotal: cart.subtotal,
        tax: cart.tax,
        shipping: cart.shipping,
        discount: cart.discount,
        loyaltyPointsUsed: _useLoyaltyPoints ? _availableLoyaltyPoints : 0,
        couponCode: cart.couponCode,
        address: shippingAddress,
      );

      // Clear cart
      cart.clear();

      // Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessScreen(orderId: orderId),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi đặt hàng: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isPlacingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thanh toán')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _placeOrder();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            } else {
              Navigator.pop(context);
            }
          },
          steps: [
            Step(
              title: Text('Thông tin khách hàng'),
              content: _buildCustomerInfoStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: Text('Địa chỉ giao hàng'),
              content: _buildShippingAddressStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: Text('Thanh toán'),
              content: _buildPaymentStep(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập họ và tên';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập số điện thoại';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildShippingAddressStep() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Địa chỉ',
            prefixIcon: Icon(Icons.home),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập địa chỉ';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _districtController,
          decoration: InputDecoration(
            labelText: 'Quận/Huyện',
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập quận/huyện';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'Tỉnh/Thành phố',
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tỉnh/thành phố';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _zipCodeController,
          decoration: InputDecoration(
            labelText: 'Mã bưu điện',
            prefixIcon: Icon(Icons.markunread_mailbox),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final cart = Provider.of<CartProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phương thức thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        RadioListTile<String>(
          title: Text('Thanh toán khi nhận hàng (COD)'),
          value: 'cod',
          groupValue: _paymentMethod,
          onChanged: (value) {
            setState(() {
              _paymentMethod = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('Chuyển khoản ngân hàng'),
          value: 'bank',
          groupValue: _paymentMethod,
          onChanged: (value) {
            setState(() {
              _paymentMethod = value!;
            });
          },
        ),

        if (_paymentMethod == 'bank') ...[
          SizedBox(height: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin chuyển khoản:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Ngân hàng: MBBank'),
                  Text('Số tài khoản: 0123456789'),
                  Text('Chủ tài khoản: CÔNG TY TNHH ABC'),
                  Text('Nội dung: Thanh toán đơn hàng [Họ tên]'),
                ],
              ),
            ),
          ),
        ],

        SizedBox(height: 24),

        // Loyalty points
        if (_availableLoyaltyPoints > 0) ...[
          Row(
            children: [
              Checkbox(
                value: _useLoyaltyPoints,
                onChanged: _toggleLoyaltyPoints,
              ),
              Expanded(
                child: Text(
                  'Sử dụng $_availableLoyaltyPoints điểm tích lũy (${_formatCurrency(_availableLoyaltyPoints.toDouble())}đ)',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],

        // Order summary
        Text('Tóm tắt đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),

        // Cart items
        ...cart.items.map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.quantity}x'),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.variant != null)
                        Text(
                          'Phiên bản: ${item.variant}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text('${_formatCurrency(item.total)}đ'),
              ],
            ),
          );
        }).toList(),

        Divider(),

        // Totals
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tạm tính:'),
            Text('${_formatCurrency(cart.subtotal)}đ'),
          ],
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Thuế (10%):'),
            Text('${_formatCurrency(cart.tax)}đ'),
          ],
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Phí vận chuyển:'),
            Text('${_formatCurrency(cart.shipping)}đ'),
          ],
        ),
        if (cart.discount > 0) ...[
          SizedBox(height: 4),
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
        if (_useLoyaltyPoints) ...[
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Điểm sử dụng:'),
              Text(
                '-${_formatCurrency(_availableLoyaltyPoints.toDouble())}đ',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
        ],
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${_formatCurrency(cart.total)}đ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),

        if (_error.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(_error, style: TextStyle(color: Colors.red)),
        ],

        SizedBox(height: 16),

        if (_isPlacingOrder) Center(child: CircularProgressIndicator()),
      ],
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
