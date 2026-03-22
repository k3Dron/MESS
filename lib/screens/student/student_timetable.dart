import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../services/firestore_service.dart';

class StudentTimetable extends StatefulWidget {
  final String vendorCode;
  const StudentTimetable({super.key, required this.vendorCode});

  @override
  State<StudentTimetable> createState() => _StudentTimetableState();
}

class _StudentTimetableState extends State<StudentTimetable> {
  final _firestoreService = FirestoreService();
  Map<String, dynamic> _menu = {};
  bool _loading = true;

  final _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final vendor = await _firestoreService.getVendorByCode(widget.vendorCode);
    if (vendor != null && mounted) {
      setState(() {
        _menu = vendor.menuConfig;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mess Timetable',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _menu.isEmpty
              ? _buildEmptyState()
              : _buildTimetableList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No menu configured yet',
            style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: _weekDays.length,
      itemBuilder: (context, index) {
        final day = _weekDays[index];
        final dayConfig = _menu[day.toLowerCase()] as Map<String, dynamic>? ?? {};
        return _dayCard(day, dayConfig);
      },
    );
  }

  Widget _dayCard(String day, Map<String, dynamic> config) {
    final hasNonVeg = config['non_veg'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Text(
                day,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (hasNonVeg) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.nonVegOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NV',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nonVegOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        NeumorphicCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _mealRow('Breakfast', config['breakfast_veg'] ?? config['breakfast'] ?? '-', config['breakfast_nonveg'] ?? ''),
              const Divider(height: 24),
              _mealRow('Lunch', config['lunch_veg'] ?? config['lunch'] ?? '-', config['lunch_nonveg'] ?? ''),
              const Divider(height: 24),
              _mealRow('Dinner', config['dinner_veg'] ?? config['dinner'] ?? '-', config['dinner_nonveg'] ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _mealRow(String meal, String vegItems, String nonVegItems) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            meal,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco_rounded, size: 14, color: AppColors.vegGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vegItems,
                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
              if (nonVegItems.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.restaurant_rounded, size: 14, color: AppColors.nonVegOrange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        nonVegItems,
                        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
