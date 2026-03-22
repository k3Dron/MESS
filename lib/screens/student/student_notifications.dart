import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../services/firestore_service.dart';

class StudentNotifications extends StatefulWidget {
  const StudentNotifications({super.key});

  @override
  State<StudentNotifications> createState() => _StudentNotificationsState();
}

class _StudentNotificationsState extends State<StudentNotifications> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;
  String _vendorCode = '';

  @override
  void initState() {
    super.initState();
    _loadVendorCode();
  }

  Future<void> _loadVendorCode() async {
    if (_user == null) return;
    final student = await _firestoreService.getStudent(_user.email!);
    if (student != null && mounted) {
      setState(() => _vendorCode = student.vendorCode);
    }
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
              'Notifications',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'All incoming updates and alerts',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: (_user == null || _vendorCode.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_rounded,
                          size: 56,
                          color: AppColors.textLight.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                        Text(
                          _vendorCode.isEmpty
                              ? 'Link a vendor code first'
                              : 'No notifications yet',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.notificationsStream(
                      _user.email!,
                      _vendorCode,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_rounded,
                                size: 56,
                                color: AppColors.textLight
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'All caught up!',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMedium,
                                ),
                              ),
                              Text(
                                'No notifications yet',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            20, 0, 20, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data()
                              as Map<String, dynamic>;
                          return _notificationTile(data);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(Map<String, dynamic> data) {
    final message = data['message'] ?? '';
    final isRead = data['read'] ?? false;
    final createdAt = data['created_at'] as Timestamp?;

    // Determine icon based on message content
    IconData icon = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;
    if (message.toString().toLowerCase().contains('parcel')) {
      icon = Icons.delivery_dining_rounded;
      iconColor = AppColors.warning;
    } else if (message.toString().toLowerCase().contains('unlock')) {
      icon = Icons.lock_open_rounded;
      iconColor = AppColors.primary;
    } else if (message.toString().toLowerCase().contains('receipt') ||
        message.toString().toLowerCase().contains('bill')) {
      icon = Icons.receipt_long_rounded;
      iconColor = AppColors.vegGreen;
    }

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight:
                              isRead ? FontWeight.w400 : FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(createdAt.toDate()),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
