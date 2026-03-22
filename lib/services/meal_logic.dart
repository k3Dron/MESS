import '../constants/constants.dart';

enum MealType { breakfast, lunch, dinner }

enum MealState { absent, veg, nonVeg }

class MealStatus {
  final MealType type;
  final bool isLocked;
  final String label;
  final DateTime lockStart;
  final DateTime lockEnd;

  MealStatus({
    required this.type,
    required this.isLocked,
    required this.label,
    required this.lockStart,
    required this.lockEnd,
  });
}

class MealLogic {
  /// Returns the lock window for a given meal on a given date.
  /// If [vendorLockTimes] is provided, uses those specific cutoff times.
  /// Otherwise, lock starts 1 hour before meal start, ends 30 min after meal end.
  static (DateTime, DateTime) _lockWindow(DateTime date, MealType type, {Map<String, String>? vendorLockTimes}) {
    if (vendorLockTimes != null) {
      final key = type.name; // breakfast, lunch, dinner
      final timeStr = vendorLockTimes[key];
      if (timeStr != null) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        // For a specific cutoff time, it's locked FROM that time onwards.
        // We can represent this as a window from [cutoff] to [end of day].
        final lockStart = DateTime(date.year, date.month, date.day, hour, minute);
        final lockEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
        return (lockStart, lockEnd);
      }
    }

    int startHour, endHour;
    switch (type) {
      case MealType.breakfast:
        startHour = MealSchedule.breakfastStart;
        endHour = MealSchedule.breakfastEnd;
      case MealType.lunch:
        startHour = MealSchedule.lunchStart;
        endHour = MealSchedule.lunchEnd;
      case MealType.dinner:
        startHour = MealSchedule.dinnerStart;
        endHour = MealSchedule.dinnerEnd;
    }
    final lockStart = DateTime(date.year, date.month, date.day, startHour)
        .subtract(const Duration(minutes: MealSchedule.lockBeforeMinutes));
    final lockEnd = DateTime(date.year, date.month, date.day, endHour)
        .add(const Duration(minutes: MealSchedule.lockAfterMinutes));
    return (lockStart, lockEnd);
  }

  /// Check if a meal is currently locked.
  static bool isMealLocked(DateTime now, DateTime mealDate, MealType type, {Map<String, String>? vendorLockTimes}) {
    // Past days are always locked
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(mealDate.year, mealDate.month, mealDate.day);
    if (targetDay.isBefore(today)) return true;

    // Same day: check lock window
    if (targetDay.isAtSameMomentAs(today)) {
      final (lockStart, lockEnd) = _lockWindow(mealDate, type, vendorLockTimes: vendorLockTimes);
      return now.isAfter(lockStart) && now.isBefore(lockEnd) || now.isAfter(lockEnd);
    }

    // Future days are unlocked
    return false;
  }

  /// Get all meal statuses for today.
  static List<MealStatus> getTodayMealStatuses(DateTime now, {Map<String, String>? vendorLockTimes}) {
    return MealType.values.map((type) {
      final (lockStart, lockEnd) = _lockWindow(now, type, vendorLockTimes: vendorLockTimes);
      final locked = isMealLocked(now, now, type, vendorLockTimes: vendorLockTimes);
      String label;
      switch (type) {
        case MealType.breakfast:
          label = 'Breakfast';
        case MealType.lunch:
          label = 'Lunch';
        case MealType.dinner:
          label = 'Dinner';
      }
      return MealStatus(
        type: type,
        isLocked: locked,
        label: label,
        lockStart: lockStart,
        lockEnd: lockEnd,
      );
    }).toList();
  }

  /// Cycle meal state: Absent -> Veg -> Non-Veg -> Absent
  /// When [nonVegAllowed] is false, cycle is Absent -> Veg -> Absent (skip Non-Veg).
  static int cycleMealState(int current, {bool nonVegAllowed = true}) {
    if (nonVegAllowed) {
      return (current + 1) % 3;
    }
    // Non-veg not allowed: 0 -> 1 -> 0
    return current == 0 ? 1 : 0;
  }

  /// Calculate the cost for a single meal.
  /// If [prices] is provided, uses dynamic vendor prices; otherwise uses defaults.
  static double getMealCost(MealType type, int state, {Map<String, double>? prices}) {
    if (state == 0) return 0; // Absent
    final p = prices ?? MealSchedule.defaultPrices;
    switch (type) {
      case MealType.breakfast:
        return p['breakfast'] ?? MealSchedule.breakfastPrice;
      case MealType.lunch:
        return state == 1
            ? (p['lunch_veg'] ?? MealSchedule.lunchVegPrice)
            : (p['lunch_nonveg'] ?? MealSchedule.lunchNonVegPrice);
      case MealType.dinner:
        return state == 1
            ? (p['dinner_veg'] ?? MealSchedule.dinnerVegPrice)
            : (p['dinner_nonveg'] ?? MealSchedule.dinnerNonVegPrice);
    }
  }

  /// Calculate total daily cost from meals list [b, l, d].
  /// If [prices] is provided, uses dynamic vendor prices.
  static double getDailyCost(List<int> meals, {Map<String, double>? prices}) {
    double total = 0;
    total += getMealCost(MealType.breakfast, meals[0], prices: prices);
    total += getMealCost(MealType.lunch, meals[1], prices: prices);
    total += getMealCost(MealType.dinner, meals[2], prices: prices);
    return total;
  }

}
