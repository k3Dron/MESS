import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    // Check vendors first
    final vendorDoc = await _db.collection('vendors').doc(user.email).get();
    if (vendorDoc.exists) return 'vendor';
    // Then check students
    final studentDoc = await _db.collection('students').doc(user.email).get();
    if (studentDoc.exists) return 'student';
    return null;
  }

  String _generateVendorCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<UserCredential> signUpStudent({
    required String email,
    required String password,
    required String name,
    String hostelNo = '',
    String hostelType = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('students').doc(email).set({
      'email': email,
      'name': name,
      'hostel_no': hostelNo,
      'hostel_type': hostelType,
      'profile_pic_url': '',
      'vendor_code': '',
      'billing_status': 'active',
      'selected_plan': 1,
      'role': 'student',
      'created_at': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> signUpVendor({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final code = _generateVendorCode();
    await _db.collection('vendors').doc(email).set({
      'email': email,
      'name': name,
      'unique_code': code,
      'menu_config': {},
      'role': 'vendor',
      'created_at': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
