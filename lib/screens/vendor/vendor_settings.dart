import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/pill_button.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class VendorSettings extends StatefulWidget {
  const VendorSettings({super.key});

  @override
  State<VendorSettings> createState() => _VendorSettingsState();
}

class _VendorSettingsState extends State<VendorSettings> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _user = FirebaseAuth.instance.currentUser;

  String _vendorName = '';
  String _vendorCode = '';
  int _studentCount = 0;

  // ── Meal Prices ──────────────────────────────────────────────
  final _breakfastCtrl = TextEditingController();
  final _lunchVegCtrl = TextEditingController();
  final _lunchNonVegCtrl = TextEditingController();
  final _dinnerVegCtrl = TextEditingController();
  final _dinnerNonVegCtrl = TextEditingController();
  final _semesterFeeCtrl = TextEditingController();
  Map<String, String> _lockTimes = {
    'breakfast': '07:00',
    'lunch': '12:00',
    'dinner': '19:00',
  };
  bool _savingPrices = false;

  // ── Plans ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _plans = [];
  bool _savingPlans = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) return;
    final vendor = await _firestoreService.getVendor(_user.email!);
    if (vendor != null && mounted) {
      final students =
          await _firestoreService.getStudentsByVendorCode(vendor.uniqueCode);

      // Populate meal price controllers
      _breakfastCtrl.text = vendor.mealPrices['breakfast']?.toStringAsFixed(0) ?? '50';
      _lunchVegCtrl.text = vendor.mealPrices['lunch_veg']?.toStringAsFixed(0) ?? '70';
      _lunchNonVegCtrl.text = vendor.mealPrices['lunch_nonveg']?.toStringAsFixed(0) ?? '80';
      _dinnerVegCtrl.text = vendor.mealPrices['dinner_veg']?.toStringAsFixed(0) ?? '70';
      _dinnerNonVegCtrl.text = vendor.mealPrices['dinner_nonveg']?.toStringAsFixed(0) ?? '80';
      _semesterFeeCtrl.text = vendor.semesterFee.toStringAsFixed(0);
      _lockTimes = Map<String, String>.from(vendor.lockTimes);

      setState(() {
        _vendorName = vendor.name;
        _vendorCode = vendor.uniqueCode;
        _studentCount = students.length;
        _plans = vendor.plans.map((p) => Map<String, dynamic>.from(p)).toList();
      });
    }
  }

  // ── Save Meal Prices ────────────────────────────────────────
  Future<void> _saveMealPrices() async {
    setState(() => _savingPrices = true);
    try {
      final prices = {
        'breakfast': double.tryParse(_breakfastCtrl.text) ?? 50,
        'lunch_veg': double.tryParse(_lunchVegCtrl.text) ?? 70,
        'lunch_nonveg': double.tryParse(_lunchNonVegCtrl.text) ?? 80,
        'dinner_veg': double.tryParse(_dinnerVegCtrl.text) ?? 70,
        'dinner_nonveg': double.tryParse(_dinnerNonVegCtrl.text) ?? 80,
      };
      await _firestoreService.updateVendor(_user!.email!, {
        'meal_prices': prices,
        'semester_fee': double.tryParse(_semesterFeeCtrl.text) ?? BillingConstants.baseFee,
        'lock_times': _lockTimes,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal prices updated!'),
            backgroundColor: AppColors.vegGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _savingPrices = false);
  }

  // ── Save Plans ──────────────────────────────────────────────
  Future<void> _savePlans() async {
    setState(() => _savingPlans = true);
    try {
      await _firestoreService.updateVendor(_user!.email!, {
        'plans': _plans,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plans updated!'),
            backgroundColor: AppColors.vegGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _savingPlans = false);
  }

  void _addPlan() {
    final nextId = _plans.isEmpty
        ? 1
        : (_plans.map((p) => p['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    setState(() {
      _plans.add({
        'id': nextId,
        'amount': 2000,
        'months': 6,
        'label': 'Plan $nextId - ₹2,000/mo × 6',
      });
    });
  }

  void _deletePlan(int index) {
    setState(() => _plans.removeAt(index));
  }

  @override
  void dispose() {
    _breakfastCtrl.dispose();
    _lunchVegCtrl.dispose();
    _lunchNonVegCtrl.dispose();
    _dinnerVegCtrl.dispose();
    _dinnerNonVegCtrl.dispose();
    _semesterFeeCtrl.dispose();
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
            Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 28),

            // Vendor Code Card
            NeumorphicCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Your Vendor Code',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _vendorCode,
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PillButton(
                    label: 'Copy Code',
                    isSmall: true,
                    isOutlined: true,
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _vendorCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vendor code copied!')),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share this code with students to connect',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Info
            NeumorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vendor Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.storefront_rounded, 'Mess Name', _vendorName),
                  const Divider(height: 24),
                  _infoRow(Icons.email_outlined, 'Email', _user?.email ?? ''),
                  const Divider(height: 24),
                  _infoRow(Icons.people_outline_rounded, 'Students',
                      '$_studentCount enrolled'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Meal Prices Editor ────────────────────────────
            _buildMealPricesEditor(),
            const SizedBox(height: 20),

            // ── Lock Times Editor ─────────────────────────────
            _buildLockTimesEditor(),
            const SizedBox(height: 20),

            // ── Plans Editor ──────────────────────────────────
            _buildPlansEditor(),
            const SizedBox(height: 20),

            // Logout
            SizedBox(
              width: double.infinity,
              child: PillButton(
                label: 'Sign Out',
                color: AppColors.danger,
                icon: Icons.logout_rounded,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await _authService.signOut();
                  if (mounted) {
                    nav.pushReplacementNamed('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Meal Prices Editor Widget ───────────────────────────────
  Widget _buildMealPricesEditor() {
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.nonVegOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu_rounded,
                    size: 20, color: AppColors.nonVegOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Meal Prices',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Set the price for each meal type. Students will be billed based on these prices.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          _priceField('Breakfast', _breakfastCtrl, Icons.wb_sunny_rounded),
          const SizedBox(height: 10),
          _priceField('Lunch (Veg)', _lunchVegCtrl, Icons.eco_rounded),
          const SizedBox(height: 10),
          _priceField('Lunch (Non-Veg)', _lunchNonVegCtrl, Icons.set_meal_rounded),
          const SizedBox(height: 10),
          _priceField('Dinner (Veg)', _dinnerVegCtrl, Icons.eco_rounded),
          const SizedBox(height: 10),
          _priceField('Dinner (Non-Veg)', _dinnerNonVegCtrl, Icons.set_meal_rounded),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _priceField('Semester Fee', _semesterFeeCtrl, Icons.school_rounded),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: _savingPrices ? 'Saving...' : 'Save Prices',
              color: AppColors.vegGreen,
              icon: Icons.save_rounded,
              isLoading: _savingPrices,
              onPressed: () { _saveMealPrices(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceField(String label, TextEditingController controller, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Lock Times Editor Widget ────────────────────────────────
  Widget _buildLockTimesEditor() {
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_clock_rounded,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Meal Lock Times',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cutoff time for students to change their meal state for the day.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          _lockTimeField('Breakfast', 'breakfast', Icons.wb_sunny_rounded),
          const SizedBox(height: 12),
          _lockTimeField('Lunch', 'lunch', Icons.eco_rounded),
          const SizedBox(height: 12),
          _lockTimeField('Dinner', 'dinner', Icons.set_meal_rounded),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: _savingPrices ? 'Saving...' : 'Save Lock Times',
              color: AppColors.primary,
              icon: Icons.save_rounded,
              isLoading: _savingPrices,
              onPressed: () { _saveMealPrices(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockTimeField(String label, String key, IconData icon) {
    final timeStr = _lockTimes[key] ?? '07:00';
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final parts = timeStr.split(':');
            final initialTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            if (picked != null) {
              setState(() {
                final h = picked.hour.toString().padLeft(2, '0');
                final m = picked.minute.toString().padLeft(2, '0');
                _lockTimes[key] = '$h:$m';
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Plans Editor Widget ─────────────────────────────────────
  Widget _buildPlansEditor() {
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Billing Plans',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure the plans students can choose from. Changes will reflect immediately for all students.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_plans.length, (i) => _planCard(i)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: 'Add Plan',
              isOutlined: true,
              icon: Icons.add_rounded,
              onPressed: _addPlan,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: _savingPlans ? 'Saving...' : 'Save Plans',
              color: AppColors.primary,
              icon: Icons.save_rounded,
              isLoading: _savingPlans,
              onPressed: () { _savePlans(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(int index) {
    final plan = _plans[index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${plan['id']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Plan ${plan['id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (_plans.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.danger),
                  onPressed: () => _deletePlan(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _planField(
                  label: 'Amount/mo',
                  value: '${plan['amount']}',
                  prefix: '₹',
                  onChanged: (val) {
                    final amount = int.tryParse(val) ?? plan['amount'];
                    setState(() {
                      _plans[index]['amount'] = amount;
                      _plans[index]['label'] =
                          'Plan ${plan['id']} - ₹${_formatAmount(amount)}/mo × ${plan['months']}';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _planField(
                  label: 'Months',
                  value: '${plan['months']}',
                  onChanged: (val) {
                    final months = int.tryParse(val) ?? plan['months'];
                    setState(() {
                      _plans[index]['months'] = months;
                      _plans[index]['label'] =
                          'Plan ${plan['id']} - ₹${_formatAmount(plan['amount'])}/mo × $months';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan['label'] ?? '',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planField({
    required String label,
    required String value,
    String? prefix,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 12,
          color: AppColors.textLight,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    final a = amount is int ? amount : (amount as num).toInt();
    if (a >= 1000) {
      return '${(a / 1000).toStringAsFixed(a % 1000 == 0 ? 0 : 1)},${(a % 1000).toString().padLeft(3, '0')}';
    }
    return a.toString();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
