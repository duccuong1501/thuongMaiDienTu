import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final List<Map<String, dynamic>> addresses;
  final int loyaltyPoints;
  final List<String> orders;
  final DateTime createdAt;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.addresses = const [],
    this.loyaltyPoints = 0,
    this.orders = const [],
    required this.createdAt,
    this.isAdmin = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    try {
      // In dữ liệu cho mục đích gỡ lỗi
      print("Dữ liệu thô từ Firestore: $map");

      // Xử lý addresses một cách an toàn
      List<Map<String, dynamic>> addressesList = [];
      if (map['addresses'] != null) {
        if (map['addresses'] is List) {
          // Chuyển đổi từng phần tử một cách an toàn
          for (var item in map['addresses']) {
            if (item is Map) {
              // Chuyển đổi từ Map<dynamic, dynamic> sang Map<String, dynamic>
              Map<String, dynamic> addressMap = {};
              item.forEach((key, value) {
                if (key is String) {
                  addressMap[key] = value;
                }
              });
              addressesList.add(addressMap);
            }
          }
        }
      }

      // Xử lý orders một cách an toàn
      List<String> ordersList = [];
      if (map['orders'] != null) {
        if (map['orders'] is List) {
          for (var item in map['orders']) {
            if (item is String) {
              ordersList.add(item);
            } else if (item != null) {
              // Chuyển đổi sang String nếu có thể
              ordersList.add(item.toString());
            }
          }
        }
      }

      // Xử lý createdAt an toàn
      DateTime createdAtDate;
      if (map['createdAt'] is Timestamp) {
        createdAtDate = (map['createdAt'] as Timestamp).toDate();
      } else {
        createdAtDate = DateTime.now();
      }

      return UserModel(
        id: id,
        email: map['email'] ?? '',
        fullName: map['fullName'] ?? '',
        addresses: addressesList,
        loyaltyPoints: map['loyaltyPoints'] ?? 0,
        orders: ordersList,
        createdAt: createdAtDate,
        isAdmin: map['isAdmin'] ?? false,
      );
    } catch (e) {
      print("Lỗi khi chuyển đổi UserModel: $e");
      // Trả về model cơ bản để tránh crash
      return UserModel(
        id: id,
        email: map['email'] ?? '',
        fullName: map['fullName'] ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'addresses': addresses,
      'loyaltyPoints': loyaltyPoints,
      'orders': orders,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    List<Map<String, dynamic>>? addresses,
    int? loyaltyPoints,
    List<String>? orders,
    DateTime? createdAt,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      addresses: addresses ?? this.addresses,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      orders: orders ?? this.orders,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
