import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';

class AdminStatisticsScreen extends StatefulWidget {
  @override
  _AdminStatisticsScreenState createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  String _period = 'monthly';
  DateTime? _startDate;
  DateTime? _endDate;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Mặc định là 6 tháng gần nhất
    _startDate = DateTime.now().subtract(Duration(days: 180));
    _endDate = DateTime.now();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final statistics = await orderService.getOrderStatistics(
        period: _period,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _statistics = statistics;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải thống kê: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê doanh thu'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _showDateRangePicker,
            tooltip: 'Chọn khoảng thời gian',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildStatisticsContent(),
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
          ElevatedButton(onPressed: _loadStatistics, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    final totalOrders = _statistics['totalOrders'] ?? 0;
    final totalRevenue = _statistics['totalRevenue'] ?? 0.0;
    final totalProfit = _statistics['totalProfit'] ?? 0.0;
    final timeData = _statistics['timeData'] as Map<String, dynamic>? ?? {};

    // Sắp xếp dữ liệu theo thời gian
    final sortedTimeData =
        timeData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khoảng thời gian',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Từ ${DateFormat('dd/MM/yyyy').format(_startDate!)} đến ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _showDateRangePicker,
                        child: Text('Thay đổi'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPeriodButton('yearly', 'Năm'),
                      SizedBox(width: 8),
                      _buildPeriodButton('quarterly', 'Quý'),
                      SizedBox(width: 8),
                      _buildPeriodButton('monthly', 'Tháng'),
                      SizedBox(width: 8),
                      _buildPeriodButton('weekly', 'Tuần'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Đơn hàng',
                          totalOrders.toString(),
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Doanh thu',
                          '${_formatCurrency(totalRevenue)}đ',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Lợi nhuận',
                          '${_formatCurrency(totalProfit)}đ',
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'TB/đơn',
                          '${_formatCurrency(totalOrders > 0 ? totalRevenue / totalOrders : 0)}đ',
                          Icons.receipt,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Time-based data
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết theo thời gian',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  sortedTimeData.isEmpty
                      ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Không có dữ liệu trong khoảng thời gian này',
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: sortedTimeData.length,
                        itemBuilder: (context, index) {
                          final entry = sortedTimeData[index];
                          final timeKey = entry.key;
                          final data = entry.value;

                          return ListTile(
                            title: Text(
                              _formatTimeKey(timeKey),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text('Đơn hàng: ${data['orders']}'),
                                Text(
                                  'Doanh thu: ${_formatCurrency(data['revenue'])}đ',
                                ),
                                Text(
                                  'Lợi nhuận: ${_formatCurrency(data['profit'])}đ',
                                ),
                                Text(
                                  'Sản phẩm đã bán: ${data['productCount']}',
                                ),
                                Text('Loại sản phẩm: ${data['productTypes']}'),
                              ],
                            ),
                            tileColor:
                                index % 2 == 0 ? Colors.grey.shade50 : null,
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _period == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _period = value;
          });
          _loadStatistics();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  String _formatTimeKey(String timeKey) {
    if (_period == 'yearly') {
      return 'Năm $timeKey';
    } else if (_period == 'quarterly') {
      final parts = timeKey.split('-Q');
      return 'Quý ${parts[1]} năm ${parts[0]}';
    } else if (_period == 'monthly') {
      final parts = timeKey.split('-');
      final month = int.parse(parts[1]);
      final year = parts[0];

      final monthNames = [
        'Tháng 1',
        'Tháng 2',
        'Tháng 3',
        'Tháng 4',
        'Tháng 5',
        'Tháng 6',
        'Tháng 7',
        'Tháng 8',
        'Tháng 9',
        'Tháng 10',
        'Tháng 11',
        'Tháng 12',
      ];

      return '${monthNames[month - 1]} năm $year';
    } else if (_period == 'weekly') {
      final parts = timeKey.split('-W');
      return 'Tuần ${parts[1]} năm ${parts[0]}';
    }

    return timeKey;
  }
}
