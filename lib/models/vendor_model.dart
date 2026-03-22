import '../constants/constants.dart';

class VendorModel {
  final String email;
  final String name;
  final String uniqueCode;
  final Map<String, dynamic> menuConfig;
  final Map<String, double> mealPrices;
  final List<Map<String, dynamic>> plans;
  final double semesterFee;
  final Map<String, String> lockTimes; // {'breakfast': '07:00', ...}

  VendorModel({
    required this.email,
    required this.name,
    required this.uniqueCode,
    this.menuConfig = const {},
    Map<String, double>? mealPrices,
    List<Map<String, dynamic>>? plans,
    this.semesterFee = BillingConstants.baseFee,
    Map<String, String>? lockTimes,
  })  : mealPrices = mealPrices ?? MealSchedule.defaultPrices,
        plans = plans ?? BillingConstants.defaultPlans,
        lockTimes = lockTimes ?? {
          'breakfast': '07:00',
          'lunch': '12:00',
          'dinner': '19:00',
        };

  factory VendorModel.fromMap(Map<String, dynamic> map) {
    // Parse meal_prices from Firestore
    Map<String, double>? parsedPrices;
    if (map['meal_prices'] != null) {
      final raw = Map<String, dynamic>.from(map['meal_prices']);
      parsedPrices = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    // Parse plans from Firestore
    List<Map<String, dynamic>>? parsedPlans;
    if (map['plans'] != null) {
      parsedPlans = List<Map<String, dynamic>>.from(
        (map['plans'] as List).map((p) => Map<String, dynamic>.from(p)),
      );
    }

    return VendorModel(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      uniqueCode: map['unique_code'] ?? '',
      menuConfig: Map<String, dynamic>.from(map['menu_config'] ?? {}),
      mealPrices: parsedPrices,
      plans: parsedPlans,
      semesterFee: (map['semester_fee'] as num?)?.toDouble() ?? BillingConstants.baseFee,
      lockTimes: Map<String, String>.from(map['lock_times'] ?? {
        'breakfast': '07:00',
        'lunch': '12:00',
        'dinner': '19:00',
      }),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'unique_code': uniqueCode,
      'menu_config': menuConfig,
      'meal_prices': mealPrices,
      'plans': plans,
      'semester_fee': semesterFee,
      'lock_times': lockTimes,
    };
  }

  VendorModel copyWith({
    String? email,
    String? name,
    String? uniqueCode,
    Map<String, dynamic>? menuConfig,
    Map<String, double>? mealPrices,
    List<Map<String, dynamic>>? plans,
    double? semesterFee,
    Map<String, String>? lockTimes,
  }) {
    return VendorModel(
      email: email ?? this.email,
      name: name ?? this.name,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      menuConfig: menuConfig ?? this.menuConfig,
      mealPrices: mealPrices ?? this.mealPrices,
      plans: plans ?? this.plans,
      semesterFee: semesterFee ?? this.semesterFee,
      lockTimes: lockTimes ?? this.lockTimes,
    );
  }
}

