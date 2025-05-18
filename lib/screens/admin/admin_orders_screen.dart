import 'package:ecommerce_app/screens/admin/order_detail_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String? initialOrderId;

  const AdminOrdersScreen({Key? key, this.initialOrderId}) : super(key: key);

  @override
  _AdminOrdersScreenState createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      final orders = await orderService.getAllOrders(
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _orders = orders;
      });

      // If initial order ID is provided, navigate to its details
      if (widget.initialOrderId != null) {
        _navigateToOrderDetail(widget.initialOrderId!);
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải đơn hàng: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToOrderDetail(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailAdminScreen(orderId: orderId),
      ),
    ).then((_) => _loadOrders());
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Lọc đơn hàng'),
                content: Container(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Status filter
                      Text(
                        'Trạng thái',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String?>(
                        value: _selectedStatus,
                        isExpanded: true,
                        hint: Text('Tất cả trạng thái'),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả trạng thái'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'pending',
                            child: Text('Chờ xác nhận'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'confirmed',
                            child: Text('Đã xác nhận'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'shipped',
                            child: Text('Đang vận chuyển'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'delivered',
                            child: Text('Đã giao hàng'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'cancelled',
                            child: Text('Đã hủy'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Date range picker
                      Text(
                        'Thời gian',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text('Từ ngày'),
                              subtitle: Text(
                                _startDate != null
                                    ? _formatDate(_startDate!)
                                    : 'Chọn ngày',
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );

                                if (picked != null) {
                                  setState(() {
                                    _startDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text('Đến ngày'),
                              subtitle: Text(
                                _endDate != null
                                    ? _formatDate(_endDate!)
                                    : 'Chọn ngày',
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );

                                if (picked != null) {
                                  setState(() {
                                    _endDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _startDate = DateTime.now().subtract(
                                  Duration(days: 7),
                                );
                                _endDate = DateTime.now();
                              });
                            },
                            child: Text('7 ngày'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _startDate = DateTime.now().subtract(
                                  Duration(days: 30),
                                );
                                _endDate = DateTime.now();
                              });
                            },
                            child: Text('30 ngày'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _startDate = DateTime.now().subtract(
                                  Duration(days: 90),
                                );
                                _endDate = DateTime.now();
                              });
                            },
                            child: Text('90 ngày'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Reset filters
                      this.setState(() {
                        _selectedStatus = null;
                        _startDate = null;
                        _endDate = null;
                      });
                      Navigator.pop(context);
                      _loadOrders();
                    },
                    child: Text('Đặt lại'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadOrders();
                    },
                    child: Text('Áp dụng'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đơn hàng'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildOrdersList(),
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
          ElevatedButton(onPressed: _loadOrders, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy đơn hàng nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy thử thay đổi bộ lọc để tìm kiếm',
              textAlign: TextAlign.center,
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
            onTap: () => _navigateToOrderDetail(order.id),
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
                  Text(
                    'Khách hàng: ${order.address['name']}',
                    style: TextStyle(fontSize: 14),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => _navigateToOrderDetail(order.id),
                        child: Text('Chi tiết'),
                      ),
                      if (order.status == 'pending')
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final orderService = Provider.of<OrderService>(
                                context,
                                listen: false,
                              );
                              await orderService.updateOrderStatus(
                                order.id,
                                'confirmed',
                              );
                              _loadOrders();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã xác nhận đơn hàng')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: ${e.toString()}')),
                              );
                            }
                          },
                          child: Text('Xác nhận'),
                        ),
                    ],
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
