import 'package:ecommerce_app/screens/admin/admin_categories_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_coupons_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_orders_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_products_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_statistics_screen.dart';
import 'package:ecommerce_app/screens/admin/admin_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
// import 'admin_orders_screen.dart';
// import 'admin_products_screen.dart';
// import 'admin_categories_screen.dart';
// import 'admin_users_screen.dart';
// import 'admin_coupons_screen.dart';
// import 'admin_statistics_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      // Lấy thống kê đơn hàng trong 30 ngày gần nhất
      final today = DateTime.now();
      final thirtyDaysAgo = today.subtract(Duration(days: 30));

      final orderStats = await orderService.getOrderStatistics(
        period: 'monthly',
        startDate: thirtyDaysAgo,
        endDate: today,
      );

      // Lấy các đơn hàng mới nhất
      final recentOrders = await orderService.getAllOrders(
        limit: 5,
        status: 'pending',
      );

      setState(() {
        _dashboardData = {
          'orderStats': orderStats,
          'recentOrders': recentOrders,
        };
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Quản trị')),
        body: Center(child: Text('Bạn không có quyền truy cập trang này')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bảng điều khiển quản trị')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildDashboard(),
    );
  }

  Widget _buildErrorWidget() {
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
          ElevatedButton(onPressed: _loadDashboardData, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final orderStats = _dashboardData['orderStats'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          Text(
            'Tổng quan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Đơn hàng',
                  value: '${orderStats['totalOrders']}',
                  color: Colors.blue,
                  icon: Icons.shopping_bag,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Doanh thu',
                  value: '${_formatCurrency(orderStats['totalRevenue'])}đ',
                  color: Colors.green,
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Lợi nhuận',
                  value: '${_formatCurrency(orderStats['totalProfit'])}đ',
                  color: Colors.purple,
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Trung bình/đơn',
                  value:
                      '${_formatCurrency(orderStats['totalOrders'] > 0 ? orderStats['totalRevenue'] / orderStats['totalOrders'] : 0)}đ',
                  color: Colors.orange,
                  icon: Icons.receipt,
                ),
              ),
            ],
          ),

          SizedBox(height: 32),

          // Recent orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn hàng mới nhất',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminOrdersScreen(),
                    ),
                  );
                },
                child: Text('Xem tất cả'),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildRecentOrders(),

          SizedBox(height: 32),

          // Menu
          Text(
            'Quản lý hệ thống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMenuCard(
                title: 'Sản phẩm',
                icon: Icons.inventory,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProductsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                title: 'Đơn hàng',
                icon: Icons.shopping_bag,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminOrdersScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                title: 'Danh mục',
                icon: Icons.category,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminCategoriesScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                title: 'Người dùng',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminUsersScreen()),
                  );
                },
              ),
              _buildMenuCard(
                title: 'Mã giảm giá',
                icon: Icons.discount,
                color: Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminCouponsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                title: 'Thống kê',
                icon: Icons.insert_chart,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminStatisticsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    final recentOrders = _dashboardData['recentOrders'] as List<dynamic>;

    if (recentOrders.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Không có đơn hàng mới')),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: recentOrders.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final order = recentOrders[index];
          return ListTile(
            title: Text(
              'Đơn hàng #${order.id.substring(0, 8)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_formatDate(order.createdAt)} - ${_formatCurrency(order.total)}đ',
            ),
            trailing: _buildStatusBadge(order.status),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AdminOrdersScreen(initialOrderId: order.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
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
