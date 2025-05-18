import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String brand;
  final double price;
  final double? discountPercentage;
  final List<String> categories;
  final List<String> images;
  final List<ProductVariant> variants;
  final ProductRating ratings;
  final bool isNew;
  final bool isTrending;
  final bool isOnSale;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.price,
    this.discountPercentage,
    required this.categories,
    required this.images,
    required this.variants,
    required this.ratings,
    this.isNew = false,
    this.isTrending = false,
    this.isOnSale = false,
    required this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      brand: map['brand'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      discountPercentage:
          map['discountPercentage'] != null
              ? (map['discountPercentage'] as num).toDouble()
              : null,
      categories: List<String>.from(map['categories'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      variants:
          (map['variants'] as List?)
              ?.map((v) => ProductVariant.fromMap(v))
              .toList() ??
          [],
      ratings: ProductRating.fromMap(
        map['ratings'] ?? {'average': 0, 'count': 0},
      ),
      isNew: map['isNew'] ?? false,
      isTrending: map['isTrending'] ?? false,
      isOnSale: map['isOnSale'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'brand': brand,
      'price': price,
      'discountPercentage': discountPercentage,
      'categories': categories,
      'images': images,
      'variants': variants.map((v) => v.toMap()).toList(),
      'ratings': ratings.toMap(),
      'isNew': isNew,
      'isTrending': isTrending,
      'isOnSale': isOnSale,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Tính giá sau khi giảm giá
  double get finalPrice {
    if (discountPercentage != null && discountPercentage! > 0) {
      return price * (1 - discountPercentage! / 100);
    }
    return price;
  }
}

class ProductVariant {
  final String name;
  final int stock;

  ProductVariant({required this.name, required this.stock});

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(name: map['name'] ?? '', stock: map['stock'] ?? 0);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'stock': stock};
  }
}

class ProductRating {
  final double average;
  final int count;

  ProductRating({required this.average, required this.count});

  factory ProductRating.fromMap(Map<String, dynamic> map) {
    return ProductRating(
      average: (map['average'] ?? 0).toDouble(),
      count: map['count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'average': average, 'count': count};
  }
}
