import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  OrderModel? _order;
  String _error = '';

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
          // Order details
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
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trạng thái:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _buildStatusBadge(_order!.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Order tracking
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theo dõi đơn hàng',
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
                              Text(
                                _getStatusDescription(status.status),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
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

          // Shipping info
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin giao hàng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Người nhận: ${_order!.address['name']}'),
                  Text('Điện thoại: ${_order!.address['phone']}'),
                  Text('Email: ${_order!.address['email']}'),
                  Text(
                    'Địa chỉ: ${_order!.address['street']}, ${_order!.address['district']}, ${_order!.address['city']}',
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
                        Text('Giảm giá:'),
                        Text('-${_formatCurrency(_order!.discount)}đ'),
                      ],
                    ),
                  ],
                  if (_order!.loyaltyPointsUsed > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Điểm sử dụng:'),
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
        ],
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

    String statusText = _getStatusText(status);

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

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Đơn hàng của bạn đang chờ xác nhận.';
      case 'confirmed':
        return 'Đơn hàng của bạn đã được xác nhận.';
      case 'shipped':
        return 'Đơn hàng của bạn đang được vận chuyển.';
      case 'delivered':
        return 'Đơn hàng của bạn đã được giao thành công.';
      case 'cancelled':
        return 'Đơn hàng của bạn đã bị hủy.';
      default:
        return 'Đơn hàng đang được xử lý.';
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
