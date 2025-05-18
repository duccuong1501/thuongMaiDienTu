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

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  // Register new user
  Future<UserModel?> register(
    String email,
    String fullName,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Create user in Firestore
        UserModel newUser = UserModel(
          id: user.uid,
          email: email,
          fullName: fullName,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        _userModel = newUser;
        notifyListeners();
        return newUser;
      }
    } catch (e) {
      print('Error during registration: $e');
      rethrow;
    }
    return null;
  }

  // Login user
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await _getUserData();
        notifyListeners();
        return _userModel;
      }
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
    return null;
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
  Future<void> updateProfile(
    String fullName,
    List<Map<String, dynamic>> addresses,
  ) async {
    try {
      if (_user == null) return;

      await _firestore.collection('users').doc(_user!.uid).update({
        'fullName': fullName,
        'addresses': addresses,
      });

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
}
