import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Phương thức chính để thêm dữ liệu mẫu
  static Future<void> seedAll({bool forceUpdate = false}) async {
    try {
      // Kiểm tra xem đã tồn tại dữ liệu chưa
      final categoriesSnapshot =
          await _firestore.collection('categories').limit(1).get();
      final productsSnapshot =
          await _firestore.collection('products').limit(1).get();

      // Chỉ thêm dữ liệu nếu chưa có hoặc forceUpdate = true
      if (forceUpdate || categoriesSnapshot.docs.isEmpty) {
        await _seedCategories();
      }

      if (forceUpdate || productsSnapshot.docs.isEmpty) {
        await _seedProducts();
      }

      await _seedCoupons();
      await _seedUsers();

      print('Đã thêm dữ liệu mẫu thành công!');
    } catch (e) {
      print('Lỗi khi thêm dữ liệu mẫu: $e');
    }
  }

  // Thêm danh mục
  static Future<void> _seedCategories() async {
    final categories = [
      {
        'name': 'Laptop',
        'image':
            'https://images.unsplash.com/photo-1611078489935-0cb964de46d6?w=500&auto=format',
      },
      {
        'name': 'Màn hình',
        'image':
            'https://images.unsplash.com/photo-1527219525722-f9767a7f2884?w=500&auto=format',
      },
      {
        'name': 'Bàn phím',
        'image':
            'https://images.unsplash.com/photo-1563191911-e65f8893877c?w=500&auto=format',
      },
      {
        'name': 'Chuột',
        'image':
            'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=500&auto=format',
      },
      {
        'name': 'Ổ cứng',
        'image':
            'https://images.unsplash.com/photo-1627398242454-45a1465c2479?w=500&auto=format',
      },
      {
        'name': 'RAM',
        'image':
            'https://images.unsplash.com/photo-1562976540-1502c2145186?w=500&auto=format',
      },
      {
        'name': 'Card đồ họa',
        'image':
            'https://images.unsplash.com/photo-1591489378430-ef2f4c626b35?w=500&auto=format',
      },
    ];

    print('Thêm ${categories.length} danh mục...');

    for (var category in categories) {
      await _firestore.collection('categories').add(category);
    }
  }

  // Thêm sản phẩm
  static Future<void> _seedProducts() async {
    // Lấy danh mục từ Firebase
    final categorySnapshot = await _firestore.collection('categories').get();
    final categories = <String, String>{};
    categorySnapshot.docs.forEach((doc) {
      categories[doc.data()['name'] as String] = doc.id;
    });

    final products = [
      {
        'name': 'Laptop Dell XPS 13',
        'description':
            'Laptop cao cấp từ Dell với màn hình InfinityEdge.\nCPU: Intel Core i7-1185G7\nRAM: 16GB LPDDR4x\nỔ cứng: 512GB PCIe NVMe SSD\nMàn hình: 13.4 inch FHD+ (1920 x 1200)\nHệ điều hành: Windows 11 Home\n\nThiết kế mỏng nhẹ, hiệu năng mạnh mẽ, thời lượng pin cả ngày.',
        'brand': 'Dell',
        'price': 32000000,
        'discountPercentage': 10,
        'categories': ['Laptop'],
        'images': [
          'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=500&auto=format',
          'https://images.unsplash.com/photo-1593642634524-b40b5baae6bb?w=500&auto=format',
          'https://images.unsplash.com/photo-1593642634315-48f5414c3ad9?w=500&auto=format',
        ],
        'variants': [
          {'name': 'i5/8GB/256GB', 'stock': 10},
          {'name': 'i7/16GB/512GB', 'stock': 5},
        ],
        'ratings': {'average': 4.8, 'count': 24},
        'isNew': true,
        'isTrending': true,
        'isOnSale': true,
      },
      {
        'name': 'Màn hình LG UltraGear 27GL850',
        'description':
            'Màn hình gaming 27 inch với tốc độ làm mới 144Hz.\nKích thước: 27 inch\nĐộ phân giải: 2560 x 1440 (QHD)\nTỉ lệ khung hình: 16:9\nTấm nền: IPS\nTần số quét: 144Hz\nThời gian phản hồi: 1ms\n\nMàn hình gaming chuyên nghiệp với độ phân giải cao và tốc độ làm mới nhanh.',
        'brand': 'LG',
        'price': 9500000,
        'discountPercentage': 5,
        'categories': ['Màn hình'],
        'images': [
          'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=500&auto=format',
          'https://images.unsplash.com/photo-1587614298142-0ba36e27fb41?w=500&auto=format',
          'https://images.unsplash.com/photo-1555375771-14b2a63968a9?w=500&auto=format',
        ],
        'variants': [
          {'name': '27 inch', 'stock': 15},
          {'name': '32 inch', 'stock': 7},
        ],
        'ratings': {'average': 4.7, 'count': 18},
        'isNew': false,
        'isTrending': true,
        'isOnSale': true,
      },
      {
        'name': 'Bàn phím cơ Logitech G Pro X',
        'description':
            'Bàn phím cơ chơi game chuyên nghiệp với switch có thể thay thế.\nKiểu: Bàn phím cơ\nKết nối: Có dây\nSwitch: GX Blue Clicky (có thể thay thế)\nĐèn nền: RGB 16.8 triệu màu\nPhím chức năng: Có\n\nBàn phím cơ cao cấp cho game thủ chuyên nghiệp với thiết kế nhỏ gọn.',
        'brand': 'Logitech',
        'price': 3200000,
        'discountPercentage': null,
        'categories': ['Bàn phím'],
        'images': [
          'https://images.unsplash.com/photo-1595225476474-87563907a212?w=500&auto=format',
          'https://images.unsplash.com/photo-1608322368835-b8e1301b38f0?w=500&auto=format',
          'https://images.unsplash.com/photo-1601445638532-3c6f6c3aa1d6?w=500&auto=format',
        ],
        'variants': [
          {'name': 'GX Blue Clicky', 'stock': 12},
          {'name': 'GX Red Linear', 'stock': 8},
          {'name': 'GX Brown Tactile', 'stock': 10},
        ],
        'ratings': {'average': 4.5, 'count': 32},
        'isNew': false,
        'isTrending': false,
        'isOnSale': false,
      },
      {
        'name': 'Chuột gaming Razer DeathAdder V2',
        'description':
            'Chuột gaming với cảm biến quang học 20.000 DPI.\nCảm biến: Razer Focus+ Optical\nDPI: 20.000\nNút: 8 nút có thể lập trình\nKết nối: Có dây\nĐèn: Razer Chroma RGB\nTrọng lượng: 82g\n\nChuột gaming hiệu suất cao với thiết kế công thái học tiện lợi.',
        'brand': 'Razer',
        'price': 1700000,
        'discountPercentage': 15,
        'categories': ['Chuột'],
        'images': [
          'https://images.unsplash.com/photo-1605773527852-c546a8584ea3?w=500&auto=format',
          'https://images.unsplash.com/photo-1613141411244-0e4ac259d217?w=500&auto=format',
          'https://images.unsplash.com/photo-1629429407756-446d66f5b24e?w=500&auto=format',
        ],
        'variants': [
          {'name': 'Đen', 'stock': 20},
          {'name': 'Trắng', 'stock': 15},
        ],
        'ratings': {'average': 4.6, 'count': 45},
        'isNew': false,
        'isTrending': true,
        'isOnSale': true,
      },
      {
        'name': 'Ổ cứng SSD Samsung 970 EVO Plus',
        'description':
            'Ổ cứng SSD NVMe với tốc độ đọc/ghi cao.\nDung lượng: 1TB\nGiao tiếp: PCIe Gen 3.0 x4, NVMe 1.3\nTốc độ đọc tuần tự: lên đến 3,500 MB/s\nTốc độ ghi tuần tự: lên đến 3,300 MB/s\nTuổi thọ: 600 TBW\n\nỔ cứng SSD hiệu suất cao cho máy tính để bàn và laptop.',
        'brand': 'Samsung',
        'price': 3400000,
        'discountPercentage': null,
        'categories': ['Ổ cứng'],
        'images': [
          'https://images.unsplash.com/photo-1597138804456-e7dca7f59d54?w=500&auto=format',
          'https://images.unsplash.com/photo-1628557044797-f21a177c37ec?w=500&auto=format',
          'https://images.unsplash.com/photo-1628557044644-b9c9775e7eed?w=500&auto=format',
        ],
        'variants': [
          {'name': '500GB', 'stock': 25},
          {'name': '1TB', 'stock': 18},
          {'name': '2TB', 'stock': 8},
        ],
        'ratings': {'average': 4.9, 'count': 56},
        'isNew': true,
        'isTrending': false,
        'isOnSale': false,
      },
      {
        'name': 'RAM Corsair Vengeance RGB Pro',
        'description':
            'Bộ nhớ RAM DDR4 với đèn RGB có thể tùy chỉnh.\nDung lượng: 16GB (2x8GB)\nLoại: DDR4\nTốc độ: 3200MHz\nĐèn LED: RGB\nCL: 16-18-18-36\nĐiện áp: 1.35V\n\nRAM hiệu suất cao với thiết kế đẹp mắt và khả năng tương thích rộng rãi.',
        'brand': 'Corsair',
        'price': 2200000,
        'discountPercentage': 7,
        'categories': ['RAM'],
        'images': [
          'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=500&auto=format',
          'https://images.unsplash.com/photo-1592664474505-51c549ad15c5?w=500&auto=format',
          'https://images.unsplash.com/photo-1541029071515-84cb9d7377ba?w=500&auto=format',
        ],
        'variants': [
          {'name': '16GB (2x8GB)', 'stock': 30},
          {'name': '32GB (2x16GB)', 'stock': 15},
          {'name': '64GB (2x32GB)', 'stock': 5},
        ],
        'ratings': {'average': 4.7, 'count': 38},
        'isNew': false,
        'isTrending': true,
        'isOnSale': true,
      },
      {
        'name': 'Card đồ họa NVIDIA GeForce RTX 4080',
        'description':
            'Card đồ họa cao cấp cho game thủ và người sáng tạo nội dung.\nBộ nhớ: 16GB GDDR6X\nInterfase: PCI Express 4.0\nClock: 2205 MHz (Boost)\nCuda Cores: 9728\nLõi RT: 76\nLõi Tensor: 304\n\nHiệu suất đồ họa vượt trội với công nghệ ray tracing thế hệ mới.',
        'brand': 'NVIDIA',
        'price': 25000000,
        'discountPercentage': null,
        'categories': ['Card đồ họa'],
        'images': [
          'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=500&auto=format',
          'https://images.unsplash.com/photo-1582647509707-632c9109d99d?w=500&auto=format',
          'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=500&auto=format',
        ],
        'variants': [
          {'name': 'Founders Edition', 'stock': 3},
          {'name': 'ASUS ROG Strix', 'stock': 4},
          {'name': 'MSI Gaming X', 'stock': 2},
        ],
        'ratings': {'average': 4.9, 'count': 15},
        'isNew': true,
        'isTrending': true,
        'isOnSale': false,
      },
      {
        'name': 'Laptop Gaming Asus ROG Strix G15',
        'description':
            'Laptop gaming mạnh mẽ với hệ thống làm mát tiên tiến.\nCPU: AMD Ryzen 7 6800H\nGPU: NVIDIA GeForce RTX 3070\nRAM: 16GB DDR5\nỔ cứng: 1TB NVMe SSD\nMàn hình: 15.6" FHD, 300Hz\nHệ điều hành: Windows 11 Home\n\nLaptop gaming cao cấp với thiết kế mạnh mẽ và hiệu suất vượt trội.',
        'brand': 'Asus',
        'price': 38000000,
        'discountPercentage': 12,
        'categories': ['Laptop'],
        'images': [
          'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=500&auto=format',
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500&auto=format',
          'https://images.unsplash.com/photo-1593642532973-d31b6557fa68?w=500&auto=format',
        ],
        'variants': [
          {'name': 'RTX 3060/16GB', 'stock': 8},
          {'name': 'RTX 3070/16GB', 'stock': 5},
          {'name': 'RTX 3080/32GB', 'stock': 3},
        ],
        'ratings': {'average': 4.8, 'count': 22},
        'isNew': true,
        'isTrending': true,
        'isOnSale': true,
      },
    ];

    print('Thêm ${products.length} sản phẩm...');

    for (var product in products) {
      // Map các ID danh mục
      final List<String> categoryNames =
          (product['categories'] as List).cast<String>();
      final List<String> categoryIds =
          categoryNames
              .map((catName) => categories[catName] ?? '')
              .where((id) => id.isNotEmpty)
              .toList();

      final newProduct = Map<String, dynamic>.from(product);
      newProduct['categories'] = categoryIds;
      newProduct['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('products').add(newProduct);
    }
  }

  // Thêm mã giảm giá
  static Future<void> _seedCoupons() async {
    // Kiểm tra xem đã có mã giảm giá nào chưa
    final couponsSnapshot =
        await _firestore.collection('coupons').limit(1).get();
    if (couponsSnapshot.docs.isNotEmpty) {
      print('Đã có dữ liệu mã giảm giá. Bỏ qua bước thêm mã giảm giá.');
      return;
    }

    final coupons = [
      {
        'code': 'WELCOME10',
        'discountPercentage': 10,
        'validUntil': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 30)),
        ),
        'usageLimit': 100,
        'usageCount': 0,
      },
      {
        'code': 'SUMMER25',
        'discountPercentage': 25,
        'validUntil': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 90)),
        ),
        'usageLimit': 50,
        'usageCount': 0,
      },
      {
        'code': 'FLASH50',
        'discountPercentage': 50,
        'validUntil': Timestamp.fromDate(DateTime.now().add(Duration(days: 2))),
        'usageLimit': 20,
        'usageCount': 0,
      },
    ];

    print('Thêm ${coupons.length} mã giảm giá...');

    for (var coupon in coupons) {
      await _firestore.collection('coupons').add(coupon);
    }
  }

  // Thêm người dùng
  static Future<void> _seedUsers() async {
    try {
      // Kiểm tra xem đã có tài khoản admin chưa
      final adminQuery =
          await _firestore
              .collection('users')
              .where('isAdmin', isEqualTo: true)
              .limit(1)
              .get();

      if (adminQuery.docs.isNotEmpty) {
        print('Đã có tài khoản admin. Bỏ qua bước thêm người dùng.');
        return;
      }

      print('Tạo tài khoản người dùng mẫu...');

      // Tạo tài khoản admin
      UserCredential adminCredential = await _auth
          .createUserWithEmailAndPassword(
            email: 'admin@example.com',
            password: 'admin123',
          );

      await _firestore.collection('users').doc(adminCredential.user!.uid).set({
        'email': 'admin@example.com',
        'fullName': 'Admin User',
        'isAdmin': true,
        'loyaltyPoints': 1000,
        'addresses': [
          {
            'name': 'Admin User',
            'phone': '0912345678',
            'street': '123 Admin Street',
            'district': 'District 1',
            'city': 'Ho Chi Minh City',
            'zipCode': '70000',
          },
        ],
        'orders': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Tạo tài khoản người dùng thông thường
      UserCredential user1Credential = await _auth
          .createUserWithEmailAndPassword(
            email: 'user1@example.com',
            password: 'password123',
          );

      await _firestore.collection('users').doc(user1Credential.user!.uid).set({
        'email': 'user1@example.com',
        'fullName': 'Nguyen Van A',
        'isAdmin': false,
        'loyaltyPoints': 500,
        'addresses': [
          {
            'name': 'Nguyen Van A',
            'phone': '0901234567',
            'street': '456 Customer Road',
            'district': 'District 2',
            'city': 'Ho Chi Minh City',
            'zipCode': '70000',
          },
        ],
        'orders': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      UserCredential user2Credential = await _auth
          .createUserWithEmailAndPassword(
            email: 'user2@example.com',
            password: 'password123',
          );

      await _firestore.collection('users').doc(user2Credential.user!.uid).set({
        'email': 'user2@example.com',
        'fullName': 'Tran Thi B',
        'isAdmin': false,
        'loyaltyPoints': 200,
        'addresses': [
          {
            'name': 'Tran Thi B',
            'phone': '0907654321',
            'street': '789 User Street',
            'district': 'District 3',
            'city': 'Ho Chi Minh City',
            'zipCode': '70000',
          },
          {
            'name': 'Tran Thi B (Công ty)',
            'phone': '0907654321',
            'street': '101 Office Building',
            'district': 'District 1',
            'city': 'Ho Chi Minh City',
            'zipCode': '70000',
          },
        ],
        'orders': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Đã tạo tài khoản người dùng thành công.');
    } catch (e) {
      // Nếu có lỗi khi tạo người dùng (có thể là do người dùng đã tồn tại)
      // Chỉ ghi log và tiếp tục
      print('Lưu ý khi tạo tài khoản người dùng: $e');
    }
  }
}
