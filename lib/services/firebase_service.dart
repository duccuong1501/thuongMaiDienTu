import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Firebase instances
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // Collections references
  static final CollectionReference usersCollection = firestore.collection(
    'users',
  );
  static final CollectionReference productsCollection = firestore.collection(
    'products',
  );
  static final CollectionReference categoriesCollection = firestore.collection(
    'categories',
  );
  static final CollectionReference ordersCollection = firestore.collection(
    'orders',
  );
  static final CollectionReference reviewsCollection = firestore.collection(
    'reviews',
  );
  static final CollectionReference couponsCollection = firestore.collection(
    'coupons',
  );

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Upload image to Firebase Storage
  static Future<String> uploadImage(String path, dynamic file) async {
    try {
      final ref = storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return auth.currentUser?.uid;
  }

  // Check if user is logged in
  static bool isUserLoggedIn() {
    return auth.currentUser != null;
  }

  // Get timestamp for Firestore
  static Timestamp getTimestamp() {
    return Timestamp.now();
  }
}
