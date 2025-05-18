import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

class OrderDetailAdminScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailAdminScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  _OrderDetailAdminScreenState createState() => _OrderDetailAdminScreenState();
}

class _OrderDetailAdminScreenState extends State<OrderDetailAdminScreen> {
  bool _isLoading = true;
  OrderModel? _order;
  String _error = '';
  String? _newStatus;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final order = await orderService.getOrderById(widget.orderId);

      setState(() {
        _order = order;
        _newStatus = order?.status;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải thông tin đơn hàng: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus() async {
    if (_newStatus == null || _newStatus == _order?.status) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.updateOrderStatus(widget.orderId, _newStatus!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cập nhật trạng thái thành công')));

      _loadOrderDetails();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết đơn hàng')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildOrderDetails(),
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
          ElevatedButton(onPressed: _loadOrderDetails, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (_order == null) {
      return Center(child: Text('Không tìm thấy thông tin đơn hàng'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and status
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
                        'Mã đơn hàng:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_order!.id),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ngày đặt:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_formatDate(_order!.createdAt)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cập nhật trạng thái',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _newStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Chờ xác nhận'),
                      ),
                      DropdownMenuItem(
                        value: 'confirmed',
                        child: Text('Đã xác nhận'),
                      ),
                      DropdownMenuItem(
                        value: 'shipped',
                        child: Text('Đang vận chuyển'),
                      ),
                      DropdownMenuItem(
                        value: 'delivered',
                        child: Text('Đã giao hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Đã hủy'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _newStatus = value;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdatingStatus ? null : _updateOrderStatus,
                      child:
                          _isUpdatingStatus
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text('Cập nhật trạng thái'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Status history
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch sử trạng thái',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...List.generate(_order!.statusHistory.length, (index) {
                    final status = _order!.statusHistory[index];
                    final isLast = index == 0;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    isLast ? Colors.blue : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child:
                                  isLast
                                      ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                      : null,
                            ),
                            if (index != _order!.statusHistory.length - 1)
                              Container(
                                width: 2,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                          ],
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getStatusText(status.status),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isLast ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(status.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Customer info
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin khách hàng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Tên: ${_order!.address['name']}'),
                  Text('Email: ${_order!.address['email']}'),
                  Text('Điện thoại: ${_order!.address['phone']}'),
                  Text(
                    'Địa chỉ: ${_order!.address['street']}, ${_order!.address['district']}, ${_order!.address['city']}',
                  ),

                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Điều hướng đến màn hình xem chi tiết người dùng
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => UserDetailScreen(userId: _order!.userId),
                      //   ),
                      // );
                    },
                    icon: Icon(Icons.person),
                    label: Text('Xem thông tin người dùng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Order items
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sản phẩm đã đặt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...List.generate(_order!.items.length, (index) {
                    final item = _order!.items[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (item.variant != null)
                                  Text(
                                    'Phiên bản: ${item.variant}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                Text(
                                  'Số lượng: ${item.quantity}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_formatCurrency(item.price * item.quantity)}đ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),

                  Divider(),

                  // Order summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tạm tính:'),
                      Text('${_formatCurrency(_order!.subtotal)}đ'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thuế:'),
                      Text('${_formatCurrency(_order!.tax)}đ'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vận chuyển:'),
                      Text('${_formatCurrency(_order!.shipping)}đ'),
                    ],
                  ),
                  if (_order!.discount > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _order!.couponCode != null
                              ? 'Giảm giá (${_order!.couponCode}):'
                              : 'Giảm giá:',
                        ),
                        Text('-${_formatCurrency(_order!.discount)}đ'),
                      ],
                    ),
                  ],
                  if (_order!.loyaltyPointsUsed > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Điểm đã dùng:'),
                        Text(
                          '-${_formatCurrency(_order!.loyaltyPointsUsed.toDouble())}đ',
                        ),
                      ],
                    ),
                  ],
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_formatCurrency(_order!.total)}đ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Quick actions for admin
          Row(
            children: [
              if (_order!.status == 'pending') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _newStatus = 'confirmed';
                      });
                      _updateOrderStatus();
                    },
                    icon: Icon(Icons.check),
                    label: Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
              if (_order!.status == 'confirmed') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _newStatus = 'shipped';
                      });
                      _updateOrderStatus();
                    },
                    icon: Icon(Icons.local_shipping),
                    label: Text('Vận chuyển'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
              if (_order!.status == 'shipped') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _newStatus = 'delivered';
                      });
                      _updateOrderStatus();
                    },
                    icon: Icon(Icons.done_all),
                    label: Text('Đã giao'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
              if (_order!.status != 'cancelled' &&
                  _order!.status != 'delivered') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _newStatus = 'cancelled';
                      });
                      _updateOrderStatus();
                    },
                    icon: Icon(Icons.cancel),
                    label: Text('Hủy đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipped':
        return 'Đang vận chuyển';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
