import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/vendor_model.dart';
import '../models/meal_day_model.dart';
import '../models/receipt_model.dart';
import '../models/comment_model.dart';
import '../models/month_billing_model.dart';
import 'meal_logic.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Student ──────────────────────────────────────────────────
  Future<StudentModel?> getStudent(String email) async {
    final doc = await _db.collection('students').doc(email).get();
    if (!doc.exists) return null;
    return StudentModel.fromMap(doc.data()!);
  }

  Future<void> updateStudent(String email, Map<String, dynamic> data) async {
    await _db.collection('students').doc(email).update(data);
  }

  // ── Vendor ───────────────────────────────────────────────────
  Future<VendorModel?> getVendor(String email) async {
    final doc = await _db.collection('vendors').doc(email).get();
    if (!doc.exists) return null;
    return VendorModel.fromMap(doc.data()!);
  }

  Future<void> updateVendor(String email, Map<String, dynamic> data) async {
    await _db.collection('vendors').doc(email).update(data);
  }

  Future<VendorModel?> getVendorByCode(String code) async {
    final query = await _db
        .collection('vendors')
        .where('unique_code', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return VendorModel.fromMap(query.docs.first.data());
  }

  // ── Meal Days ────────────────────────────────────────────────
  Future<void> setMealDay(
    String studentEmail,
    String vendorCode,
    int month,
    int day,
    MealDayModel mealDay,
  ) async {
    await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('months')
        .doc(month.toString())
        .collection('days')
        .doc(day.toString())
        .set(mealDay.toMap());
  }

  Future<MealDayModel?> getMealDay(
    String studentEmail,
    String vendorCode,
    int month,
    int day,
  ) async {
    final doc = await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('months')
        .doc(month.toString())
        .collection('days')
        .doc(day.toString())
        .get();
    if (!doc.exists) return null;
    return MealDayModel.fromMap(doc.data()!);
  }

  Future<List<MealDayModel>> getMonthMeals(
    String studentEmail,
    String vendorCode,
    int month,
  ) async {
    final snapshot = await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('months')
        .doc(month.toString())
        .collection('days')
        .get();
    return snapshot.docs
        .map((doc) => MealDayModel.fromMap(doc.data()))
        .toList();
  }

  // ── Month Billing ────────────────────────────────────────────
  Future<void> setMonthBilling(
    String studentEmail,
    String vendorCode,
    int month,
    MonthBillingModel billing,
  ) async {
    await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('months')
        .doc(month.toString())
        .set(billing.toMap(), SetOptions(merge: true));
  }

  Future<MonthBillingModel?> getMonthBilling(
    String studentEmail,
    String vendorCode,
    int month,
  ) async {
    final doc = await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('months')
        .doc(month.toString())
        .get();
    if (!doc.exists) return null;
    return MonthBillingModel.fromMap(doc.data()!);
  }

  // ── Recalculate Monthly Expenditure ──────────────────────────
  /// Fetches all day docs for the month, sums meal costs, and
  /// writes the total back to the month billing doc.
  /// Returns the new monthly expenditure value.
  /// If [mealPrices] is provided, uses dynamic vendor prices.
  Future<double> recalculateMonthlyExpenditure(
    String studentEmail,
    String vendorCode,
    int month, {
    Map<String, double>? mealPrices,
  }) async {
    final days = await getMonthMeals(studentEmail, vendorCode, month);
    double total = 0;
    for (final day in days) {
      total += MealLogic.getDailyCost(day.meals, prices: mealPrices);
    }
    // Fetch existing billing or create a new one
    final existing = await getMonthBilling(studentEmail, vendorCode, month);
    final billing = MonthBillingModel(
      month: month,
      monthlyExp: total,
      totalYearExp: existing?.totalYearExp ?? 0,
      paidStatus: existing?.paidStatus ?? 'pending',
    );
    await setMonthBilling(studentEmail, vendorCode, month, billing);
    return total;
  }

  // ── Receipts ─────────────────────────────────────────────────
  Future<void> addReceipt(
    String studentEmail,
    String vendorCode,
    ReceiptModel receipt,
  ) async {
    await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('receipts')
        .doc(receipt.id)
        .set(receipt.toMap());
  }

  Future<List<ReceiptModel>> getReceipts(
    String studentEmail,
    String vendorCode,
  ) async {
    final snapshot = await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('receipts')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ReceiptModel.fromMap(doc.data()))
        .toList();
  }

  // ── Comments ─────────────────────────────────────────────────
  Future<void> addComment(String vendorCode, CommentModel comment) async {
    await _db
        .collection('vendors')
        .doc(vendorCode)
        .collection('comments')
        .doc(comment.id)
        .set(comment.toMap());
  }

  Stream<List<CommentModel>> commentsStream(String vendorCode) {
    return _db
        .collection('vendors')
        .doc(vendorCode)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => CommentModel.fromMap(doc.data())).toList());
  }

  Future<void> likeComment(String vendorCode, String commentId) async {
    await _db
        .collection('vendors')
        .doc(vendorCode)
        .collection('comments')
        .doc(commentId)
        .update({'likes': FieldValue.increment(1)});
  }

  Future<void> replyToComment(
    String vendorCode,
    String commentId,
    String reply,
  ) async {
    await _db
        .collection('vendors')
        .doc(vendorCode)
        .collection('comments')
        .doc(commentId)
        .update({
      'reply': reply,
      'reply_timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ── Requests (Unlock / Parcel) ───────────────────────────────
  Future<void> sendBroadcastNotification(
    String vendorEmail,
    String message,
  ) async {
    final vendor = await getVendor(vendorEmail);
    if (vendor == null) return;

    final students = await getStudentsByVendorCode(vendor.uniqueCode);
    final batch = _db.batch();

    for (var student in students) {
      final notifRef = _db
          .collection('students')
          .doc(student.email)
          .collection('vendor_data')
          .doc(vendor.uniqueCode)
          .collection('notifications')
          .doc();

      batch.set(notifRef, {
        'message': message,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await batch.commit();
  }
  Future<void> sendRequest({
    required String vendorEmail,
    required String studentEmail,
    required String type, // 'unlock' or 'parcel'
    required String mealLabel,
    required String reason,
    String recipientName = '',
  }) async {
    await _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('active_requests')
        .add({
      'student_email': studentEmail,
      'type': type,
      'meal_label': mealLabel,
      'reason': reason,
      'recipient_name': recipientName,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> requestsStream(String vendorEmail) {
    return _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('active_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Cancel any pending parcel request for a specific student + meal.
  /// Returns the number of requests that were cancelled.
  Future<int> cancelPendingParcelRequest({
    required String vendorEmail,
    required String studentEmail,
    required String mealLabel,
  }) async {
    final snap = await _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('active_requests')
        .where('student_email', isEqualTo: studentEmail)
        .where('type', isEqualTo: 'parcel')
        .where('meal_label', isEqualTo: mealLabel)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    return snap.docs.length;
  }

  // ── Vendor: Student list by code ─────────────────────────────
  Future<List<StudentModel>> getStudentsByVendorCode(String vendorCode) async {
    final snapshot = await _db
        .collection('students')
        .where('vendor_code', isEqualTo: vendorCode)
        .get();
    return snapshot.docs
        .map((doc) => StudentModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<StudentModel>> searchStudents({
    required String vendorCode,
    String? email,
    String? hostelNo,
  }) async {
    Query query = _db
        .collection('students')
        .where('vendor_code', isEqualTo: vendorCode);
    if (email != null && email.isNotEmpty) {
      query = query.where('email', isEqualTo: email);
    }
    if (hostelNo != null && hostelNo.isNotEmpty) {
      query = query.where('hostel_no', isEqualTo: hostelNo);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ── Headcounts ───────────────────────────────────────────────
  /// Returns headcounts split by hostel type.
  /// Keys: 'boys', 'girls' → each contains breakfast_veg, breakfast_nv, etc.
  Future<Map<String, Map<String, int>>> getMealHeadcounts(
    String vendorCode,
    int month,
    int day,
  ) async {
    final students = await getStudentsByVendorCode(vendorCode);

    // Initialise counters for both hostel types
    final Map<String, Map<String, int>> result = {
      'boys': {
        'breakfast_veg': 0, 'breakfast_nv': 0,
        'lunch_veg': 0, 'lunch_nv': 0,
        'dinner_veg': 0, 'dinner_nv': 0,
      },
      'girls': {
        'breakfast_veg': 0, 'breakfast_nv': 0,
        'lunch_veg': 0, 'lunch_nv': 0,
        'dinner_veg': 0, 'dinner_nv': 0,
      },
    };

    for (final s in students) {
      final hostel = s.hostelType == 'girls' ? 'girls' : 'boys';
      final meal = await getMealDay(s.email, vendorCode, month, day);
      if (meal != null) {
        if (meal.meals[0] == 1) result[hostel]!['breakfast_veg'] = result[hostel]!['breakfast_veg']! + 1;
        if (meal.meals[0] == 2) result[hostel]!['breakfast_nv'] = result[hostel]!['breakfast_nv']! + 1;
        if (meal.meals[1] == 1) result[hostel]!['lunch_veg'] = result[hostel]!['lunch_veg']! + 1;
        if (meal.meals[1] == 2) result[hostel]!['lunch_nv'] = result[hostel]!['lunch_nv']! + 1;
        if (meal.meals[2] == 1) result[hostel]!['dinner_veg'] = result[hostel]!['dinner_veg']! + 1;
        if (meal.meals[2] == 2) result[hostel]!['dinner_nv'] = result[hostel]!['dinner_nv']! + 1;
      }
    }
    return result;
  }

  // ── Student Notifications ────────────────────────────────────
  Stream<QuerySnapshot> notificationsStream(
    String studentEmail,
    String vendorCode,
  ) {
    return _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> addStudentNotification(
    String studentEmail,
    String vendorCode,
    String message,
  ) async {
    await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('notifications')
        .add({
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // ── Vendor Receipts ─────────────────────────────────────────
  Future<void> addVendorReceipt(
    String vendorEmail,
    ReceiptModel receipt,
  ) async {
    await _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('receipts')
        .doc(receipt.id)
        .set(receipt.toMap());
  }

  Future<List<ReceiptModel>> getVendorReceipts(String vendorEmail) async {
    final snapshot = await _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('receipts')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ReceiptModel.fromMap(doc.data()))
        .toList();
  }

  // ── Month Billing Cleanup ───────────────────────────────────
  Future<void> clearMonthBilling(
    String studentEmail,
    String vendorCode,
    int month,
  ) async {
    await _db
        .collection('students')
        .doc(studentEmail)
        .collection('vendor_data')
        .doc(vendorCode)
        .collection('months')
        .doc(month.toString())
        .update({
      'monthly_exp': 0,
      'paid_status': 'paid',
    });
  }

  // ── Pending Bills (Vendor side) ─────────────────────────────
  Future<void> setPendingBill({
    required String vendorEmail,
    required String studentEmail,
    required String studentName,
    required int month,
    required double amount,
    String type = 'monthly', // 'monthly' or 'semester_fee'
  }) async {
    final docId = '${studentEmail}_${type}_$month';
    await _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('pending_bills')
        .doc(docId)
        .set({
      'student_email': studentEmail,
      'student_name': studentName,
      'month': month,
      'amount': amount,
      'type': type,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePendingBill(
    String vendorEmail,
    String studentEmail,
    int month, {
    String type = 'monthly',
  }) async {
    final docId = '${studentEmail}_${type}_$month';
    await _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('pending_bills')
        .doc(docId)
        .delete();
  }

  Stream<QuerySnapshot> pendingBillsStream(String vendorEmail) {
    return _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('pending_bills')
        .orderBy('updated_at', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getPendingBillsForStudent(
    String vendorEmail,
    String studentEmail,
  ) async {
    final snapshot = await _db
        .collection('vendors')
        .doc(vendorEmail)
        .collection('pending_bills')
        .where('student_email', isEqualTo: studentEmail)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
