class MealDayModel {
  final int day;
  final int month;
  final int year;
  final List<int> meals; // [breakfast, lunch, dinner] → 0=Absent, 1=Veg, 2=Non-Veg

  MealDayModel({
    required this.day,
    required this.month,
    required this.year,
    this.meals = const [0, 0, 0],
  });

  factory MealDayModel.fromMap(Map<String, dynamic> map) {
    return MealDayModel(
      day: map['day'] ?? 1,
      month: map['month'] ?? 1,
      year: map['year'] ?? 2026,
      meals: List<int>.from(map['meals'] ?? [0, 0, 0]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'meals': meals,
    };
  }

  MealDayModel copyWith({List<int>? meals}) {
    return MealDayModel(
      day: day,
      month: month,
      year: year,
      meals: meals ?? List<int>.from(this.meals),
    );
  }
}
