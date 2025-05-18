import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/coupon_model.dart';
import 'firebase_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Tạo đơn hàng mới
  Future<String> createOrder({
    required String userId,
    required List<OrderItem> items,
    required double subtotal,
    required double tax,
    required double shipping,
    double discount = 0,
    int loyaltyPointsUsed = 0,
    String? couponCode,
    required Map<String, dynamic> address,
  }) async {
    try {
      // Tính tổng tiền
      double total = subtotal + tax + shipping - discount - loyaltyPointsUsed;
      if (total < 0) total = 0;

      // Tạo đơn hàng
      final orderData = {
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'shipping': shipping,
        'discount': discount,
        'total': total,
        'loyaltyPointsUsed': loyaltyPointsUsed,
        'couponCode': couponCode,
        'status': 'pending',
        'statusHistory': [
          {'status': 'pending', 'timestamp': Timestamp.now()},
        ],
        'address': address,
        'createdAt': Timestamp.now(),
      };

      DocumentReference orderRef = await _firestore
          .collection('orders')
          .add(orderData);

      // Cập nhật bảng user với đơn hàng mới
      await _firestore.collection('users').doc(userId).update({
        'orders': FieldValue.arrayUnion([orderRef.id]),
      });

      // Cập nhật số lượng sử dụng coupon nếu có
      if (couponCode != null && couponCode.isNotEmpty) {
        QuerySnapshot couponSnapshot =
            await _firestore
                .collection('coupons')
                .where('code', isEqualTo: couponCode)
                .limit(1)
                .get();

        if (couponSnapshot.docs.isNotEmpty) {
          String couponId = couponSnapshot.docs.first.id;
          await _firestore.collection('coupons').doc(couponId).update({
            'usageCount': FieldValue.increment(1),
          });
        }
      }

      // Nếu dùng điểm, cập nhật điểm của user
      if (loyaltyPointsUsed > 0) {
        await _firestore.collection('users').doc(userId).update({
          'loyaltyPoints': FieldValue.increment(-loyaltyPointsUsed),
        });
      }

      // Thêm điểm thưởng (10% tổng giá trị đơn hàng)
      int loyaltyPointsEarned = (total * 0.1).round();
      await _firestore.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(loyaltyPointsEarned),
      });

      // Cập nhật số lượng hàng tồn kho
      for (OrderItem item in items) {
        DocumentSnapshot productDoc =
            await _firestore.collection('products').doc(item.productId).get();
        if (productDoc.exists) {
          Map<String, dynamic> productData =
              productDoc.data() as Map<String, dynamic>;
          List<dynamic> variants = productData['variants'] ?? [];

          List<dynamic> updatedVariants =
              variants.map((variant) {
                if (variant['name'] == item.variant) {
                  int currentStock = variant['stock'] ?? 0;
                  return {...variant, 'stock': currentStock - item.quantity};
                }
                return variant;
              }).toList();

          await _firestore.collection('products').doc(item.productId).update({
            'variants': updatedVariants,
          });
        }
      }

      return orderRef.id;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Lấy đơn hàng của người dùng
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      print("Đang thử truy vấn orders với index...");
      // Thử truy vấn với sắp xếp (sẽ gây lỗi nếu index chưa sẵn sàng)
      QuerySnapshot snapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      print("Truy vấn orders với index thành công");
      return snapshot.docs
          .map(
            (doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Lỗi khi lấy đơn hàng với index: $e');

      // Nếu lỗi liên quan đến index, thực hiện truy vấn dự phòng
      if (e.toString().contains('index') ||
          e.toString().contains('failed-precondition') ||
          e.toString().contains('FAILED_PRECONDITION')) {
        print("Đang thực hiện truy vấn orders dự phòng không có sắp xếp...");
        try {
          // Truy vấn không có sắp xếp
          QuerySnapshot snapshot =
              await _firestore
                  .collection('orders')
                  .where('userId', isEqualTo: userId)
                  .get();

          print(
            "Truy vấn orders dự phòng thành công, đang sắp xếp kết quả thủ công...",
          );
          // Chuyển đổi dữ liệu
          List<OrderModel> orders =
              snapshot.docs
                  .map(
                    (doc) => OrderModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

          // Sắp xếp thủ công theo thời gian tạo (giảm dần)
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print("Đã sắp xếp ${orders.length} đơn hàng thành công");
          return orders;
        } catch (fallbackError) {
          print("Lỗi khi thực hiện truy vấn orders dự phòng: $fallbackError");
          rethrow;
        }
      }

      // Nếu lỗi không liên quan đến index, ném lại lỗi
      print("Lỗi không phải do index, ném lại lỗi gốc");
      rethrow;
    }
  } // Lấy chi tiết đơn hàng

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting order by id: $e');
      rethrow;
    }
  }

  // Cập nhật trạng thái đơn hàng (cho admin)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      DocumentSnapshot orderDoc =
          await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'statusHistory': FieldValue.arrayUnion([
          {'status': newStatus, 'timestamp': Timestamp.now()},
        ]),
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Kiểm tra mã giảm giá
  Future<CouponModel?> validateCoupon(String code, double orderTotal) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('coupons')
              .where('code', isEqualTo: code)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      DocumentSnapshot doc = snapshot.docs.first;
      CouponModel coupon = CouponModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      // Kiểm tra hạn sử dụng
      if (!coupon.isValid) {
        return null;
      }

      // Kiểm tra giá trị đơn hàng tối thiểu (nếu cần)
      double discountAmount = orderTotal * (coupon.discountPercentage / 100);

      return coupon;
    } catch (e) {
      print('Error validating coupon: $e');
      rethrow;
    }
  }

  // Admin: Lấy tất cả đơn hàng
  Future<List<OrderModel>> getAllOrders({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('orders');

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      if (startDate != null && endDate != null) {
        query = query
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            );
      } else if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      } else if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      query = query.orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error getting all orders: $e');
      rethrow;
    }
  }

  // Admin: Nhận thống kê đơn hàng
  Future<Map<String, dynamic>> getOrderStatistics({
    String period = 'yearly',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('orders');

      if (startDate != null && endDate != null) {
        query = query
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            );
      } else {
        // Mặc định lấy 1 năm gần nhất
        final today = DateTime.now();
        final oneYearAgo = DateTime(today.year - 1, today.month, today.day);
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(oneYearAgo),
        );
      }

      QuerySnapshot snapshot = await query.get();

      List<OrderModel> orders =
          snapshot.docs
              .map(
                (doc) => OrderModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Tính toán thống kê
      int totalOrders = orders.length;
      double totalRevenue = 0;
      double totalProfit = 0; // Giả sử lợi nhuận là 20% doanh thu

      // Dữ liệu theo thời gian
      Map<String, dynamic> timeData = {};

      for (OrderModel order in orders) {
        totalRevenue += order.total;
        totalProfit += order.total * 0.2;

        String timeKey;
        DateTime date = order.createdAt;

        if (period == 'yearly') {
          timeKey = date.year.toString();
        } else if (period == 'quarterly') {
          int quarter = (date.month - 1) ~/ 3 + 1;
          timeKey = '${date.year}-Q$quarter';
        } else if (period == 'monthly') {
          timeKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        } else if (period == 'weekly') {
          // Tính số tuần trong năm
          final firstDayOfYear = DateTime(date.year, 1, 1);
          final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
          int weekNumber = (daysSinceFirstDay / 7).ceil();
          timeKey = '${date.year}-W$weekNumber';
        } else {
          timeKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }

        if (!timeData.containsKey(timeKey)) {
          timeData[timeKey] = {
            'orders': 0,
            'revenue': 0.0,
            'profit': 0.0,
            'productCount': 0,
            'productTypes': <String>{},
          };
        }

        timeData[timeKey]['orders']++;
        timeData[timeKey]['revenue'] += order.total;
        timeData[timeKey]['profit'] += order.total * 0.2;

        // Số lượng sản phẩm và loại sản phẩm
        for (OrderItem item in order.items) {
          timeData[timeKey]['productCount'] += item.quantity;
          timeData[timeKey]['productTypes'].add(item.productId);
        }
      }

      // Chuyển đổi Set thành số lượng
      timeData.forEach((key, value) {
        value['productTypes'] = (value['productTypes'] as Set).length;
      });

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'totalProfit': totalProfit,
        'timeData': timeData,
      };
    } catch (e) {
      print('Error getting order statistics: $e');
      rethrow;
    }
  }

  // Admin: Thêm mã giảm giá
  Future<String> addCoupon(CouponModel coupon) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('coupons')
          .add(coupon.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding coupon: $e');
      rethrow;
    }
  }

  // Admin: Cập nhật mã giảm giá
  Future<void> updateCoupon(CouponModel coupon) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(coupon.id)
          .update(coupon.toMap());
    } catch (e) {
      print('Error updating coupon: $e');
      rethrow;
    }
  }

  // Admin: Xóa mã giảm giá
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _firestore.collection('coupons').doc(couponId).delete();
    } catch (e) {
      print('Error deleting coupon: $e');
      rethrow;
    }
  }

  // Lấy tất cả mã giảm giá
  Future<List<CouponModel>> getAllCoupons() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('coupons').get();

      return snapshot.docs
          .map(
            (doc) =>
                CouponModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error getting all coupons: $e');
      rethrow;
    }
  }
}
