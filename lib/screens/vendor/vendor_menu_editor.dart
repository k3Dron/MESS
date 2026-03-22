import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/pill_button.dart';
import '../../services/firestore_service.dart';

class VendorMenuEditor extends StatefulWidget {
  const VendorMenuEditor({super.key});

  @override
  State<VendorMenuEditor> createState() => _VendorMenuEditorState();
}

class _VendorMenuEditorState extends State<VendorMenuEditor> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  final _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Menu config: day -> { breakfast_veg, breakfast_nonveg, lunch_veg, ... , non_veg }
  Map<String, Map<String, dynamic>> _menu = {};
  int _selectedDay = 0;
  bool _isEditing = false;

  // Veg controllers
  final _breakfastVegController = TextEditingController();
  final _lunchVegController = TextEditingController();
  final _dinnerVegController = TextEditingController();

  // Non-veg controllers
  final _breakfastNonVegController = TextEditingController();
  final _lunchNonVegController = TextEditingController();
  final _dinnerNonVegController = TextEditingController();

  bool _nonVegToday = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    if (_user == null) return;
    final vendor = await _firestoreService.getVendor(_user.email!);
    if (vendor != null && mounted) {
      final config = vendor.menuConfig;
      final parsed = <String, Map<String, dynamic>>{};
      config.forEach((key, value) {
        if (value is Map) {
          parsed[key] = Map<String, dynamic>.from(value);
        }
      });
      setState(() => _menu = parsed);
      _loadDayDetails();
    }
  }

  void _loadDayDetails() {
    final day = _weekDays[_selectedDay].toLowerCase();
    final details = _menu[day] ?? {};
    // Load veg items (fallback to legacy single-field keys)
    _breakfastVegController.text = details['breakfast_veg'] ?? details['breakfast'] ?? '';
    _lunchVegController.text = details['lunch_veg'] ?? details['lunch'] ?? '';
    _dinnerVegController.text = details['dinner_veg'] ?? details['dinner'] ?? '';
    // Load non-veg items
    _breakfastNonVegController.text = details['breakfast_nonveg'] ?? '';
    _lunchNonVegController.text = details['lunch_nonveg'] ?? '';
    _dinnerNonVegController.text = details['dinner_nonveg'] ?? '';
    _nonVegToday = details['non_veg'] ?? false;
    setState(() {});
  }

  Future<void> _saveMenu() async {
    final day = _weekDays[_selectedDay].toLowerCase();
    _menu[day] = {
      'breakfast_veg': _breakfastVegController.text,
      'breakfast_nonveg': _breakfastNonVegController.text,
      'lunch_veg': _lunchVegController.text,
      'lunch_nonveg': _lunchNonVegController.text,
      'dinner_veg': _dinnerVegController.text,
      'dinner_nonveg': _dinnerNonVegController.text,
      'non_veg': _nonVegToday,
    };
    await _firestoreService.updateVendor(_user!.email!, {
      'menu_config': _menu,
    });
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu saved!')),
      );
    }
  }

  @override
  void dispose() {
    _breakfastVegController.dispose();
    _lunchVegController.dispose();
    _dinnerVegController.dispose();
    _breakfastNonVegController.dispose();
    _lunchNonVegController.dispose();
    _dinnerNonVegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu Editor',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (_isEditing)
                  PillButton(
                    label: 'Save',
                    isSmall: true,
                    onPressed: _saveMenu,
                  )
                else
                  PillButton(
                    label: 'Edit',
                    isSmall: true,
                    isOutlined: true,
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Day selector
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final isActive = index == _selectedDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDay = index);
                      _loadDayDetails();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: isActive ? [] : AppShadows.cardSmall,
                      ),
                      child: Center(
                        child: Text(
                          _shortDays[index],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Non-veg toggle
            NeumorphicCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.nonVegOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant_rounded,
                            color: AppColors.nonVegOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Non-Veg Day',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _nonVegToday,
                    onChanged: _isEditing
                        ? (v) => setState(() => _nonVegToday = v)
                        : null,
                    activeTrackColor: AppColors.nonVegOrange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Meal items
            _mealInput(
              'Breakfast',
              '08:00 - 09:00',
              _breakfastVegController,
              _breakfastNonVegController,
              Icons.wb_sunny_rounded,
              const Color(0xFFFF9800),
            ),
            const SizedBox(height: 12),
            _mealInput(
              'Lunch',
              '13:00 - 14:00',
              _lunchVegController,
              _lunchNonVegController,
              Icons.wb_cloudy_rounded,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            _mealInput(
              'Dinner',
              '20:00 - 21:00',
              _dinnerVegController,
              _dinnerNonVegController,
              Icons.nightlight_round,
              const Color(0xFF5C6BC0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealInput(
    String title,
    String time,
    TextEditingController vegController,
    TextEditingController nonVegController,
    IconData icon,
    Color color,
  ) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Veg items field
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 16, color: AppColors.vegGreen),
              const SizedBox(width: 6),
              Text(
                'Veg Items',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.vegGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: vegController,
            enabled: _isEditing,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter veg $title items...',
              hintStyle: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          const SizedBox(height: 14),
          // Non-veg items field
          Row(
            children: [
              Icon(Icons.restaurant_rounded, size: 16, color: AppColors.nonVegOrange),
              const SizedBox(width: 6),
              Text(
                'Non-Veg Items',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nonVegOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: nonVegController,
            enabled: _isEditing,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter non-veg $title items...',
              hintStyle: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
            style: GoogleFonts.manrope(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
