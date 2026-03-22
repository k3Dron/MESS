import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/pill_button.dart';
import '../../services/firestore_service.dart';
import '../../models/comment_model.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  String _vendorName = '';
  String _vendorCode = '';
  Map<String, Map<String, int>> _headcounts = {};
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
      setState(() {
        _vendorName = vendor.name;
        _vendorCode = vendor.uniqueCode;
      });
      // Load today's headcounts
      final now = DateTime.now();
      final counts = await _firestoreService.getMealHeadcounts(
        _vendorCode,
        now.month,
        now.day,
      );
      if (mounted) {
        setState(() {
          _headcounts = counts;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
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
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _vendorName.isNotEmpty ? _vendorName[0].toUpperCase() : 'V',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vendorName.isNotEmpty ? _vendorName : 'Vendor',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Code: $_vendorCode',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppColors.textLight,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Headcount Section
            Text(
              "Today's Headcount",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // ── Boys Hostel ──
              _hostelHeadcountSection(
                'Boys Hostel',
                Icons.male_rounded,
                const Color(0xFF42A5F5),
                _headcounts['boys'] ?? {},
              ),
              const SizedBox(height: 20),
              // ── Girls Hostel ──
              _hostelHeadcountSection(
                'Girls Hostel',
                Icons.female_rounded,
                const Color(0xFFEC407A),
                _headcounts['girls'] ?? {},
              ),
            ],
            const SizedBox(height: 28),

            // Request Queue
            Text(
              'Pending Requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildRequestQueue(),
            const SizedBox(height: 28),

            // Recent Comments
            Text(
              'Recent Comments',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentComments(),
          ],
        ),
      ),
    );
  }

  Widget _hostelHeadcountSection(
    String title,
    IconData titleIcon,
    Color accentColor,
    Map<String, int> counts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(titleIcon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _headcountCard(
          'Breakfast',
          Icons.wb_sunny_rounded,
          const Color(0xFFFFF3E0),
          const Color(0xFFFF9800),
          counts['breakfast_veg'] ?? 0,
          counts['breakfast_nv'] ?? 0,
        ),
        const SizedBox(height: 10),
        _headcountCard(
          'Lunch',
          Icons.wb_cloudy_rounded,
          const Color(0xFFE8F5E9),
          const Color(0xFF4CAF50),
          counts['lunch_veg'] ?? 0,
          counts['lunch_nv'] ?? 0,
        ),
        const SizedBox(height: 10),
        _headcountCard(
          'Dinner',
          Icons.nightlight_round,
          const Color(0xFFE8EAF6),
          const Color(0xFF5C6BC0),
          counts['dinner_veg'] ?? 0,
          counts['dinner_nv'] ?? 0,
        ),
      ],
    );
  }

  Widget _headcountCard(
    String meal,
    IconData icon,
    Color bgColor,
    Color iconColor,
    int veg,
    int nonVeg,
  ) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _countChip('Veg', veg, AppColors.vegGreen),
                    const SizedBox(width: 10),
                    _countChip('Non-Veg', nonVeg, AppColors.nonVegOrange),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${veg + nonVeg}',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Total',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$label: $count',
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRequestQueue() {
    if (_user == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.requestsStream(_user.email!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return NeumorphicCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No pending requests',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isParcel = data['type'] == 'parcel';
            return NeumorphicCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isParcel ? AppColors.warning : AppColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isParcel
                          ? Icons.delivery_dining_rounded
                          : Icons.lock_open_rounded,
                      color:
                          isParcel ? AppColors.warning : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isParcel ? 'Parcel Request' : 'Unlock Request',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data['student_email'] ?? '',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                        if ((data['reason'] ?? '').isNotEmpty)
                          Text(
                            data['reason'],
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
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentComments() {
    if (_vendorCode.isEmpty) {
      return NeumorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Loading...',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ),
        ),
      );
    }
    return StreamBuilder(
      stream: _firestoreService.commentsStream(_vendorCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return NeumorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No comments yet',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          );
        }
        final comments = snapshot.data!.take(5).toList();
        return Column(
          children: comments
              .map((c) => NeumorphicCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  AppColors.vegGreen.withValues(alpha: 0.15),
                              child: Text(
                                c.authorName.isNotEmpty
                                    ? c.authorName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.vegGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.authorName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.favorite_rounded,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${c.likes}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showReplyDialog(c),
                              child: Icon(
                                c.reply.isNotEmpty
                                    ? Icons.edit_note_rounded
                                    : Icons.reply_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.text,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (c.reply.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.subdirectory_arrow_right_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    c.reply,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  void _showReplyDialog(CommentModel comment) {
    final controller = TextEditingController(text: comment.reply);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reply to ${comment.authorName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Type your reply...',
            hintStyle: GoogleFonts.manrope(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope()),
          ),
          PillButton(
            label: 'Submit',
            isSmall: true,
            onPressed: () async {
              final reply = controller.text.trim();
              Navigator.pop(context);
              
              if (reply.isEmpty) return;

              try {
                await _firestoreService.replyToComment(
                  _vendorCode,
                  comment.id,
                  reply,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reply submitted!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
