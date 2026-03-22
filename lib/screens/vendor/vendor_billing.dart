import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/pill_button.dart';
import '../../services/firestore_service.dart';
import '../../services/billing_logic.dart';
import '../../services/receipt_pdf_service.dart';
import '../../models/student_model.dart';
import '../../models/receipt_model.dart';

class VendorBilling extends StatefulWidget {
  const VendorBilling({super.key});

  @override
  State<VendorBilling> createState() => _VendorBillingState();
}

class _VendorBillingState extends State<VendorBilling> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;
  final _searchController = TextEditingController();

  String _vendorCode = '';
  String _vendorEmail = '';
  List<_StudentBillingData> _students = [];
  List<_StudentBillingData> _filteredStudents = [];
  List<Map<String, dynamic>> _semFeePending = [];
  List<Map<String, dynamic>> _vendorPlans = BillingConstants.defaultPlans;
  double _semesterFee = BillingConstants.baseFee;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) return;
    final vendor = await _firestoreService.getVendor(_user.email!);
    if (vendor != null && mounted) {
      _vendorCode = vendor.uniqueCode;
      _vendorEmail = vendor.email;
      _vendorPlans = vendor.plans;
      _semesterFee = vendor.semesterFee;
      final students =
          await _firestoreService.getStudentsByVendorCode(_vendorCode);

      // Load billing data for each student
      final now = DateTime.now();
      final billingDataList = <_StudentBillingData>[];
      for (final student in students) {
        // Current month (in-progress, not clearable)
        final currentBilling = await _firestoreService.getMonthBilling(
          student.email,
          _vendorCode,
          now.month,
        );
        billingDataList.add(_StudentBillingData(
          student: student,
          monthlyExp: currentBilling?.monthlyExp ?? 0,
          paidStatus: 'in_progress',
          month: now.month,
          isCurrentMonth: true,
        ));

        // Check previous month if unpaid
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevBilling = await _firestoreService.getMonthBilling(
          student.email,
          _vendorCode,
          prevMonth,
        );
        if (prevBilling != null &&
            prevBilling.paidStatus != 'paid' &&
            prevBilling.monthlyExp > 0) {
          billingDataList.add(_StudentBillingData(
            student: student,
            monthlyExp: prevBilling.monthlyExp,
            paidStatus: prevBilling.paidStatus,
            month: prevMonth,
            isCurrentMonth: false,
          ));
        }
      }

      // Load semester fee pending bills
      final allPendingSnap = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(_vendorEmail)
          .collection('pending_bills')
          .where('type', isEqualTo: 'semester_fee')
          .get();
      final semFees = allPendingSnap.docs
          .map((doc) => doc.data())
          .toList();

      if (mounted) {
        setState(() {
          _students = billingDataList;
          _semFeePending = semFees;
          _filteredStudents = List.from(_students);
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String query) {
    setState(() {
      _filteredStudents = _students.where((s) {
        final q = query.toLowerCase();
        return s.student.email.toLowerCase().contains(q) ||
            s.student.name.toLowerCase().contains(q) ||
            s.student.hostelNo.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _clearBill(_StudentBillingData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Clear Bill',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clear bill for ${data.student.name}?',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₹${data.monthlyExp.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A receipt with a unique code will be generated for both you and the student.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          PillButton(
            label: 'Clear & Generate Receipt',
            isSmall: true,
            color: AppColors.vegGreen,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final receiptCode = ReceiptModel.generateReceiptCode();
      final receiptId =
          '${data.student.email}_${data.month}_${DateTime.now().millisecondsSinceEpoch}';

      // Calculate billing
      final billingResult = BillingLogic.calculateMonthBilling(
        monthlyExpense: data.monthlyExp,
        planId: data.student.selectedPlan,
        currentBuffer: BillingConstants.securityDeposit,
        plans: _vendorPlans,
      );

      final receipt = ReceiptModel(
        id: receiptId,
        receiptCode: receiptCode,
        expenditure: data.monthlyExp,
        planDeduction: billingResult.planAllowance,
        finalCost: billingResult.pendingBill,
        bufferUsed: billingResult.bufferUsed,
        date: DateTime.now(),
        studentEmail: data.student.email,
        vendorCode: _vendorCode,
        month: data.month,
      );

      // 1. Save receipt to student DB
      await _firestoreService.addReceipt(
        data.student.email,
        _vendorCode,
        receipt,
      );

      // 2. Save receipt to vendor DB
      await _firestoreService.addVendorReceipt(_vendorEmail, receipt);

      // 3. Clear the month billing on student side
      await _firestoreService.clearMonthBilling(
        data.student.email,
        _vendorCode,
        data.month,
      );

      // 4. Mark student billing status as paid
      await _firestoreService.updateStudent(data.student.email, {
        'billing_status': 'paid',
      });

      // 5. Delete pending bill from vendor DB
      await _firestoreService.deletePendingBill(
        _vendorEmail,
        data.student.email,
        data.month,
      );

      // 6. Notify student
      await _firestoreService.addStudentNotification(
        data.student.email,
        _vendorCode,
        'Your bill for Month ${data.month} has been cleared. Receipt code: $receiptCode',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill cleared! Receipt: $receiptCode'),
            backgroundColor: AppColors.vegGreen,
            action: SnackBarAction(
              label: 'Download PDF',
              textColor: Colors.white,
              onPressed: () => ReceiptPdfService.downloadReceipt(receipt),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }

      // Reload data
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _issueSemesterFee() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students linked to your code.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Issue Semester Fee',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will issue a semester fee of ₹${_semesterFee.toStringAsFixed(0)} to all ${_students.length} linked students.',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Students who have already paid will be notified. Students with pending bills will be updated.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          PillButton(
            label: 'Issue to All',
            isSmall: true,
            color: AppColors.accent,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final semFee = _semesterFee;
      int notified = 0;

      for (final data in _students) {
        final wasPaid = data.student.billingStatus == 'paid';

        // Set billing_status to pending
        await _firestoreService.updateStudent(data.student.email, {
          'billing_status': 'pending',
        });

        // Write pending bill to vendor DB
        await _firestoreService.setPendingBill(
          vendorEmail: _vendorEmail,
          studentEmail: data.student.email,
          studentName: data.student.name,
          month: 0,
          amount: semFee,
          type: 'semester_fee',
        );

        // If was paid, send notification
        if (wasPaid) {
          await _firestoreService.addStudentNotification(
            data.student.email,
            _vendorCode,
            'New semester fee of ₹${semFee.toStringAsFixed(0)} has been issued. Please select a plan and complete payment.',
          );
          notified++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Semester fee issued to ${_students.length} students ($notified newly notified).',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Billing',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by email or hostel number...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 12),

          // Issue Semester Fee Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: PillButton(
                label: 'Issue New Semester Fee',
                isSmall: false,
                color: AppColors.accent,
                icon: Icons.school_rounded,
                onPressed: _issueSemesterFee,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Student List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Text(
                          'No students found',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: _semFeePending.length +
                            _filteredStudents.length,
                        itemBuilder: (context, index) {
                          // Semester fee cards first
                          if (index < _semFeePending.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _semFeeCard(
                                  _semFeePending[index]),
                            );
                          }
                          // Then monthly billing cards
                          final billingIndex =
                              index - _semFeePending.length;
                          return _studentBillingCard(
                              _filteredStudents[billingIndex]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _studentBillingCard(_StudentBillingData data) {
    final isPaid = data.paidStatus == 'paid';
    final isInProgress = data.isCurrentMonth;
    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthLabel = data.month > 0 && data.month <= 12
        ? monthNames[data.month]
        : 'Month ${data.month}';

    // Status badge
    String statusLabel;
    Color statusColor;
    if (isPaid) {
      statusLabel = 'Paid';
      statusColor = AppColors.vegGreen;
    } else if (isInProgress) {
      statusLabel = 'In Progress';
      statusColor = AppColors.primary;
    } else {
      statusLabel = 'Pending';
      statusColor = AppColors.danger;
    }

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  data.student.name.isNotEmpty
                      ? data.student.name[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.student.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${data.student.email} • Hostel ${data.student.hostelNo}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount and month info
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  '₹${data.monthlyExp.toStringAsFixed(0)} • $monthLabel',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              // Only show Clear Bill for past unpaid months
              if (!isPaid && !isInProgress && data.monthlyExp > 0)
                PillButton(
                  label: 'Clear Bill',
                  isSmall: true,
                  color: AppColors.vegGreen,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _clearBill(data),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _semFeeCard(Map<String, dynamic> data) {
    final email = data['student_email'] ?? '';
    final name = data['student_name'] ?? '';
    final amount = (data['amount'] ?? 0).toDouble();

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded,
                    color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : email,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Semester Fee \u2022 \u20b9${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Unpaid',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: 'Mark as Paid',
              isSmall: true,
              color: AppColors.vegGreen,
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => _clearSemFee(email, name),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearSemFee(String studentEmail, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Confirm Semester Fee Payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Mark semester fee for ${studentName.isNotEmpty ? studentName : studentEmail} as paid?',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          PillButton(
            label: 'Confirm',
            isSmall: true,
            color: AppColors.vegGreen,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 1. Mark student billing as paid
      await _firestoreService.updateStudent(studentEmail, {
        'billing_status': 'paid',
      });

      // 2. Delete semester fee pending bill from vendor DB
      await _firestoreService.deletePendingBill(
        _vendorEmail,
        studentEmail,
        0,
        type: 'semester_fee',
      );

      // 3. Notify student
      await _firestoreService.addStudentNotification(
        studentEmail,
        _vendorCode,
        'Your semester fee has been confirmed as paid by the vendor.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Semester fee for $studentName marked as paid.'),
            backgroundColor: AppColors.vegGreen,
          ),
        );
      }

      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Internal data class to bundle student + billing info.
class _StudentBillingData {
  final StudentModel student;
  final double monthlyExp;
  final String paidStatus;
  final int month;
  final bool isCurrentMonth;

  _StudentBillingData({
    required this.student,
    required this.monthlyExp,
    required this.paidStatus,
    required this.month,
    this.isCurrentMonth = false,
  });
}
