import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'history_page.dart';
import 'favorite_page.dart';
import 'saved_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'login_page.dart';
import 'category_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final search = TextEditingController();

  final categories = [
    ["Historical", Icons.account_balance, "assets/historical.jpg"],
    ["Spiritual", Icons.temple_hindu, "assets/spiritual.jpg"],
    ["Mountains", Icons.landscape, "assets/mountains.jpg"],
    ["Beaches", Icons.beach_access, "assets/beaches.jpg"],
  ];

  Future<void> toggleFavorite(String placeId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(placeId);

    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed from favorites")),
        );
      }
    } else {
      await ref.set({
        'placeId': placeId,
        'savedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to favorites ❤️")),
        );
      }
    }
  }

  Stream<bool> isFavorite(String placeId) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(placeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<QuerySnapshot> getPlaces() {
    return FirebaseFirestore.instance
        .collection('places')
        .snapshots();
  }

  Future<void> openLocation(
      double latitude,
      double longitude,
      ) async {
    if (kIsWeb) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      await launchUrl(
        url,
        webOnlyWindowName: '_blank',
      );
    } else {
      final geo = Uri(
        scheme: 'geo',
        path: '$latitude,$longitude',
      );

      await launchUrl(geo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _drawer(context),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // TOP NAVIGATION
              _topBar(),

              // HERO
              _hero(),

              // MAIN CONTENT
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _sectionTitle(
                      "Explore Maharashtra",
                      "Discover amazing places across the state",
                    ),

                    const SizedBox(height: 20),

                    _categories(),

                    const SizedBox(height: 45),

                    _sectionTitle(
                      "Popular Destinations",
                      "Places you should not miss",
                    ),

                    const SizedBox(height: 20),

                    _places(),

                    const SizedBox(height: 35),

                    _startJourney(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TOP BAR
  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 15,
      ),
      child: Row(
        children: [

          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, size: 30),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),

          const SizedBox(width: 10),

          const Text(
            "Explore Maharashtra",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // SEARCH
          SizedBox(
            width: 320,
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search places or cities...",
                prefixIcon: const Icon(Icons.search),

                suffixIcon: search.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    search.clear();
                    setState(() {});
                  },
                )
                    : null,

                filled: true,
                fillColor: Colors.grey.shade100,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HERO
  Widget _hero() {
    return SizedBox(
      width: double.infinity,
      height: 430,
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/splash3_bg.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(50),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Colors.black.withOpacity(.75),
                Colors.transparent,
              ],
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Discover Maharashtra",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              Text(
                "Explore forts, beaches, mountains,\ntemples and unforgettable experiences.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),

              SizedBox(height: 20),

              // You can keep your Start Exploring button here
            ],
          ),
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget _sectionTitle(
      String title,
      String subtitle,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // CATEGORIES
  Widget _categories() {
    return LayoutBuilder(
      builder: (context, constraints) {

        final width = constraints.maxWidth;

        int count = 4;

        if (width < 900) {
          count = 2;
        }

        if (width < 500) {
          count = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          itemCount: categories.length,

          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 2.3,
          ),

          itemBuilder: (context, index) {

            final category = categories[index];

            return _categoryCard(
              category[0] as String,
              category[1] as IconData,
              category[2] as String,
            );
          },
        );
      },
    );
  }

  // CATEGORY CARD
  Widget _categoryCard(
      String title,
      IconData icon,
      String image,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryPage(
              category: title,
            ),
          ),
        );
      },

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],

          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(.45),
              BlendMode.darken,
            ),
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Row(
            children: [

              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 15),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIRESTORE PLACES
  Widget _places() {
    return StreamBuilder<QuerySnapshot>(
      stream: getPlaces(),

      builder: (context, snapshot) {

        if (snapshot.hasError) {
          return Text(
            "Firebase Error:\n${snapshot.error}",
            style: const TextStyle(
              color: Colors.red,
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text(
            "No places found",
          );
        }

        final searchText =
        search.text.toLowerCase();

        final places =
        snapshot.data!.docs.where((place) {

          final data =
          place.data() as Map<String, dynamic>;

          final name =
              data['name']?.toString().toLowerCase() ?? "";

          final city =
              data['city']?.toString().toLowerCase() ?? "";

          return name.contains(searchText) ||
              city.contains(searchText);

        }).toList();

        if (places.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "No matching places found",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {

            int count = 3;

            if (constraints.maxWidth < 1000) {
              count = 2;
            }

            if (constraints.maxWidth < 600) {
              count = 1;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),

              itemCount: places.length,

              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.45,
              ),

              itemBuilder: (context, index) {

                final place = places[index];

                final data =
                place.data()
                as Map<String, dynamic>;

                final latitude =
                (data['latitude'] as num?)
                    ?.toDouble();

                final longitude =
                (data['longitude'] as num?)
                    ?.toDouble();

                return _placeCard(
                  place.id,
                  data['name']?.toString() ??
                      "Unknown Place",
                  data['city']?.toString() ??
                      "Maharashtra",
                  data['location']?.toString() ??
                      "Maharashtra",
                  latitude,
                  longitude,
                );
              },
            );
          },
        );
      },
    );
  }

  // PLACE CARD
  Widget _placeCard(
      String placeId,
      String title,
      String city,
      String location,
      double? latitude,
      double? longitude,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(
              children: [

                Container(
                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                    BorderRadius.circular(15),
                  ),

                  child: const Icon(
                    Icons.location_city,
                    size: 30,
                  ),
                ),

                const Spacer(),

                StreamBuilder<bool>(
                  stream: isFavorite(placeId),

                  builder: (context, snapshot) {

                    final favorite =
                        snapshot.data ?? false;

                    return IconButton(
                      icon: Icon(
                        favorite
                            ? Icons.favorite
                            : Icons.favorite_border,

                        color: favorite
                            ? Colors.red
                            : Colors.grey,
                      ),

                      onPressed: () {
                        toggleFavorite(placeId);
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Row(
              children: [

                const Icon(
                  Icons.location_on,
                  size: 15,
                  color: Colors.grey,
                ),

                const SizedBox(width: 4),

                Expanded(
                  child: Text(
                    city,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            Row(
              children: [

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {

                      if (latitude != null &&
                          longitude != null) {

                        openLocation(
                          latitude,
                          longitude,
                        );

                      } else {

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Location is not available",
                            ),
                          ),
                        );
                      }
                    },

                    icon: const Icon(
                      Icons.map_outlined,
                      size: 18,
                    ),

                    label: const Text("Map"),

                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  icon: const Icon(
                    Icons.bookmark_border,
                  ),

                  onPressed: () {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content:
                        Text("Place saved 🔖"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // START JOURNEY
  Widget _startJourney() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.black,
      ),

      child: Row(
        children: [

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  "Ready for your next adventure?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "Explore the beauty of Maharashtra.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content:
                  Text("🌄 Your journey begins!"),
                ),
              );
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,

              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 15,
              ),

              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(30),
              ),
            ),

            child: const Text(
              "Explore Now",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DRAWER
  Widget _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,

        children: [

          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),

            accountName: Text(
              "Traveler",
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            accountEmail: Text(
              "Explore Maharashtra",
            ),

            currentAccountPicture:
            CircleAvatar(
              backgroundColor: Colors.white,

              child: Icon(
                Icons.person,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),

          _drawerItem(
            context,
            Icons.person,
            "Profile",
          ),

          _drawerItem(
            context,
            Icons.history,
            "History",
          ),

          _drawerItem(
            context,
            Icons.favorite,
            "Favorites",
          ),

          _drawerItem(
            context,
            Icons.bookmark,
            "Saved",
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),

            onTap: () async {

              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,

                MaterialPageRoute(
                  builder: (_) =>
                  const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),

      onTap: () {
        Navigator.pop(context);

        if (title == "Profile") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          );
        } else if (title == "History") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HistoryPage(),
            ),
          );
        } else if (title=="Favorites") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FavoritePage(),
          ),
        );
        } else if (title=="Saved") {
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Saved'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedPage(),
                ),
              );
            },
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title selected"),
            ),
          );
        }
      },
    );
}
}