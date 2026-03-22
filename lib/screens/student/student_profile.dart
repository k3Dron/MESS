import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/pill_button.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../../models/receipt_model.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _user = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _hostelController = TextEditingController();
  final _vendorCodeController = TextEditingController();
  bool _isEditing = false;
  String _oldVendorCode = '';
  String _vendorCode = '';
  String _billingStatus = 'active';
  int _selectedPlan = 1;
  List<ReceiptModel> _receipts = [];
  List<Map<String, dynamic>> _vendorPlans = BillingConstants.defaultPlans;
  double _semesterFee = BillingConstants.baseFee;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    final student = await _firestoreService.getStudent(_user.email!);
    if (student != null && mounted) {
      _nameController.text = student.name;
      _hostelController.text = student.hostelNo;
      _vendorCodeController.text = student.vendorCode;
      _oldVendorCode = student.vendorCode;
      _vendorCode = student.vendorCode;
      _billingStatus = student.billingStatus;
      _selectedPlan = student.selectedPlan;

      // Load vendor plans
      if (student.vendorCode.isNotEmpty) {
        final vendor = await _firestoreService.getVendorByCode(student.vendorCode);
        if (vendor != null && mounted) {
          setState(() {
            _vendorPlans = vendor.plans;
            _semesterFee = vendor.semesterFee;
          });
        }
        // Load receipts
        final receipts = await _firestoreService.getReceipts(
          _user.email!,
          student.vendorCode,
        );
        if (mounted) setState(() => _receipts = receipts);
      }
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    final newVendorCode = _vendorCodeController.text.trim();
    await _firestoreService.updateStudent(_user!.email!, {
      'name': _nameController.text.trim(),
      'hostel_no': _hostelController.text.trim(),
      'vendor_code': newVendorCode,
    });

    // If vendor code changed → write semester fee as pending bill
    if (newVendorCode.isNotEmpty && newVendorCode != _oldVendorCode) {
      final vendor = await _firestoreService.getVendorByCode(newVendorCode);
      if (vendor != null) {
        final semFee = vendor.semesterFee;
        await _firestoreService.setPendingBill(
          vendorEmail: vendor.email,
          studentEmail: _user.email!,
          studentName: _nameController.text.trim(),
          month: 0, // 0 = semester fee, not a specific month
          amount: semFee,
          type: 'semester_fee',
        );
      }
      _oldVendorCode = newVendorCode;
    }

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostelController.dispose();
    _vendorCodeController.dispose();
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Row(
                  children: [
                    if (_isEditing)
                      PillButton(
                        label: 'Save',
                        isSmall: true,
                        onPressed: _saveProfile,
                      )
                    else
                      PillButton(
                        label: 'Edit',
                        isSmall: true,
                        isOutlined: true,
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        await _authService.signOut();
                        if (mounted) {
                          nav.pushReplacementNamed('/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.danger),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Card
            NeumorphicCard(
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'S',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _profileField(
                    label: 'Name',
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _profileField(
                    label: 'Hostel Number',
                    controller: _hostelController,
                    icon: Icons.apartment_rounded,
                  ),
                  const SizedBox(height: 14),
                  _profileField(
                    label: 'Vendor Code',
                    controller: _vendorCodeController,
                    icon: Icons.qr_code_rounded,
                  ),
                  const SizedBox(height: 14),
                  // Email (read-only)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 20, color: AppColors.textLight),
                        const SizedBox(width: 12),
                        Text(
                          _user?.email ?? '',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Unpaid Semester Fee Card
            if (_billingStatus == 'pending') ...[_semesterFeeCard()],

            // Receipts
            Text(
              'Receipts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (_receipts.isEmpty)
              NeumorphicCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 40,
                            color: AppColors.textLight.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No receipts yet',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_receipts.length, (i) {
                final r = _receipts[i];
                return NeumorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${r.finalCost.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                r.date.toString().substring(0, 10),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  r.receiptCode,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (r.bufferUsed > 0)
                                Text(
                                  'Buffer: ₹${r.bufferUsed.toStringAsFixed(0)}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                  ),
                                ),
                              Text(
                                'Exp: ₹${r.expenditure.toStringAsFixed(0)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: PillButton(
                          label: 'Download Receipt',
                          isSmall: true,
                          isOutlined: true,
                          icon: Icons.download_rounded,
                          onPressed: () => ReceiptPdfService.downloadReceipt(r),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _profileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  Widget _semesterFeeCard() {
    final semFee = _semesterFee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semester Fee',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        NeumorphicCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semester Fee Unpaid',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                        Text(
                          '₹${semFee.toStringAsFixed(0)} (incl. security deposit)',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Select a Plan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_vendorPlans.length, (i) {
                final planData = _vendorPlans[i];
                final planId = planData['id'] as int;
                final isSelected = _selectedPlan == planId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPlan = planId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textLight,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            planData['label'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: 'Submit Plan',
                  color: AppColors.primary,
                  icon: Icons.send_rounded,
                  onPressed: _confirmPlanPayment,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Future<void> _confirmPlanPayment() async {
    try {
      // Only save the selected plan (vendor marks as paid)
      await _firestoreService.updateStudent(_user!.email!, {
        'selected_plan': _selectedPlan,
      });

      // Notify vendor that student picked a plan
      if (_vendorCode.isNotEmpty) {
        final vendor =
            await _firestoreService.getVendorByCode(_vendorCode);
        if (vendor != null) {
          // Find the plan data for the selected plan
          final selectedPlanData = _vendorPlans.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p!['id'] == _selectedPlan,
            orElse: () => null,
          );
          final amount = selectedPlanData != null ? selectedPlanData['amount'] : '?';
          await _firestoreService.addStudentNotification(
            _user.email!,
            _vendorCode,
            'Plan $_selectedPlan selected (\u20b9$amount/mo). Awaiting payment confirmation.',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan $_selectedPlan submitted! Vendor will confirm payment.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
