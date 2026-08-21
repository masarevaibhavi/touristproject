import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // Get history of currently logged-in user
  Stream<QuerySnapshot<Map<String, dynamic>>> getHistory() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  // Delete one history item
  Future<void> deleteHistory(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('history')
          .doc(documentId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting history: $e');
    }
  }

  // Delete all history of current user
  Future<void> clearAllHistory(
      BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
      ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text(
            'Are you sure you want to delete your complete history?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final document in documents) {
        batch.delete(document.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Recently viewed';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: getHistory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }

              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear history',
                onPressed: () {
                  clearAllHistory(
                    context,
                    snapshot.data!.docs,
                  );
                },
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: getHistory(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // User not logged in
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Please login to view your history',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // No history
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyHistory();
          }

          final history = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final document = history[index];
              final data = document.data();

              final placeName =
                  data['placeName']?.toString() ?? 'Unknown Place';

              final city =
                  data['city']?.toString() ?? 'Maharashtra';

              final category =
                  data['category']?.toString() ?? 'Tourist Place';

              final imageUrl =
                  data['imageUrl']?.toString() ?? '';

              final timestamp =
              data['visitedAt'] as Timestamp?;

              return _historyCard(
                context: context,
                documentId: document.id,
                placeName: placeName,
                city: city,
                category: category,
                imageUrl: imageUrl,
                date: formatDate(timestamp),
              );
            },
          );
        },
      ),
    );
  }

  // Empty history UI
  Widget _emptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 70,
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'No History Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Places you explore will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // History card
  Widget _historyCard({
    required BuildContext context,
    required String documentId,
    required String placeName,
    required String city,
    required String category,
    required String imageUrl,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(10),

        child: Row(
          children: [
            // Place image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),

              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,

                errorBuilder:
                    (context, error, stackTrace) {
                  return _imagePlaceholder();
                },
              )
                  : _imagePlaceholder(),
            ),

            const SizedBox(width: 14),

            // Information
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    placeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          city,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 15,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),

              onPressed: () async {
                await deleteHistory(documentId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade200,

      child: const Icon(
        Icons.image_outlined,
        size: 35,
        color: Colors.grey,
      ),
    );
  }
}