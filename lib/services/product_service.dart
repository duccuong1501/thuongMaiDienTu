import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';
import 'firebase_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Lấy tất cả sản phẩm với phân trang
  Future<List<ProductModel>> getProducts({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? category,
    String? searchQuery,
    String? sortBy,
    bool descending = false,
    double? minPrice,
    double? maxPrice,
    String? brand,
  }) async {
    try {
      Query query = _firestore.collection('products');

      // Áp dụng bộ lọc
      if (category != null && category.isNotEmpty) {
        query = query.where('categories', arrayContains: category);
      }

      if (brand != null && brand.isNotEmpty) {
        query = query.where('brand', isEqualTo: brand);
      }

      // Lưu ý: Firestore không cho phép sử dụng nhiều lệnh where với các phép so sánh khác nhau
      // nên chúng ta sẽ lọc giá sau khi nhận kết quả

      // Áp dụng sắp xếp
      if (sortBy != null && sortBy.isNotEmpty) {
        query = query.orderBy(sortBy, descending: descending);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      // Áp dụng phân trang
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      QuerySnapshot snapshot = await query.get();

      List<ProductModel> products =
          snapshot.docs.map((doc) {
            return ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

      // Lọc theo giá và tìm kiếm
      if (minPrice != null || maxPrice != null || searchQuery != null) {
        products =
            products.where((product) {
              bool matchesPrice = true;
              if (minPrice != null) {
                matchesPrice = matchesPrice && product.price >= minPrice;
              }
              if (maxPrice != null) {
                matchesPrice = matchesPrice && product.price <= maxPrice;
              }

              bool matchesSearch = true;
              if (searchQuery != null && searchQuery.isNotEmpty) {
                final query = searchQuery.toLowerCase();
                matchesSearch =
                    product.name.toLowerCase().contains(query) ||
                    product.description.toLowerCase().contains(query) ||
                    product.brand.toLowerCase().contains(query);
              }

              return matchesPrice && matchesSearch;
            }).toList();
      }

      // Sắp xếp lại nếu cần (vì đã lọc sau khi nhận kết quả)
      if (sortBy == 'price') {
        products.sort(
          (a, b) =>
              descending
                  ? b.price.compareTo(a.price)
                  : a.price.compareTo(b.price),
        );
      } else if (sortBy == 'name') {
        products.sort(
          (a, b) =>
              descending ? b.name.compareTo(a.name) : a.name.compareTo(b.name),
        );
      }

      return products;
    } catch (e) {
      print('Error getting products: $e');
      rethrow;
    }
  }

  // Lấy sản phẩm nổi bật (mới, khuyến mãi, bán chạy)
  Future<Map<String, List<ProductModel>>> getFeaturedProducts({
    int limit = 6,
  }) async {
    try {
      Map<String, List<ProductModel>> featuredProducts = {
        'new': [],
        'sale': [],
        'trending': [],
      };

      // Sản phẩm mới
      QuerySnapshot newProducts =
          await _firestore
              .collection('products')
              .where('isNew', isEqualTo: true)
              .limit(limit)
              .get();

      featuredProducts['new'] =
          newProducts.docs
              .map(
                (doc) => ProductModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Sản phẩm khuyến mãi
      QuerySnapshot saleProducts =
          await _firestore
              .collection('products')
              .where('isOnSale', isEqualTo: true)
              .limit(limit)
              .get();

      featuredProducts['sale'] =
          saleProducts.docs
              .map(
                (doc) => ProductModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Sản phẩm bán chạy
      QuerySnapshot trendingProducts =
          await _firestore
              .collection('products')
              .where('isTrending', isEqualTo: true)
              .limit(limit)
              .get();

      featuredProducts['trending'] =
          trendingProducts.docs
              .map(
                (doc) => ProductModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      return featuredProducts;
    } catch (e) {
      print('Error getting featured products: $e');
      rethrow;
    }
  }

  // Lấy chi tiết sản phẩm
  Future<ProductModel?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting product by id: $e');
      rethrow;
    }
  }

  // Lấy các danh mục
  Future<List<CategoryModel>> getCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map(
            (doc) => CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  // Thêm đánh giá sản phẩm
  Future<void> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    try {
      // Thêm bình luận vào collection 'reviews'
      await _firestore.collection('reviews').add({
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      // Cập nhật xếp hạng trung bình của sản phẩm
      DocumentSnapshot productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (productDoc.exists) {
        Map<String, dynamic> productData =
            productDoc.data() as Map<String, dynamic>;

        double currentAvg = 0;
        int currentCount = 0;

        if (productData.containsKey('ratings')) {
          currentAvg = (productData['ratings']['average'] ?? 0).toDouble();
          currentCount = (productData['ratings']['count'] ?? 0);
        }

        double newAvg =
            (currentAvg * currentCount + rating) / (currentCount + 1);

        await _firestore.collection('products').doc(productId).update({
          'ratings': {'average': newAvg, 'count': currentCount + 1},
        });
      }
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  // Lấy đánh giá của sản phẩm
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('reviews')
              .where('productId', isEqualTo: productId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error getting product reviews: $e');
      rethrow;
    }
  }

  // Lấy các thương hiệu (brands)
  Future<List<String>> getBrands() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('products').get();

      Set<String> brands = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('brand') && data['brand'] != null) {
          brands.add(data['brand']);
        }
      }

      return brands.toList()..sort();
    } catch (e) {
      print('Error getting brands: $e');
      rethrow;
    }
  }

  // Admin: Thêm sản phẩm mới
  Future<String> addProduct(ProductModel product) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('products')
          .add(product.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // Admin: Cập nhật sản phẩm
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Admin: Xóa sản phẩm
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();

      // Xóa các đánh giá liên quan
      QuerySnapshot reviews =
          await _firestore
              .collection('reviews')
              .where('productId', isEqualTo: productId)
              .get();

      for (var doc in reviews.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Admin: Thêm danh mục
  Future<String> addCategory(CategoryModel category) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('categories')
          .add(category.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  // Admin: Cập nhật danh mục
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Admin: Xóa danh mục
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}
