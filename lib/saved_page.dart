import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Places',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: user == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 85,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              'Please login to view your saved places',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved')
            .orderBy(
          'createdAt',
          descending: true,
        )
            .snapshots(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
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
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 65,
                      color: Colors.red,
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

          // Empty state
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 90,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No Saved Places',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Save places you want to visit\nand find them here later.',
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

          final savedPlaces = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedPlaces.length,
            itemBuilder: (context, index) {
              final doc = savedPlaces[index];

              final data =
              doc.data() as Map<String, dynamic>;

              final String name =
                  data['name']?.toString() ??
                      'Unknown Place';

              final String location =
                  data['location']?.toString() ??
                      'Maharashtra';

              final String imageUrl =
                  data['imageUrl']?.toString() ?? '';

              final String description =
                  data['description']?.toString() ?? '';

              return SavedPlaceCard(
                id: doc.id,
                userId: user.uid,
                name: name,
                location: location,
                imageUrl: imageUrl,
                description: description,
              );
            },
          );
        },
      ),
    );
  }
}


// ============================================================
// SAVED PLACE CARD
// ============================================================

class SavedPlaceCard extends StatelessWidget {
  final String id;
  final String userId;
  final String name;
  final String location;
  final String imageUrl;
  final String description;

  const SavedPlaceCard({
    super.key,
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.description,
  });

  // ==========================================================
  // REMOVE SAVED PLACE
  // ==========================================================

  Future<void> removeSaved(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved')
          .doc(id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Removed from saved places',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to remove saved place: $e',
            ),
          ),
        );
      }
    }
  }

  // ==========================================================
  // CONFIRM DELETE
  // ==========================================================

  void confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Saved Place?',
          ),
          content: Text(
            'Do you want to remove "$name" from your saved places?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                removeSaved(context);
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          // ==================================================
          // IMAGE
          // ==================================================

          Stack(
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 55,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.location_city,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              // Saved button
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.bookmark,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      confirmRemove(context);
                    },
                  ),
                ),
              ),
            ],
          ),

          // ==================================================
          // PLACE INFORMATION
          // ==================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                // Description
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // View details
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Opening $name',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.explore,
                    ),
                    label: const Text(
                      'View Details',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ADD PLACE TO SAVED
// ============================================================

Future<void> addToSaved({
  required String name,
  required String location,
  String imageUrl = '',
  String description = '',
}) async {
  final User? user =
      FirebaseAuth.instance.currentUser;

  if (user == null) {
    return;
  }

  try {
    // Create an ID from the place name.
    final String savedId =
    name.toLowerCase().replaceAll(' ', '_');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved')
        .doc(savedId)
        .set({
      'name': name,
      'location': location,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint(
      'Error adding saved place: $e',
    );
  }
}