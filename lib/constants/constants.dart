import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF6F7FB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42E8);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF2ECC71);
  static const Color vegGreen = Color(0xFF27AE60);
  static const Color nonVegOrange = Color(0xFFE67E22);
  static const Color absentGrey = Color(0xFFBDC3C7);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMedium = Color(0xFF636E72);
  static const Color textLight = Color(0xFF95A5A6);
  static const Color border = Color(0xFFE8ECF4);
  static const Color shadowLight = Color(0x14000000);
  static const Color shadowDark = Color(0x0A000000);
  static const Color danger = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color locked = Color(0xFFE74C3C);
}

class AppRadius {
  static const double card = 24.0;
  static const double button = 16.0;
  static const double pill = 50.0;
  static const double input = 16.0;
  static const double small = 12.0;
  static const double bottomNav = 28.0;
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> cardSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, -5),
    ),
  ];
}

class MealSchedule {
  static const int breakfastStart = 8;
  static const int breakfastEnd = 9;
  static const int lunchStart = 13;
  static const int lunchEnd = 14;
  static const int dinnerStart = 20;
  static const int dinnerEnd = 21;

  static const double breakfastPrice = 50;
  static const double lunchVegPrice = 70;
  static const double lunchNonVegPrice = 80;
  static const double dinnerVegPrice = 70;
  static const double dinnerNonVegPrice = 80;

  static const int lockBeforeMinutes = 60;
  static const int lockAfterMinutes = 30;

  /// Default meal prices map (used as fallback when vendor has no custom prices).
  static Map<String, double> get defaultPrices => {
    'breakfast': breakfastPrice,
    'lunch_veg': lunchVegPrice,
    'lunch_nonveg': lunchNonVegPrice,
    'dinner_veg': dinnerVegPrice,
    'dinner_nonveg': dinnerNonVegPrice,
  };
}

class BillingConstants {
  static const double baseFee = 13500;
  static const double securityDeposit = 1500;

  static const Map<int, Map<String, dynamic>> plans = {
    1: {'amount': 2000, 'months': 6, 'label': 'Plan 1 - ₹2,000/mo × 6'},
    2: {'amount': 2500, 'months': 5, 'label': 'Plan 2 - ₹2,500/mo × 5'},
    3: {'amount': 3000, 'months': 4, 'label': 'Plan 3 - ₹3,000/mo × 4'},
  };

  /// Default plans as a List (used as fallback when vendor has no custom plans).
  static List<Map<String, dynamic>> get defaultPlans => [
    {'id': 1, 'amount': 2000, 'months': 6, 'label': 'Plan 1 - ₹2,000/mo × 6'},
    {'id': 2, 'amount': 2500, 'months': 5, 'label': 'Plan 2 - ₹2,500/mo × 5'},
    {'id': 3, 'amount': 3000, 'months': 4, 'label': 'Plan 3 - ₹3,000/mo × 4'},
  ];
}
