import 'package:ecommerce_app/screens/admin/admin_dashboard.dart';
import 'package:ecommerce_app/screens/auth/login_screen.dart';
import 'package:ecommerce_app/screens/auth/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../product/product_details_screen.dart';
import '../product/products_screen.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, List<ProductModel>> _featuredProducts = {};
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

      // Tải song song sản phẩm nổi bật và danh mục
      final results = await Future.wait([
        productService.getFeaturedProducts(),
        productService.getCategories(),
      ]);

      setState(() {
        _featuredProducts = results[0] as Map<String, List<ProductModel>>;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Danh sách màn hình bottom navigation
    final List<Widget> _pages = [
      _buildHomeContent(),
      ProductsScreen(),
      CartScreen(),
      authService.isLoggedIn ? ProfileScreen() : _buildLoginPrompt(),
      if (authService.isAdmin) AdminDashboard(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Máy tính & Linh kiện'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body:
          _selectedIndex < _pages.length
              ? _pages[_selectedIndex]
              : _buildHomeContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
          if (authService.isAdmin)
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Quản trị',
            ),
        ],
        currentIndex: _selectedIndex < _pages.length ? _selectedIndex : 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner section
              _buildBannerSection(),

              // Categories section
              _buildSectionTitle('Danh mục sản phẩm'),
              _buildCategoriesSection(),

              // Featured products sections
              if (_featuredProducts.containsKey('sale') &&
                  _featuredProducts['sale']!.isNotEmpty)
                _buildProductSection(
                  'Sản phẩm khuyến mại',
                  _featuredProducts['sale']!,
                ),

              if (_featuredProducts.containsKey('new') &&
                  _featuredProducts['new']!.isNotEmpty)
                _buildProductSection('Sản phẩm mới', _featuredProducts['new']!),

              if (_featuredProducts.containsKey('trending') &&
                  _featuredProducts['trending']!.isNotEmpty)
                _buildProductSection(
                  'Sản phẩm bán chạy',
                  _featuredProducts['trending']!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade100,
      ),
      child: Center(
        child: Text(
          'KHUYẾN MÃI ĐẶC BIỆT\nGiảm đến 50%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductsScreen(categoryId: category.id),
                ),
              );
            },
            child: Container(
              width: 100,
              margin: EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        category.image.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                category.image,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Icon(Icons.category, size: 40),
                  ),
                  SizedBox(height: 8),
                  Text(
                    category.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductsScreen()),
              );
            },
            child: Text('Xem tất cả'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(String title, List<ProductModel> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Container(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
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
        );
      },
      child: Container(
        width: 180,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRect(
          // Add ClipRect to clip overflowing content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: Container(
                  height: 180,
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
                // Use Expanded to constrain the height of the info section
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Minimize the column's height
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      if (product.discountPercentage != null &&
                          product.discountPercentage! > 0)
                        Row(
                          children: [
                            Text(
                              '${_formatCurrency(product.price)}đ',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
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
                      SizedBox(height: 4),
                      Text(
                        '${_formatCurrency(product.finalPrice)}đ',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Vui lòng đăng nhập để xem thông tin tài khoản',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Đăng nhập / Đăng ký'),
          ),
        ],
      ),
    );
  }
}
