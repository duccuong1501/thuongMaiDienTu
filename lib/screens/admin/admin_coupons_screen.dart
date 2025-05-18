import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';
import '../../models/coupon_model.dart';

class AdminCouponsScreen extends StatefulWidget {
  @override
  _AdminCouponsScreenState createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  bool _isLoading = true;
  List<CouponModel> _coupons = [];
  String _error = '';

  // Form controllers
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  int? _usageLimit;
  DateTime _validUntil = DateTime.now().add(Duration(days: 30));
  bool _isSaving = false;
  CouponModel? _editingCoupon;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final coupons = await orderService.getAllCoupons();

      setState(() {
        _coupons = coupons;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải mã giảm giá: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCouponDialog({CouponModel? coupon}) {
    setState(() {
      _editingCoupon = coupon;
      _codeController.text = coupon?.code ?? '';
      _discountController.text = coupon?.discountPercentage.toString() ?? '';
      _usageLimit = coupon?.usageLimit;
      _validUntil =
          coupon?.validUntil ?? DateTime.now().add(Duration(days: 30));
    });

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  _editingCoupon == null
                      ? 'Thêm mã giảm giá'
                      : 'Chỉnh sửa mã giảm giá',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Mã giảm giá',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _discountController,
                        decoration: InputDecoration(
                          labelText: 'Phần trăm giảm giá (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText:
                              'Giới hạn sử dụng (để trống nếu không giới hạn)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _usageLimit?.toString() ?? '',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _usageLimit =
                                value.isEmpty ? null : int.tryParse(value);
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _validUntil,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );

                          if (picked != null) {
                            setState(() {
                              _validUntil = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Có hiệu lực đến',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_validUntil),
                              ),
                              Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _isSaving
                            ? null
                            : () async {
                              if (_codeController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Vui lòng nhập mã giảm giá'),
                                  ),
                                );
                                return;
                              }

                              if (_discountController.text.isEmpty ||
                                  double.tryParse(_discountController.text) ==
                                      null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Vui lòng nhập phần trăm giảm giá hợp lệ',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final discount = double.parse(
                                _discountController.text,
                              );

                              if (discount <= 0 || discount > 50) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Phần trăm giảm giá phải từ 1-50%',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isSaving = true;
                              });

                              try {
                                final orderService = Provider.of<OrderService>(
                                  context,
                                  listen: false,
                                );

                                final coupon = CouponModel(
                                  id: _editingCoupon?.id ?? '',
                                  code: _codeController.text.toUpperCase(),
                                  discountPercentage: discount,
                                  validUntil: _validUntil,
                                  usageLimit: _usageLimit,
                                  usageCount: _editingCoupon?.usageCount ?? 0,
                                );

                                if (_editingCoupon == null) {
                                  // Add new coupon
                                  await orderService.addCoupon(coupon);
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Thêm mã giảm giá thành công',
                                      ),
                                    ),
                                  );
                                } else {
                                  // Update existing coupon
                                  await orderService.updateCoupon(coupon);
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cập nhật mã giảm giá thành công',
                                      ),
                                    ),
                                  );
                                }

                                Navigator.pop(context);
                                _loadCoupons();
                              } catch (e) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: ${e.toString()}'),
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _isSaving = false;
                                });
                              }
                            },
                    child:
                        _isSaving
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text('Lưu'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _deleteCoupon(String couponId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận xóa'),
            content: Text('Bạn có chắc muốn xóa mã giảm giá này?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                    final orderService = Provider.of<OrderService>(
                      context,
                      listen: false,
                    );
                    await orderService.deleteCoupon(couponId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xóa mã giảm giá thành công')),
                    );

                    _loadCoupons();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Xóa'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý mã giảm giá')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildCouponsList(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showCouponDialog(),
      ),
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
          ElevatedButton(onPressed: _loadCoupons, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildCouponsList() {
    if (_coupons.isEmpty) {
      return Center(child: Text('Chưa có mã giảm giá nào'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _coupons.length,
      itemBuilder: (context, index) {
        final coupon = _coupons[index];
        final isExpired = coupon.validUntil.isBefore(DateTime.now());
        final isLimitReached =
            coupon.usageLimit != null &&
            coupon.usageCount >= coupon.usageLimit!;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _showCouponDialog(coupon: coupon),
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
                        coupon.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color:
                              isExpired || isLimitReached
                                  ? Colors.grey
                                  : Colors.blue,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isExpired || isLimitReached
                                  ? Colors.grey.shade100
                                  : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isExpired
                              ? 'Hết hạn'
                              : isLimitReached
                              ? 'Đã dùng hết'
                              : 'Còn hiệu lực',
                          style: TextStyle(
                            color:
                                isExpired || isLimitReached
                                    ? Colors.grey
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giảm ${coupon.discountPercentage}%',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hạn: ${DateFormat('dd/MM/yyyy').format(coupon.validUntil)}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã dùng: ${coupon.usageCount}${coupon.usageLimit != null ? '/${coupon.usageLimit}' : ''}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Còn lại: ${coupon.usageLimit != null ? (coupon.usageLimit! - coupon.usageCount) : 'Không giới hạn'}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCouponDialog(coupon: coupon),
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCoupon(coupon.id),
                        tooltip: 'Xóa',
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
}
