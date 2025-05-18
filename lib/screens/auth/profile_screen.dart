import 'package:ecommerce_app/screens/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../cart/order_details_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingOrders = true;
  List<OrderModel> _orders = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoadingOrders = true;
      _error = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);

      if (authService.isLoggedIn) {
        final orders = await orderService.getUserOrders(authService.user!.uid);

        setState(() {
          _orders = orders;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải đơn hàng: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đăng xuất: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isLoggedIn) {
      return Center(
        child: Text('Vui lòng đăng nhập để xem thông tin tài khoản'),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tài khoản'),
          actions: [
            TextButton(
              onPressed: _logout,
              child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Thông tin cá nhân'),
              Tab(text: 'Đơn hàng của tôi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildProfileTab(authService), _buildOrdersTab()],
        ),
      ),
    );
  }

  Widget _buildProfileTab(AuthService authService) {
    final user = authService.userModel;

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, size: 50, color: Colors.blue),
                ),
                SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
                SizedBox(height: 8),
                Text(
                  'Thành viên từ ${_formatDate(user.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Loyalty points
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.orange, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điểm tích lũy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${user.loyaltyPoints} điểm (${_formatCurrency(user.loyaltyPoints.toDouble())}đ)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Addresses
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        child: Text('Chỉnh sửa'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (user.addresses.isEmpty)
                    Text('Chưa có địa chỉ nào')
                  else
                    ...user.addresses.map((address) {
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address['name'] ?? user.fullName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (address['phone'] != null)
                              Text('SĐT: ${address['phone']}'),
                            SizedBox(height: 4),
                            Text(
                              '${address['street'] ?? ''}, ${address['district'] ?? ''}, ${address['city'] ?? ''}',
                            ),
                            if (address != user.addresses.last)
                              Divider(height: 16),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Admin panel link
          if (user.isAdmin)
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to admin dashboard
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminDashboard()),
                );
              },
              icon: Icon(Icons.admin_panel_settings),
              label: Text('Quản trị viên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),

          SizedBox(height: 16),

          // Logout button
          ElevatedButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout),
            label: Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOrders, child: Text('Thử lại')),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Bạn chưa có đơn hàng nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy mua sắm để bắt đầu tích lũy điểm',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/products');
              },
              child: Text('Mua sắm ngay'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(orderId: order.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đơn hàng #${order.id.substring(0, 8)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ngày đặt: ${_formatDate(order.createdAt)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${order.items.length} sản phẩm - ${_formatCurrency(order.total)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (order.items.isNotEmpty)
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            order.items.first.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.items.first.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order.items.length > 1)
                          Text(
                            '+${order.items.length - 1} sản phẩm khác',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    OrderDetailsScreen(orderId: order.id),
                          ),
                        );
                      },
                      child: Text('Xem chi tiết'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'shipped':
        color = Colors.purple;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    String statusText;

    switch (status) {
      case 'pending':
        statusText = 'Chờ xác nhận';
        break;
      case 'confirmed':
        statusText = 'Đã xác nhận';
        break;
      case 'shipped':
        statusText = 'Đang vận chuyển';
        break;
      case 'delivered':
        statusText = 'Đã giao hàng';
        break;
      case 'cancelled':
        statusText = 'Đã hủy';
        break;
      default:
        statusText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
