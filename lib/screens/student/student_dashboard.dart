import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/meal_card_widget.dart';
import '../../services/meal_logic.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/comment_model.dart';
import '../../models/meal_day_model.dart';
import 'student_timetable.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _firestoreService = FirestoreService();
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _user = FirebaseAuth.instance.currentUser;

  // Meal states for today: [breakfast, lunch, dinner]
  List<int> _todayMeals = [0, 0, 0];
  double _monthlyExpense = 0;
  String _vendorCode = '';
  String _vendorEmail = '';
  String _userName = '';
  String? _pickedImagePath;

  // Vendor menu config for today
  Map<String, dynamic> _todayMenu = {}; // today's menu: {breakfast_veg, breakfast_nonveg, non_veg, ...}
  Map<String, double>? _mealPrices; // vendor's custom meal prices
  Map<String, String>? _lockTimes; // vendor's custom meal lock times

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) return;
    final student = await _firestoreService.getStudent(_user.email!);
    if (student != null && mounted) {
      // Look up vendor email from code
      final vendor =
          await _firestoreService.getVendorByCode(student.vendorCode);
      // Load today's menu config
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final todayDayName = dayNames[DateTime.now().weekday - 1];
      final menuConfig = vendor?.menuConfig ?? {};
      final todayMenuRaw = menuConfig[todayDayName];
      setState(() {
        _vendorCode = student.vendorCode;
        _userName = student.name;
        _vendorEmail = vendor?.email ?? '';
        _todayMenu = todayMenuRaw is Map ? Map<String, dynamic>.from(todayMenuRaw) : {};
        _mealPrices = vendor?.mealPrices;
        _lockTimes = vendor?.lockTimes;
      });
      // Load today's meals
      final now = DateTime.now();
      final mealDay = await _firestoreService.getMealDay(
        _user.email!,
        _vendorCode,
        now.month,
        now.day,
      );
      if (mealDay != null && mounted) {
        setState(() => _todayMeals = List<int>.from(mealDay.meals));
      }
      // Load monthly expenditure
      final billing = await _firestoreService.getMonthBilling(
        _user.email!,
        _vendorCode,
        now.month,
      );
      if (mounted) {
        setState(() => _monthlyExpense = billing?.monthlyExp ?? 0);
      }
    }
  }

  void _cycleMeal(int index) {
    // Check if meal is locked
    final now = DateTime.now();
    final mealType = MealType.values[index];
    if (MealLogic.isMealLocked(now, now, mealType, vendorLockTimes: _lockTimes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This meal is locked and cannot be changed.')),
      );
      return;
    }

    final oldState = _todayMeals[index];
    final nonVegAllowed = _todayMenu['non_veg'] == true;
    final nextState = MealLogic.cycleMealState(_todayMeals[index], nonVegAllowed: nonVegAllowed);

    // Show alert if user tried to go non-veg but it's not allowed
    if (!nonVegAllowed && oldState == 1 && nextState == 0) {
      // They cycled from Veg back to Absent — that's fine
    }
    if (!nonVegAllowed && oldState == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non-veg is not available today')),
      );
    }

    setState(() {
      _todayMeals[index] = nextState;
    });
    final newState = _todayMeals[index];
    // Save to Firestore and recalculate monthly expenditure
    _firestoreService.setMealDay(
      _user!.email!,
      _vendorCode,
      now.month,
      now.day,
      _buildMealDayModel(now),
    ).then((_) async {
      final newTotal = await _firestoreService.recalculateMonthlyExpenditure(
        _user.email!,
        _vendorCode,
        now.month,
        mealPrices: _mealPrices,
      );
      // Sync pending bill to vendor DB
      if (_vendorEmail.isNotEmpty) {
        if (newTotal > 0) {
          await _firestoreService.setPendingBill(
            vendorEmail: _vendorEmail,
            studentEmail: _user.email!,
            studentName: _userName,
            month: now.month,
            amount: newTotal,
          );
        } else {
          await _firestoreService.deletePendingBill(
            _vendorEmail,
            _user.email!,
            now.month,
          );
        }
      }

      // If changed to absent and was previously veg/non-veg,
      // cancel any pending parcel request for that meal
      if (newState == 0 && (oldState == 1 || oldState == 2)) {
        final mealLabels = ['Breakfast', 'Lunch', 'Dinner'];
        if (_vendorEmail.isNotEmpty) {
          final cancelled = await _firestoreService.cancelPendingParcelRequest(
            vendorEmail: _vendorEmail,
            studentEmail: _user.email!,
            mealLabel: mealLabels[index],
          );
          if (cancelled > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Parcel request cancelled (meal set to absent)'),
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() => _monthlyExpense = newTotal);
      }
    });
  }

  MealDayModel _buildMealDayModel(DateTime now) {
    return MealDayModel(
      day: now.day,
      month: now.month,
      year: now.year,
      meals: List<int>.from(_todayMeals),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImagePath = picked.path);
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty && _pickedImagePath == null) return;

    String imageUrl = '';
    if (_pickedImagePath != null) {
      imageUrl = await CloudinaryService.uploadImage(File(_pickedImagePath!)) ?? '';
    }

    final comment = CommentModel(
      id: '${_user!.email}_${DateTime.now().millisecondsSinceEpoch}',
      text: _commentController.text,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      authorEmail: _user.email!,
      authorName: _userName,
    );
    await _firestoreService.addComment(_vendorCode, comment);
    _commentController.clear();
    setState(() => _pickedImagePath = null);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Returns true if the meal's window has fully expired
  /// (meal end time + 30 min has passed). No requests allowed after this.
  bool _isMealExpired(MealType type) {
    final now = DateTime.now();
    int endHour;
    switch (type) {
      case MealType.breakfast:
        endHour = MealSchedule.breakfastEnd;
        break;
      case MealType.lunch:
        endHour = MealSchedule.lunchEnd;
        break;
      case MealType.dinner:
        endHour = MealSchedule.dinnerEnd;
        break;
    }
    final cutoff = DateTime(now.year, now.month, now.day, endHour, 30);
    return now.isAfter(cutoff);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mealStatuses = MealLogic.getTodayMealStatuses(now, vendorLockTimes: _lockTimes);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────
            _buildHeader(),
            const SizedBox(height: 24),

            // ── Stats Cards ────────────────────────
            _buildStatsRow(),
            const SizedBox(height: 24),

            // ── Today's Meals ──────────────────────
            Text(
              "Today's Meals",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              final status = mealStatuses[index];
              final expired = _isMealExpired(status.type);
              // Determine which menu items to show based on meal state
              final mealKeys = ['breakfast', 'lunch', 'dinner'];
              final mealState = _todayMeals[index];
              String? menuItems;
              if (mealState == 1) {
                menuItems = _todayMenu['${mealKeys[index]}_veg'] as String? ??
                    _todayMenu[mealKeys[index]] as String?;
              } else if (mealState == 2) {
                menuItems = _todayMenu['${mealKeys[index]}_nonveg'] as String?;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MealCardWidget(
                  mealType: status.type,
                  state: _todayMeals[index],
                  isLocked: status.isLocked,
                  menuItems: menuItems,
                  onDoubleTap: () => _cycleMeal(index),
                  onRequestTap: (status.isLocked && !expired)
                      ? () => _showRequestDialog(status.label)
                      : null,
                  onParcelTap: !expired
                      ? () => _showParcelDialog(status.label)
                      : null,
                ),
              );
            }),
            const SizedBox(height: 12),
            
            // ── Timetable Prompt ──
            _buildTimetablePromp(),
            const SizedBox(height: 24),

            // ── Comments Feed ──────────────────────
            Text(
              'Mess Feed',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildCommentInput(),
            const SizedBox(height: 12),
            _buildCommentsFeed(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetablePromp() {
    return GestureDetector(
      onTap: () {
        if (_vendorCode.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentTimetable(vendorCode: _vendorCode),
          ),
        );
      },
      child: NeumorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_view_week_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Timetable',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Check what\'s cooking this week',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, ${_userName.isNotEmpty ? _userName : 'Student'} 👋',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                _user?.email ?? '',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: NeumorphicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.currency_rupee_rounded,
                          size: 18, color: AppColors.accent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'This Month',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_monthlyExpense.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NeumorphicCard(
            padding: const EdgeInsets.all(16),
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
                      child: const Icon(Icons.qr_code_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vendor',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _vendorCode.isNotEmpty ? _vendorCode : '------',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return NeumorphicCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Say something about the food...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
              style: GoogleFonts.manrope(fontSize: 14),
            ),
          ),
          if (_pickedImagePath != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_pickedImagePath!),
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => setState(() => _pickedImagePath = null),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              _pickedImagePath != null
                  ? Icons.image_rounded
                  : Icons.image_outlined,
              color: _pickedImagePath != null
                  ? AppColors.primary
                  : AppColors.textLight,
              size: 22,
            ),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: Icon(Icons.send_rounded,
                color: AppColors.primary, size: 22),
            onPressed: _sendComment,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsFeed() {
    if (_vendorCode.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Link a vendor code to see the feed',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ),
      );
    }
    return StreamBuilder(
      stream: _firestoreService.commentsStream(_vendorCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No comments yet. Be the first!',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ),
          );
        }
        final comments = snapshot.data!;
        return Column(
          children: comments.map((c) => _commentTile(c)).toList(),
        );
      },
    );
  }

  Widget _commentTile(CommentModel comment) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.vegGreen.withValues(alpha: 0.15),
                child: Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.vegGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      _formatTime(comment.timestamp),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _firestoreService.likeComment(
                    _vendorCode, comment.id),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likes}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          if (comment.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                comment.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (comment.reply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Vendor Reply',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.reply,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showRequestDialog(String mealLabel) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Request $mealLabel Change',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          PillButton(
            label: 'Send Request',
            isSmall: true,
            onPressed: () async {
              if (_vendorEmail.isNotEmpty) {
                await _firestoreService.sendRequest(
                  vendorEmail: _vendorEmail,
                  studentEmail: _user!.email!,
                  type: 'unlock',
                  mealLabel: mealLabel,
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text+'\nMeal change request for $mealLabel'
                      : 'Meal change request for $mealLabel',
                  recipientName: _userName,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request sent to vendor!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  void _showParcelDialog(String mealLabel) {
    final recipientController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Request $mealLabel Parcel',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: recipientController,
              decoration: const InputDecoration(
                hintText: 'Recipient name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          PillButton(
            label: 'Send Parcel Request',
            isSmall: true,
            color: AppColors.warning,
            onPressed: () async {
              if (_vendorEmail.isNotEmpty) {
                await _firestoreService.sendRequest(
                  vendorEmail: _vendorEmail,
                  studentEmail: _user!.email!,
                  type: 'parcel',
                  mealLabel: mealLabel,
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'Parcel request for $mealLabel',
                  recipientName: recipientController.text.isNotEmpty
                      ? recipientController.text
                      : _userName,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Parcel request sent!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
