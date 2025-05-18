import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final double discountPercentage;
  final DateTime validUntil;
  final int? usageLimit;
  final int usageCount;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountPercentage,
    required this.validUntil,
    this.usageLimit,
    this.usageCount = 0,
  });

  factory CouponModel.fromMap(Map<String, dynamic> map, String id) {
    return CouponModel(
      id: id,
      code: map['code'] ?? '',
      discountPercentage: (map['discountPercentage'] ?? 0).toDouble(),
      validUntil: (map['validUntil'] as Timestamp).toDate(),
      usageLimit: map['usageLimit'],
      usageCount: map['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountPercentage': discountPercentage,
      'validUntil': Timestamp.fromDate(validUntil),
      'usageLimit': usageLimit,
      'usageCount': usageCount,
    };
  }

  bool get isValid {
    final now = DateTime.now();
    if (now.isAfter(validUntil)) {
      return false;
    }
    if (usageLimit != null && usageCount >= usageLimit!) {
      return false;
    }
    return true;
  }
}
