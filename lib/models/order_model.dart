import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final int loyaltyPointsUsed;
  final String? couponCode;
  final String status;
  final List<StatusHistory> statusHistory;
  final Map<String, dynamic> address;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    this.discount = 0,
    required this.total,
    this.loyaltyPointsUsed = 0,
    this.couponCode,
    required this.status,
    required this.statusHistory,
    required this.address,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items:
          (map['items'] as List?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      shipping: (map['shipping'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      loyaltyPointsUsed: map['loyaltyPointsUsed'] ?? 0,
      couponCode: map['couponCode'],
      status: map['status'] ?? 'pending',
      statusHistory:
          (map['statusHistory'] as List?)
              ?.map((status) => StatusHistory.fromMap(status))
              .toList() ??
          [],
      address: Map<String, dynamic>.from(map['address'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'loyaltyPointsUsed': loyaltyPointsUsed,
      'couponCode': couponCode,
      'status': status,
      'statusHistory': statusHistory.map((status) => status.toMap()).toList(),
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String? variant;
  final int quantity;
  final double price;
  final double? discountedPrice;
  final String imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    this.variant,
    required this.quantity,
    required this.price,
    this.discountedPrice,
    required this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      variant: map['variant'],
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      discountedPrice:
          map['discountedPrice'] != null
              ? (map['discountedPrice'] as num).toDouble()
              : null,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'variant': variant,
      'quantity': quantity,
      'price': price,
      'discountedPrice': discountedPrice,
      'imageUrl': imageUrl,
    };
  }
}

class StatusHistory {
  final String status;
  final DateTime timestamp;

  StatusHistory({required this.status, required this.timestamp});

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      status: map['status'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'status': status, 'timestamp': Timestamp.fromDate(timestamp)};
  }
}
