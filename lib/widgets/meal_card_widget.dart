import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/constants.dart';
import '../services/meal_logic.dart';

class MealCardWidget extends StatelessWidget {
  final MealType mealType;
  final int state; // 0=Absent, 1=Veg, 2=Non-Veg
  final bool isLocked;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onRequestTap;
  final VoidCallback? onParcelTap;
  final bool compact;
  final String? menuItems;

  const MealCardWidget({
    super.key,
    required this.mealType,
    required this.state,
    required this.isLocked,
    this.onDoubleTap,
    this.onRequestTap,
    this.onParcelTap,
    this.compact = false,
    this.menuItems,
  });

  Color get _stateColor {
    switch (state) {
      case 1:
        return AppColors.vegGreen;
      case 2:
        return AppColors.nonVegOrange;
      default:
        return AppColors.absentGrey;
    }
  }

  String get _stateLabel {
    switch (state) {
      case 1:
        return 'Veg';
      case 2:
        return 'Non-Veg';
      default:
        return 'Absent';
    }
  }

  IconData get _stateIcon {
    switch (state) {
      case 1:
        return Icons.eco_rounded;
      case 2:
        return Icons.restaurant_rounded;
      default:
        return Icons.close_rounded;
    }
  }

  String get _mealLabel {
    switch (mealType) {
      case MealType.breakfast:
        return 'B';
      case MealType.lunch:
        return 'L';
      case MealType.dinner:
        return 'D';
    }
  }

  String get _mealFullLabel {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
    }
  }

  String get _timeLabel {
    switch (mealType) {
      case MealType.breakfast:
        return '08:00 - 09:00';
      case MealType.lunch:
        return '13:00 - 14:00';
      case MealType.dinner:
        return '20:00 - 21:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull(context);
  }

  Widget _buildCompact() {
    return GestureDetector(
      onDoubleTap: isLocked ? null : onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _stateColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _stateColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _mealLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _stateColor,
              ),
            ),
            if (isLocked)
              Icon(Icons.lock_rounded, size: 10, color: _stateColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return GestureDetector(
      onDoubleTap: isLocked ? null : onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _stateColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: _stateColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _stateColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _stateColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_stateIcon, color: _stateColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mealFullLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          _timeLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _stateColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _stateLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            // Show menu items when student has marked for a meal
            if (menuItems != null && menuItems!.isNotEmpty && state != 0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _stateColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _stateColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.dining_rounded, size: 14, color: _stateColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        menuItems!,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isLocked) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lock_rounded,
                      size: 14, color: AppColors.locked),
                  const SizedBox(width: 6),
                  Text(
                    'Locked',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.locked,
                    ),
                  ),
                  const Spacer(),
                  // Parcel button for active meals (veg/non-veg)
                  if (onParcelTap != null && (state == 1 || state == 2))
                    GestureDetector(
                      onTap: onParcelTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delivery_dining_rounded,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Parcel',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Request (unlock) button for absent meals
                  else if (onRequestTap != null && state == 0)
                    GestureDetector(
                      onTap: onRequestTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'Request',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Double-tap to change',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  const Spacer(),
                  if (onParcelTap != null && (state == 1 || state == 2))
                    GestureDetector(
                      onTap: onParcelTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delivery_dining_rounded,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Parcel',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
