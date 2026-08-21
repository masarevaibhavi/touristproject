// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter/foundation.dart';
//
// class CategoryPage extends StatelessWidget {
//   final String category;
//
//   const CategoryPage({
//     super.key,
//     required this.category,
//   });
//
//   Future<void> openLocation(
//       double latitude,
//       double longitude,
//       ) async {
//     if (kIsWeb) {
//       final url = Uri.parse(
//         'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
//       );
//
//       await launchUrl(
//         url,
//         webOnlyWindowName: '_blank',
//       );
//     } else {
//       final geo = Uri(
//         scheme: 'geo',
//         path: '$latitude,$longitude',
//       );
//
//       await launchUrl(geo);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(category),
//       ),
//
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('places')
//             .where('category', isEqualTo: category)
//             .snapshots(),
//
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 "Error: ${snapshot.error}",
//               ),
//             );
//           }
//
//           if (snapshot.connectionState ==
//               ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//
//           if (!snapshot.hasData ||
//               snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: Text(
//                 "No $category places found",
//               ),
//             );
//           }
//
//           final places = snapshot.data!.docs;
//
//           return ListView.builder(
//             padding: const EdgeInsets.all(15),
//             itemCount: places.length,
//
//             itemBuilder: (context, index) {
//               final place = places[index];
//
//               return Card(
//                 margin: const EdgeInsets.only(
//                   bottom: 15,
//                 ),
//
//                 child: ListTile(
//                   contentPadding:
//                   const EdgeInsets.all(15),
//
//                   leading: const CircleAvatar(
//                     radius: 30,
//                     child: Icon(
//                       Icons.location_on,
//                     ),
//                   ),
//
//                   title: Text(
//                     place['name'].toString(),
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//
//                   subtitle: Padding(
//                     padding:
//                     const EdgeInsets.only(top: 5),
//                     child: Text(
//                       place['location'].toString(),
//                     ),
//                   ),
//
//                   trailing: const Icon(
//                     Icons.arrow_forward_ios,
//                     size: 18,
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// 2nd code
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CategoryPage extends StatefulWidget {
  final String category;

  const CategoryPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String search = '';

  // Open Google Maps
  void openMap(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),

      body: Column(
        children: [

          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search place or city',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase();
                });
              },
            ),
          ),

          // Places
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .where(
                'category',
                isEqualTo: widget.category,
              )
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                    ),
                  );
                }

                final places = snapshot.data!.docs.where((place) {
                  final name =
                  place['name'].toString().toLowerCase();

                  final city =
                  place['city'].toString().toLowerCase();

                  return name.contains(search) ||
                      city.contains(search);
                }).toList();

                if (places.isEmpty) {
                  return const Center(
                    child: Text('No places found'),
                  );
                }

                return ListView.builder(
                  itemCount: places.length,

                  itemBuilder: (context, index) {
                    final place = places[index];

                    return Card(
                      margin: const EdgeInsets.all(10),

                      child: ListTile(

                        leading: const CircleAvatar(
                          child: Icon(Icons.location_on),
                        ),

                        title: Text(
                          place['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          '${place['city']} • ${place['location']}',
                        ),

                        trailing: IconButton(
                          icon: const Icon(Icons.map),

                          onPressed: () {
                            openMap(
                              double.parse(
                                place['latitude'].toString(),
                              ),
                              double.parse(
                                place['longitude'].toString(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}