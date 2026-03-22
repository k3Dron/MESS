import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/constants.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/pill_button.dart';
import '../../services/firestore_service.dart';

class VendorNotifications extends StatefulWidget {
  const VendorNotifications({super.key});

  @override
  State<VendorNotifications> createState() =>
      _VendorNotificationsState();
}

class _VendorNotificationsState
    extends State<VendorNotifications> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  // ============================================================
  // HANDLE REQUEST ACTION
  // ============================================================
  Future<void> _handleRequestAction(
    Map<String, dynamic> data,
    String docId,
    bool markNonVeg,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final vendorEmail = FirebaseAuth.instance.currentUser!.email!;

      final vendorDoc = await firestore.collection('vendors').doc(vendorEmail).get();
      if (!vendorDoc.exists) {
        throw Exception("Vendor document missing");
      }
      final vendorData = vendorDoc.data()!;
      final vendorCode = vendorData['unique_code'];
      if (vendorCode == null || vendorCode.isEmpty) {
        throw Exception("Vendor unique_code missing");
      }

      final studentEmail = data['student_email'];
      final mealLabel = data['meal_label'];
      final createdAt = (data['timestamp'] as Timestamp).toDate();
      final isParcel = data['type'] == 'parcel';

      final now = DateTime.now();
      final difference = now.difference(createdAt);

      // ================= TIME VALIDATION =================
      if (!isParcel && difference.inHours > 3) {
        await firestore
            .collection('vendors')
            .doc(vendorEmail)
            .collection('active_requests')
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Request expired (3hr rule).')),
        );
        return;
      }

      if (isParcel && difference.inHours > 12) {
        await firestore
            .collection('vendors')
            .doc(vendorEmail)
            .collection('active_requests')
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Parcel request expired (12hr rule).')),
        );
        return;
      }

      final requestRef = firestore
          .collection('vendors')
          .doc(vendorEmail)
          .collection('active_requests')
          .doc(docId);

      // ================= PARCEL LOGIC =================
      if (isParcel) {
        final notificationRef = firestore
            .collection('students')
            .doc(studentEmail)
            .collection('vendor_data')
            .doc(vendorCode)
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'message':
              'Your parcel will be kept ready. Please come to collect it.',
          'created_at': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
      // ================= MEAL UPDATE LOGIC =================
      else {
        final month = createdAt.month.toString();
        final day = createdAt.day.toString();

        final mealRef = firestore
            .collection('students')
            .doc(studentEmail)
            .collection('vendor_data')
            .doc(vendorCode)
            .collection('months')
            .doc(month)
            .collection('days')
            .doc(day);

        // 1️⃣ Get existing day document
        final dayDoc = await mealRef.get();

        if (!dayDoc.exists) {
          throw Exception("Day document not found");
        }

        final dayData =
            Map<String, dynamic>.from(dayDoc.data() as Map);

        List<dynamic> meals = List.from(dayData['meals'] ?? [1, 1, 1]);

        // 2️⃣ Convert meal_label to index
        int index;
        switch (mealLabel.toString().toLowerCase()) {
          case 'breakfast':
            index = 0;
            break;
          case 'lunch':
            index = 1;
            break;
          case 'dinner':
            index = 2;
            break;
          default:
            throw Exception("Invalid meal label");
        }

        // 3️⃣ Update array value
        meals[index] = markNonVeg ? 2 : 1;

        // 4️⃣ Update Firestore
        batch.update(mealRef, {
          'meals': meals,
        });

        // 5️⃣ Notify student about the unlock
        final mealTypeStr = markNonVeg ? 'Non-Veg' : 'Veg';
        final notificationRef = firestore
            .collection('students')
            .doc(studentEmail)
            .collection('vendor_data')
            .doc(vendorCode)
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'message':
              'Your $mealLabel has been unlocked and set to $mealTypeStr.',
          'created_at': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      // Delete vendor request after handling
      batch.delete(requestRef);

      await batch.commit();

      // Recalculate monthly expenditure after meal change (outside batch)
      if (!isParcel) {
        await _firestoreService.recalculateMonthlyExpenditure(
          studentEmail,
          vendorCode,
          createdAt.month,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request handled successfully')),
      );
    } catch (e, stack) {
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
            const SizedBox(height: 16),
            Expanded(
              child: _user == null
                  ? const SizedBox.shrink()
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService
                          .requestsStream(_user.email!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("No pending notifications"),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            return _notificationTile(data, docs[index].id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: _showBroadcastDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.campaign_rounded, color: Colors.white),
        ),
      ),
    );
  }

  void _showBroadcastDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Broadcast',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Type message to all students...',
            hintStyle: GoogleFonts.manrope(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope()),
          ),
          PillButton(
            label: 'Send',
            isSmall: true,
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final msg = controller.text.trim();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sending broadcast...')),
              );

              try {
                await _firestoreService.sendBroadcastNotification(
                  _user!.email!,
                  msg,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Broadcast sent successfully!')),
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

  // ============================================================
  // NOTIFICATION TILE
  // ============================================================
  Widget _notificationTile(
  Map<String, dynamic> data,
  String docId,
) {
  final isParcel = data['type'] == 'parcel';
  final isPending = data['status'] == 'pending';

  final String studentName =
      data['student_name'] ?? data['student_email'] ?? 'Student';

  return NeumorphicCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // ================= Avatar =================
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                studentName.isNotEmpty
                    ? studentName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ================= Name + Subtext =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isParcel
                        ? "Parcel Request"
                        : "Unlock Request",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${data['student_email'] ?? ''}",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            // ================= Status Pill =================
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isPending
                    ? AppColors.danger.withValues(alpha: 0.1)
                    : AppColors.vegGreen.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                isPending ? "Pending" : "Done",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPending
                      ? AppColors.danger
                      : AppColors.vegGreen,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ================= Reason Text =================
        Text(
          data['reason'] ?? '',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 12),

        // ================= Action Buttons =================
        if (isPending)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isParcel)
                PillButton(
                  label: "Mark Done",
                  isSmall: true,
                  color: AppColors.primary,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () =>
                      _handleRequestAction(data, docId, false),
                )
              else ...[
                PillButton(
                  label: "Veg",
                  isSmall: true,
                  color: AppColors.vegGreen,
                  icon: Icons.eco_outlined,
                  onPressed: () =>
                      _handleRequestAction(data, docId, false),
                ),
                const SizedBox(width: 8),
                PillButton(
                  label: "NonVeg",
                  isSmall: true,
                  color: AppColors.danger,
                  icon: Icons.local_fire_department_outlined,
                  onPressed: () =>
                      _handleRequestAction(data, docId, true),
                ),
              ],
            ],
          ),
      ],
    ),
  );
}
}