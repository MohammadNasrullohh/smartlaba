import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'buat_toko_page.dart';
import 'dashboard.dart';

class StoreHubPage extends StatelessWidget {
  const StoreHubPage({super.key});

  String _formatPublishedAt(Map<String, dynamic> data) {
    DateTime? value;
    final publishedAt = data['published_at'];
    final createdAt = data['createdAt'];

    if (publishedAt is String && publishedAt.trim().isNotEmpty) {
      value = DateTime.tryParse(publishedAt);
    } else if (publishedAt is Timestamp) {
      value = publishedAt.toDate();
    } else if (createdAt is Timestamp) {
      value = createdAt.toDate();
    }

    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final minute = local.minute.toString().padLeft(2, '0');
    final hour24 = local.hour;
    final hour12 = ((hour24 + 11) % 12) + 1;
    final hour = hour12.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year, $hour.$minute $period';
  }

  Future<void> _openCreateStore(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BuatTokoPage()));

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF162B5A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            'Toko berhasil dibuat.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openStoreDashboard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> storeDoc,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final data = storeDoc.data();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
          'uid': currentUser.uid,
          'role': 'Owner',
          'storeId': storeDoc.id,
          'storeName': (data['name'] ?? '').toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!context.mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DashboardPage()));
  }

  @override
  Widget build(BuildContext context) {
    final ownerUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('stores')
              .where('ownerUid', isEqualTo: ownerUid)
              .snapshots(),
          builder: (context, snapshot) {
            final stores = [...?snapshot.data?.docs];
            stores.sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aTime =
                  (aData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                  DateTime.tryParse(
                    (aData['published_at'] ?? '').toString(),
                  )?.millisecondsSinceEpoch ??
                  0;
              final bTime =
                  (bData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                  DateTime.tryParse(
                    (bData['published_at'] ?? '').toString(),
                  )?.millisecondsSinceEpoch ??
                  0;
              return aTime.compareTo(bTime);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                  child: Text(
                    'SmartLaba',
                    style: GoogleFonts.unbounded(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF162B5A),
                    ),
                  ),
                ),
                Container(
                  height: 0.6,
                  width: double.infinity,
                  color: Colors.black,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 18, 10, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'Daftar Toko',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF202020),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF162B5A),
                              ),
                            ),
                          )
                        else if (stores.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 256,
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      22,
                                      24,
                                      26,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'SmartLaba',
                                          style: GoogleFonts.unbounded(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF162B5A),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          width: 62,
                                          height: 62,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F2F5),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.storefront_rounded,
                                            size: 34,
                                            color: Color(0xFF4A73F1),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Selamat Datang!',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF2A2A2A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Kelola toko dengan mudah dari mana saja',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            height: 1.5,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: 126,
                                          height: 42,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _openCreateStore(context),
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              backgroundColor: const Color(
                                                0xFF162B5A,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                            ),
                                            child: Text(
                                              'Buat Toko >',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Anda Belum Memiliki Toko',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2A2A2A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: stores.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final store = stores[index];
                                final data = store.data();
                                final storeName = (data['name'] ?? 'TOKO')
                                    .toString();

                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () =>
                                      _openStoreDashboard(context, store),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFEFEF),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFD1D1D1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3E5EB),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2_rounded,
                                            size: 30,
                                            color: Color(0xFF4A73F1),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                storeName.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF2A2A2A,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Dipublikasikan pada :',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xFF666666,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatPublishedAt(data),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xFF666666,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
