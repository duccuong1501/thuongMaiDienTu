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
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      addresses: List<Map<String, dynamic>>.from(map['addresses'] ?? []),
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      orders: List<String>.from(map['orders'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] ?? false,
    );
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
