import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/constants.dart';
import '../../widgets/meal_card_widget.dart';
import '../../services/meal_logic.dart';
import '../../services/firestore_service.dart';
import '../../models/meal_day_model.dart';

class StudentCalendar extends StatefulWidget {
  const StudentCalendar({super.key});

  @override
  State<StudentCalendar> createState() => _StudentCalendarState();
}

class _StudentCalendarState extends State<StudentCalendar> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _vendorCode = '';
  String _vendorEmail = '';
  String _userName = '';
  Map<int, List<int>> _mealData = {}; // day -> [b, l, d]
  Map<String, dynamic> _menuConfig = {}; // vendor menu config (all days)
  Map<String, String>? _lockTimes; // vendor's custom meal lock times

  @override
  void initState() {
    super.initState();
    _loadVendorCode();
  }

  Future<void> _loadVendorCode() async {
    if (_user == null) return;
    final student = await _firestoreService.getStudent(_user.email!);
    if (student != null && mounted) {
      final vendor =
          await _firestoreService.getVendorByCode(student.vendorCode);
      setState(() {
        _vendorCode = student.vendorCode;
        _vendorEmail = vendor?.email ?? '';
        _userName = student.name;
        _menuConfig = vendor?.menuConfig ?? {};
        _lockTimes = vendor?.lockTimes;
      });
      _loadMonthData();
    }
  }

  Future<void> _loadMonthData() async {
    if (_vendorCode.isEmpty) return;
    final meals = await _firestoreService.getMonthMeals(
      _user!.email!,
      _vendorCode,
      _selectedMonth,
    );
    final map = <int, List<int>>{};
    for (final m in meals) {
      map[m.day] = m.meals;
    }
    if (mounted) setState(() => _mealData = map);
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  bool _isFuture(int day) {
    final now = DateTime.now();
    final date = DateTime(_selectedYear, _selectedMonth, day);
    return date.isAfter(DateTime(now.year, now.month, now.day));
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return _selectedYear == now.year &&
        _selectedMonth == now.month &&
        day == now.day;
  }

  void _cycleMealForDay(int day, int mealIndex) {
    // Check if meal is locked
    final now = DateTime.now();
    final mealDate = DateTime(_selectedYear, _selectedMonth, day);
    final mealType = MealType.values[mealIndex];
    if (MealLogic.isMealLocked(now, mealDate, mealType, vendorLockTimes: _lockTimes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This meal is locked and cannot be changed.')),
      );
      return;
    }

    final meals = _mealData[day] ?? [0, 0, 0];
    final newMeals = List<int>.from(meals);

    // Check non-veg availability for the target day
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final targetDate = DateTime(_selectedYear, _selectedMonth, day);
    final dayName = dayNames[targetDate.weekday - 1];
    final dayMenuRaw = _menuConfig[dayName];
    final dayMenu = dayMenuRaw is Map ? Map<String, dynamic>.from(dayMenuRaw) : <String, dynamic>{};
    final nonVegAllowed = dayMenu['non_veg'] == true;

    final oldState = newMeals[mealIndex];
    newMeals[mealIndex] = MealLogic.cycleMealState(newMeals[mealIndex], nonVegAllowed: nonVegAllowed);

    // Show alert if non-veg is not available and user tried to go past veg
    if (!nonVegAllowed && oldState == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non-veg is not available on this day')),
      );
    }

    setState(() => _mealData[day] = newMeals);

    // Save to Firestore and recalculate monthly expenditure
    _firestoreService.setMealDay(
      _user!.email!,
      _vendorCode,
      _selectedMonth,
      day,
      MealDayModel(
        day: day,
        month: _selectedMonth,
        year: _selectedYear,
        meals: newMeals,
      ),
    ).then((_) async {
      final newTotal = await _firestoreService.recalculateMonthlyExpenditure(
        _user.email!,
        _vendorCode,
        _selectedMonth,
      );
      // Sync pending bill to vendor DB
      if (_vendorEmail.isNotEmpty) {
        if (newTotal > 0) {
          await _firestoreService.setPendingBill(
            vendorEmail: _vendorEmail,
            studentEmail: _user.email!,
            studentName: _userName,
            month: _selectedMonth,
            amount: newTotal,
          );
        } else {
          await _firestoreService.deletePendingBill(
            _vendorEmail,
            _user.email!,
            _selectedMonth,
          );
        }
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
      _mealData.clear();
    });
    _loadMonthData();
  }

  @override
  Widget build(BuildContext context) {
    final daysCount = _daysInMonth(_selectedYear, _selectedMonth);
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return SafeArea(
      child: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                ),
                Text(
                  '${monthNames[_selectedMonth]} $_selectedYear',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                ),
              ],
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _legendDot(AppColors.absentGrey, 'Absent'),
                const SizedBox(width: 16),
                _legendDot(AppColors.vegGreen, 'Veg'),
                const SizedBox(width: 16),
                _legendDot(AppColors.nonVegOrange, 'Non-Veg'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    'Day',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...['B', 'L', 'D'].map((l) => Expanded(
                      child: Center(
                        child: Text(
                          l,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: daysCount,
              itemBuilder: (context, index) {
                final day = index + 1;
                final meals = _mealData[day] ?? [0, 0, 0];
                final isFuture = _isFuture(day);
                final isToday = _isToday(day);

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isToday
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2))
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            Text(
                              '$day',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? AppColors.primary
                                    : AppColors.textDark,
                              ),
                            ),
                            if (isToday)
                              Text(
                                'Today',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(3, (mi) {
                        final mealType = MealType.values[mi];
                        final mealDate =
                            DateTime(_selectedYear, _selectedMonth, day);
                        final locked = MealLogic.isMealLocked(
                                DateTime.now(), mealDate, mealType, vendorLockTimes: _lockTimes);
                        return Expanded(
                          child: Center(
                            child: MealCardWidget(
                              mealType: mealType,
                              state: meals[mi],
                              isLocked: locked,
                              compact: true,
                              onDoubleTap: isFuture
                                  ? () => _cycleMealForDay(day, mi)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}
