import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import 'edit_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  @override
  _AdminProductsScreenState createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _isLoading = true;
  List<ProductModel> _products = [];
  String _searchQuery = '';
  String? _selectedCategory;
  List<CategoryModel> _categories = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final productService = Provider.of<ProductService>(
        context,
        listen: false,
      );

      // Tải song song sản phẩm và danh mục
      final results = await Future.wait([
        productService.getProducts(limit: 100),
        productService.getCategories(),
      ]);

      final products = results[0] as List<ProductModel>;
      final categories = results[1] as List<CategoryModel>;

      setState(() {
        _products = products;
        _categories = categories;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((product) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesCategory =
          _selectedCategory == null ||
          product.categories.contains(_selectedCategory);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận xóa'),
            content: Text('Bạn có chắc muốn xóa sản phẩm này?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                    final productService = Provider.of<ProductService>(
                      context,
                      listen: false,
                    );
                    await productService.deleteProduct(productId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xóa sản phẩm thành công')),
                    );

                    _loadData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Xóa'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý sản phẩm'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProductScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
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
              ],
            ),
          ),

          // Products list
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                    ? _buildErrorWidget()
                    : _filteredProducts.isEmpty
                    ? Center(child: Text('Không tìm thấy sản phẩm nào'))
                    : _buildProductsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditProductScreen()),
          ).then((_) => _loadData());
        },
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
          ElevatedButton(onPressed: _loadData, child: Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: product),
                ),
              ).then((_) => _loadData());
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        product.images.isNotEmpty
                            ? Image.network(
                              product.images.first,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image, size: 40),
                            ),
                  ),
                  SizedBox(width: 16),

                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thương hiệu: ${product.brand}',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (product.discountPercentage != null &&
                                product.discountPercentage! > 0)
                              Text(
                                '${_formatCurrency(product.price)}đ',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            SizedBox(width: 4),
                            Text(
                              '${_formatCurrency(product.finalPrice)}đ',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product.discountPercentage != null &&
                                product.discountPercentage! > 0)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${product.discountPercentage!.toInt()}%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                'Tồn kho: ${product.variants.fold(0, (sum, variant) => sum + variant.stock)}',
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue.shade100,
                            ),
                            SizedBox(width: 8),
                            if (product.isNew)
                              Chip(
                                label: Text(
                                  'Mới',
                                  style: TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.green.shade100,
                              ),
                            if (product.isTrending)
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Chip(
                                  label: Text(
                                    'Bán chạy',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.orange.shade100,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      EditProductScreen(product: product),
                            ),
                          ).then((_) => _loadData());
                        },
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product.id),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
