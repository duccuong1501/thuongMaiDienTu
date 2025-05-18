import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? categoryId;

  const ProductsScreen({Key? key, this.categoryId}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<String> _brands = [];
  String? _selectedCategory;
  String? _selectedBrand;
  String _sortBy = 'newest';
  double _minPrice = 0;
  double _maxPrice = 50000000;
  final TextEditingController _searchController = TextEditingController();
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  String _error = '';

  // Lọc hiện tại
  RangeValues _currentRangeValues = RangeValues(0, 50000000);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryId;
    _loadFilters();
    _loadProducts(initial: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final productService = Provider.of<ProductService>(
        context,
        listen: false,
      );

      // Tải song song danh mục và thương hiệu
      final results = await Future.wait([
        productService.getCategories(),
        productService.getBrands(),
      ]);

      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _brands = results[1] as List<String>;
      });
    } catch (e) {
      print('Error loading filters: $e');
    }
  }

  Future<void> _loadProducts({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _lastDocument = null;
        _products = [];
        _hasMore = true;
        _error = '';
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;

      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final productService = Provider.of<ProductService>(
        context,
        listen: false,
      );

      // Chuyển đổi sortBy thành field và hướng sắp xếp
      String? sortField;
      bool descending = false;

      switch (_sortBy) {
        case 'newest':
          sortField = 'createdAt';
          descending = true;
          break;
        case 'price_asc':
          sortField = 'price';
          descending = false;
          break;
        case 'price_desc':
          sortField = 'price';
          descending = true;
          break;
        case 'name_asc':
          sortField = 'name';
          descending = false;
          break;
        case 'name_desc':
          sortField = 'name';
          descending = true;
          break;
      }

      List<ProductModel> newProducts = await productService.getProducts(
        limit: 10,
        startAfter: _lastDocument,
        category: _selectedCategory,
        searchQuery: _searchController.text.trim(),
        sortBy: sortField,
        descending: descending,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        brand: _selectedBrand,
      );

      if (newProducts.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        setState(() {
          if (initial) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }

          if (newProducts.length < 10) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải sản phẩm: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _minPrice = _currentRangeValues.start;
      _maxPrice = _currentRangeValues.end;
    });
    _loadProducts(initial: true);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = widget.categoryId;
      _selectedBrand = null;
      _sortBy = 'newest';
      _minPrice = 0;
      _maxPrice = 50000000;
      _currentRangeValues = RangeValues(0, 50000000);
      _searchController.clear();
    });
    _loadProducts(initial: true);
    Navigator.pop(context);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Lọc sản phẩm'),
                content: Container(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Danh mục
                      Text(
                        'Danh mục',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String?>(
                        value: _selectedCategory,
                        isExpanded: true,
                        hint: Text('Tất cả danh mục'),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả danh mục'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem<String?>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Thương hiệu
                      Text(
                        'Thương hiệu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String?>(
                        value: _selectedBrand,
                        isExpanded: true,
                        hint: Text('Tất cả thương hiệu'),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả thương hiệu'),
                          ),
                          ..._brands.map((brand) {
                            return DropdownMenuItem<String?>(
                              value: brand,
                              child: Text(brand),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedBrand = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Giá
                      Text(
                        'Khoảng giá',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      RangeSlider(
                        values: _currentRangeValues,
                        min: 0,
                        max: 50000000,
                        divisions: 100,
                        labels: RangeLabels(
                          '${_formatCurrency(_currentRangeValues.start)}đ',
                          '${_formatCurrency(_currentRangeValues.end)}đ',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _currentRangeValues = values;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatCurrency(_currentRangeValues.start)}đ',
                          ),
                          Text('${_formatCurrency(_currentRangeValues.end)}đ'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: _resetFilters, child: Text('Đặt lại')),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: Text('Áp dụng'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sản phẩm'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchBar(),

          // Sort options
          _buildSortBar(),

          // Products grid
          Expanded(
            child:
                _isLoading && _products.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty && _products.isEmpty
                    ? _buildErrorWidget()
                    : _products.isEmpty
                    ? _buildEmptyState()
                    : _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _loadProducts(initial: true),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _loadProducts(initial: true),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Text('Sắp xếp:'),
          SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortButton('newest', 'Mới nhất'),
                  _buildSortButton('price_asc', 'Giá tăng dần'),
                  _buildSortButton('price_desc', 'Giá giảm dần'),
                  _buildSortButton('name_asc', 'Tên A-Z'),
                  _buildSortButton('name_desc', 'Tên Z-A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String value, String label) {
    bool isSelected = _sortBy == value;

    return Container(
      margin: EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _sortBy = value;
          });
          _loadProducts(initial: true);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          if (_hasMore && !_isLoadingMore) {
            _loadProducts();
          }
        }
        return true;
      },
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            return _isLoadingMore
                ? Center(child: CircularProgressIndicator())
                : SizedBox();
          }

          return _buildProductCard(_products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productId: product.id),
          ),
        ).then((_) => _loadProducts(initial: true));
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  child:
                      product.images.isNotEmpty
                          ? Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image, size: 40),
                          ),
                ),
              ),
              // Product info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(6), // Reduced from 8 to 6
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, // Slightly smaller
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1), // Reduced from 2 to 1
                      if (product.discountPercentage != null &&
                          product.discountPercentage! > 0)
                        Row(
                          children: [
                            Text(
                              '${_formatCurrency(product.price)}đ',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 11, // Smaller font
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1, // Reduced vertical padding
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${product.discountPercentage!.toInt()}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9, // Smaller font
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 1), // Reduced from 2 to 1
                      Text(
                        '${_formatCurrency(product.finalPrice)}đ',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13, // Reduced from 14
                        ),
                      ),
                      SizedBox(height: 1), // Reduced from 2 to 1
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 12,
                          ), // Smaller icon
                          SizedBox(width: 2),
                          Text(
                            '${product.ratings.average.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 11), // Smaller font
                          ),
                          Text(
                            ' (${product.ratings.count})',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác hoặc thay đổi bộ lọc',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetFilters,
            child: Text('Đặt lại bộ lọc'),
          ),
        ],
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
          ElevatedButton(
            onPressed: () => _loadProducts(initial: true),
            child: Text('Thử lại'),
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
}
