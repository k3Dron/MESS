class MonthBillingModel {
  final int month;
  final double monthlyExp;
  final double totalYearExp;
  final String paidStatus; // 'paid', 'pending', 'partial'

  MonthBillingModel({
    required this.month,
    this.monthlyExp = 0,
    this.totalYearExp = 0,
    this.paidStatus = 'pending',
  });

  factory MonthBillingModel.fromMap(Map<String, dynamic> map) {
    return MonthBillingModel(
      month: map['month'] ?? 1,
      monthlyExp: (map['monthly_exp'] ?? 0).toDouble(),
      totalYearExp: (map['total_year_exp'] ?? 0).toDouble(),
      paidStatus: map['paid_status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'monthly_exp': monthlyExp,
      'total_year_exp': totalYearExp,
      'paid_status': paidStatus,
    };
  }
}
