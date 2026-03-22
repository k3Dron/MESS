import '../constants/constants.dart';

class BillingResult {
  final double monthlyExpense;
  final double planAllowance;
  final double overspend;
  final double bufferUsed;
  final double pendingBill;
  final double remainingBuffer;

  BillingResult({
    required this.monthlyExpense,
    required this.planAllowance,
    required this.overspend,
    required this.bufferUsed,
    required this.pendingBill,
    required this.remainingBuffer,
  });
}

class BillingLogic {
  /// Get monthly plan allowance based on selected plan.
  /// If [plans] is provided, uses dynamic vendor plans; otherwise uses defaults.
  static double getMonthlyAllowance(int planId, {List<Map<String, dynamic>>? plans}) {
    final planList = plans ?? BillingConstants.defaultPlans;
    final plan = planList.cast<Map<String, dynamic>?>().firstWhere(
      (p) => p!['id'] == planId,
      orElse: () => null,
    );
    if (plan == null) return 0;
    return (plan['amount'] as num).toDouble();
  }

  /// Calculate billing for a month.
  /// [monthlyExpense] = total food cost for the month.
  /// [planId] = selected plan (1, 2, or 3).
  /// [currentBuffer] = remaining security deposit buffer.
  /// If [plans] is provided, uses dynamic vendor plans.
  static BillingResult calculateMonthBilling({
    required double monthlyExpense,
    required int planId,
    required double currentBuffer,
    List<Map<String, dynamic>>? plans,
  }) {
    final allowance = getMonthlyAllowance(planId, plans: plans);
    final overspend = (monthlyExpense - allowance).clamp(0.0, double.infinity).toDouble();

    double bufferUsed = 0;
    double pendingBill = 0;
    double remainingBuffer = currentBuffer;

    if (overspend > 0) {
      if (currentBuffer >= overspend) {
        bufferUsed = overspend.toDouble();
        remainingBuffer = currentBuffer - overspend;
      } else {
        bufferUsed = currentBuffer;
        pendingBill = overspend - currentBuffer;
        remainingBuffer = 0;
      }
    }

    return BillingResult(
      monthlyExpense: monthlyExpense,
      planAllowance: allowance,
      overspend: overspend,
      bufferUsed: bufferUsed,
      pendingBill: pendingBill,
      remainingBuffer: remainingBuffer,
    );
  }

  /// Get plan label.
  static String getPlanLabel(int planId, {List<Map<String, dynamic>>? plans}) {
    final planList = plans ?? BillingConstants.defaultPlans;
    final plan = planList.cast<Map<String, dynamic>?>().firstWhere(
      (p) => p!['id'] == planId,
      orElse: () => null,
    );
    if (plan == null) return 'Unknown Plan';
    return plan['label'] as String;
  }

  /// Get all plan options for display.
  static List<Map<String, dynamic>> getAllPlans({List<Map<String, dynamic>>? plans}) {
    return plans ?? BillingConstants.defaultPlans;
  }
}

