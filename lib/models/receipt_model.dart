import 'dart:math';

class ReceiptModel {
  final String id;
  final String receiptCode; // Unique 8-char alphanumeric
  final double expenditure;
  final double planDeduction;
  final double finalCost;
  final double bufferUsed;
  final DateTime date;
  final String studentEmail;
  final String vendorCode;
  final int month;

  ReceiptModel({
    required this.id,
    required this.receiptCode,
    required this.expenditure,
    required this.planDeduction,
    required this.finalCost,
    required this.bufferUsed,
    required this.date,
    required this.studentEmail,
    required this.vendorCode,
    required this.month,
  });

  /// Generate an 8-character unique receipt code.
  static String generateReceiptCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] ?? '',
      receiptCode: map['receipt_code'] ?? '',
      expenditure: (map['expenditure'] ?? 0).toDouble(),
      planDeduction: (map['plan_deduction'] ?? 0).toDouble(),
      finalCost: (map['final_cost'] ?? 0).toDouble(),
      bufferUsed: (map['buffer_used'] ?? 0).toDouble(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      studentEmail: map['student_email'] ?? '',
      vendorCode: map['vendor_code'] ?? '',
      month: map['month'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_code': receiptCode,
      'expenditure': expenditure,
      'plan_deduction': planDeduction,
      'final_cost': finalCost,
      'buffer_used': bufferUsed,
      'date': date.toIso8601String(),
      'student_email': studentEmail,
      'vendor_code': vendorCode,
      'month': month,
    };
  }
}
