import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = true;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _userModel?.isAdmin ?? false;

  // Constructor
  AuthService() {
    _initAuthListener();
  }

  // Initialize auth state listener
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _getUserData();
      } else {
        _userModel = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // Get user data from Firestore
  Future<void> _getUserData() async {
    try {
      if (_user == null) return;

      print("Đang lấy dữ liệu người dùng cho UID: ${_user!.uid}");
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (doc.exists) {
        try {
          final userData = doc.data() as Map<String, dynamic>;
          print("Dữ liệu người dùng từ Firestore: $userData");

          _userModel = UserModel.fromMap(userData, doc.id);
          print("Tạo UserModel thành công: ${_userModel?.fullName}");
        } catch (conversionError) {
          print("Lỗi khi chuyển đổi dữ liệu người dùng: $conversionError");

          // Tạo UserModel cơ bản để tránh crash
          _userModel = UserModel(
            id: _user!.uid,
            email: _user!.email ?? '',
            fullName: _user!.displayName ?? '',
            createdAt: DateTime.now(),
          );
        }
      } else {
        print("Không tìm thấy dữ liệu người dùng trong Firestore");
        _userModel = UserModel(
          id: _user!.uid,
          email: _user!.email ?? '',
          fullName: _user!.displayName ?? '',
          createdAt: DateTime.now(),
        );
      }
      notifyListeners();
    } catch (e) {
      print('Lỗi khi lấy dữ liệu người dùng: $e');
      // Khởi tạo một model cơ bản để tránh crash
      _userModel = UserModel(
        id: _user!.uid,
        email: _user!.email ?? '',
        fullName: _user!.displayName ?? '',
        createdAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Trong AuthService
  Future<UserModel?> register(
    String email,
    String fullName,
    String password,
  ) async {
    try {
      print("===== BẮT ĐẦU ĐĂNG KÝ =====");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        print("Firebase Auth đăng ký thành công với uid: ${user.uid}");

        // Cập nhật _user ngay lập tức
        _user = user;

        // Tạo UserModel trước khi lưu vào Firestore
        UserModel newUser = UserModel(
          id: user.uid,
          email: email,
          fullName: fullName,
          createdAt: DateTime.now(),
        );

        // Lưu _userModel ngay lập tức
        _userModel = newUser;

        // Thông báo UI cập nhật TRƯỚC khi thử lưu vào Firestore
        notifyListeners();

        try {
          // Cố gắng lưu dữ liệu vào Firestore, nhưng không ảnh hưởng đến trạng thái đăng ký
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
          print("Đã lưu dữ liệu người dùng vào Firestore");
        } catch (firestoreError) {
          print(
            "Lỗi khi lưu dữ liệu người dùng vào Firestore: $firestoreError",
          );
          // Không throw lỗi, vẫn coi như đăng ký thành công
        }

        return newUser;
      } else {
        print("Firebase Auth đăng ký thành công nhưng user null");
        return null;
      }
    } catch (e) {
      print("Lỗi đăng ký trong AuthService: $e");
      rethrow;
    }
  }

  // Login user
  Future<User?> login(String email, String password) async {
    try {
      print("===== BẮT ĐẦU ĐĂNG NHẬP TRONG AUTH SERVICE =====");
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        print("Firebase Auth đăng nhập thành công với uid: ${user.uid}");

        // Cập nhật _user ngay lập tức
        _user = user;

        // Tạo _userModel cơ bản từ thông tin Firebase Auth
        // Điều này đảm bảo _userModel luôn tồn tại và isLoggedIn sẽ là true
        _userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? email.split('@')[0],
          createdAt: DateTime.now(),
        );

        // Thông báo cho UI cập nhật TRƯỚC khi thử lấy dữ liệu từ Firestore
        notifyListeners();

        try {
          // Cố gắng lấy dữ liệu từ Firestore, nhưng không ảnh hưởng đến trạng thái đăng nhập
          await _getUserData();
        } catch (userDataError) {
          print(
            "Lỗi khi lấy dữ liệu người dùng, nhưng vẫn coi như đăng nhập thành công: $userDataError",
          );
          // Không cần đảm bảo _userModel vì đã tạo ở trên
        }

        return user;
      } else {
        print("Firebase Auth đăng nhập thành công nhưng user null");
        return null;
      }
    } catch (e) {
      print("Lỗi đăng nhập trong AuthService: $e");
      rethrow;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _userModel = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  // Update user profile
  // Trong AuthService
  Future<void> updateProfile(
    String fullName,
    List<Map<String, dynamic>> addresses,
  ) async {
    try {
      if (_user == null) return;

      final docRef = _firestore.collection('users').doc(_user!.uid);

      // Kiểm tra xem document có tồn tại không
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Cập nhật document hiện tại
        await docRef.update({'fullName': fullName, 'addresses': addresses});
      } else {
        // Tạo document mới với dữ liệu đầy đủ
        await docRef.set({
          'id': _user!.uid,
          'email': _user!.email ?? '',
          'fullName': fullName,
          'addresses': addresses,
          'loyaltyPoints': 0,
          'orders': [],
          'createdAt': Timestamp.now(),
          'isAdmin': false,
        });
      }

      await _getUserData();
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Get user loyalty points
  int getUserLoyaltyPoints() {
    return _userModel?.loyaltyPoints ?? 0;
  }

  // Get user addresses
  List<Map<String, dynamic>> getUserAddresses() {
    return _userModel?.addresses ?? [];
  }

  // Check if user is admin
  bool isUserAdmin() {
    return _userModel?.isAdmin ?? false;
  }

  // Thêm vào AuthService
  Future<UserModel?> loginWithoutUserData(String email, String password) async {
    try {
      print("===== BẮT ĐẦU ĐĂNG NHẬP ĐƠN GIẢN HÓA =====");
      print("Email: $email");

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        print("Đăng nhập Firebase Auth thành công với UID: ${user.uid}");

        // Tạo một UserModel đơn giản mà không lấy dữ liệu từ Firestore
        _userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          fullName:
              user.displayName ??
              email.split('@')[0], // Lấy phần trước @ làm tên
          createdAt: DateTime.now(),
        );

        notifyListeners();
        return _userModel;
      }
    } catch (e) {
      print("Lỗi đăng nhập đơn giản hóa: $e");
      rethrow;
    }
    return null;
  }
}
