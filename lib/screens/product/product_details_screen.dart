import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../cart/cart_provider.dart';
import '../auth/login_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isLoading = true;
  ProductModel? _product;
  List<ReviewModel> _reviews = [];
  String? _selectedVariant;
  int _quantity = 1;
  int _currentImageIndex = 0;
  double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final FocusNode _reviewFocusNode = FocusNode();
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _reviewFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final productService = Provider.of<ProductService>(
        context,
        listen: false,
      );

      // Tải song song sản phẩm và đánh giá
      final results = await Future.wait([
        productService.getProductById(widget.productId),
        productService.getProductReviews(widget.productId),
      ]);

      final product = results[0] as ProductModel?;
      final reviews = results[1] as List<ReviewModel>;

      if (product == null) {
        throw Exception('Không tìm thấy sản phẩm');
      }

      setState(() {
        _product = product;
        _reviews = reviews;
        if (product.variants.isNotEmpty) {
          _selectedVariant = product.variants.first.name;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu sản phẩm: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isLoggedIn) {
      _showLoginDialog();
      return;
    }

    if (_userRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vui lòng chọn số sao đánh giá')));
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vui lòng nhập nhận xét')));
      return;
    }

    try {
      final productService = Provider.of<ProductService>(
        context,
        listen: false,
      );
      await productService.addReview(
        productId: widget.productId,
        userId: authService.user!.uid,
        userName: authService.userModel?.fullName ?? 'Người dùng',
        rating: _userRating,
        comment: _reviewController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã gửi đánh giá thành công')));

      // Reset form and reload reviews
      setState(() {
        _userRating = 0;
        _reviewController.clear();
      });

      _reviewFocusNode.unfocus();

      // Tải lại sản phẩm và đánh giá
      _loadProduct();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Đăng nhập'),
            content: Text('Bạn cần đăng nhập để đánh giá sản phẩm.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Đăng nhập'),
              ),
            ],
          ),
    );
  }

  void _addToCart() {
    if (_product == null) return;

    if (_product!.variants.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn phiên bản sản phẩm')),
      );
      return;
    }

    // Kiểm tra số lượng tồn kho
    if (_product!.variants.isNotEmpty) {
      final selectedVariantObj = _product!.variants.firstWhere(
        (v) => v.name == _selectedVariant,
      );

      if (selectedVariantObj.stock < _quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Số lượng vượt quá hàng tồn kho')),
        );
        return;
      }
    }

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.addItem(
        productId: _product!.id,
        name: _product!.name,
        price: _product!.finalPrice,
        variant: _selectedVariant,
        quantity: _quantity,
        image: _product!.images.isNotEmpty ? _product!.images.first : '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm sản phẩm vào giỏ hàng'),
          action: SnackBarAction(
            label: 'XEM GIỎ HÀNG',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết sản phẩm')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorWidget()
              : _buildProductDetails(),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
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
          ElevatedButton(onPressed: _loadProduct, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    if (_product == null) return Container();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product images
          _buildImageGallery(),

          // Product info
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name and rating
                Text(
                  _product!.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Rating stars
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (_product!.ratings.average.round())
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${_product!.ratings.average.toStringAsFixed(1)} (${_product!.ratings.count} đánh giá)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                // Price
                SizedBox(height: 16),
                if (_product!.discountPercentage != null &&
                    _product!.discountPercentage! > 0)
                  Row(
                    children: [
                      Text(
                        '${_formatCurrency(_product!.price)}đ',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${_product!.discountPercentage!.toInt()}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 4),
                Text(
                  '${_formatCurrency(_product!.finalPrice)}đ',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),

                // Brand
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Thương hiệu:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Text(_product!.brand),
                  ],
                ),

                // Variants
                if (_product!.variants.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Phiên bản:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _product!.variants.map((variant) {
                          bool isSelected = variant.name == _selectedVariant;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVariant = variant.name;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color:
                                    isSelected
                                        ? Colors.blue.shade50
                                        : Colors.white,
                              ),
                              child: Text(
                                '${variant.name} (${variant.stock > 0 ? 'Còn hàng' : 'Hết hàng'})',
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],

                // Quantity
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Số lượng:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed:
                                _quantity > 1
                                    ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                    : null,
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(),
                            iconSize: 16,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_quantity',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(),
                            iconSize: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description
                SizedBox(height: 24),
                Text(
                  'Mô tả sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(_product!.description),

                // Reviews
                SizedBox(height: 24),
                Text(
                  'Đánh giá sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildReviewInput(),
                SizedBox(height: 16),
                _buildReviewsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (_product == null || _product!.images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        child: Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          child: PageView.builder(
            itemCount: _product!.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                _product!.images[index],
                fit: BoxFit.contain,
              );
            },
          ),
        ),
        if (_product!.images.length > 1)
          Container(
            height: 80,
            margin: EdgeInsets.only(top: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _product!.images.length,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                bool isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _product!.images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thêm đánh giá của bạn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _userRating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() {
                  _userRating = index + 1.0;
                });
              },
              padding: EdgeInsets.all(0),
              constraints: BoxConstraints(),
            );
          }),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          focusNode: _reviewFocusNode,
          decoration: InputDecoration(
            hintText: 'Nhập nhận xét của bạn...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _submitReview,
            child: Text('Gửi đánh giá'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Chưa có đánh giá nào cho sản phẩm này'),
        ),
      );
    }

    return Column(
      children:
          _reviews.map((review) {
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review.userName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  SizedBox(height: 8),
                  Text(review.comment),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Thêm vào giỏ hàng'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _addToCart();
                Navigator.pushNamed(context, '/cart');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Mua ngay'),
            ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
