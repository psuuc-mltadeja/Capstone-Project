import 'package:cityinsight_mobile/screens/about-us.dart';
import 'package:cityinsight_mobile/screens/auth.dart';
import 'package:cityinsight_mobile/screens/blocked_users.dart';
import 'package:cityinsight_mobile/screens/emergency_contacts.dart';
import 'package:cityinsight_mobile/screens/profile.dart';
import 'package:cityinsight_mobile/screens/verify_identity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen(
      {super.key,
      required this.onToggleTheme,
      required this.isDarkMode,
      required this.currentMapStyle,
      required this.onMapStyleChange});
  final Function(bool) onToggleTheme;
  final bool isDarkMode;
  final String currentMapStyle;
  final Function(String) onMapStyleChange;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkUserVerification();
  }

  Future<void> _checkUserVerification() async {
    final userId = _auth.currentUser?.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _isVerified = userDoc['isFullyVerified'] ?? false;
        });
      } else {
        setState(() {
          _isVerified = false;
        });
      }
    } catch (e) {
      print('Error fetching user verification status: $e');
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    void logout() async {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const ChooseAuth(),
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      } catch (err) {
        print('Error Logging Out: $err');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error Logging Out: $err"),
        ));
      }
    }

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const VerifyIdentityScreen(),
                ));
              },
              icon: _isVerified
                  ? const Icon(Icons.verified)
                  : const Icon(Icons.verified_outlined))
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseAuth.instance.currentUser != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error Fetching Data"),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("No user data found"),
            );
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String userName = userData['firstname'] ?? '';
          String lastName = userData['lastname'] ?? '';
          String email = userData['email'] ?? '';
          String? profileImageUrl =
              userData['profileImageUrl']; // Fetch profile image from Firestore

          // Get Google photo URL if logged in with Google
          String? googlePhotoUrl = FirebaseAuth.instance.currentUser?.photoURL;

          // Determine which image to display: uploaded image or Google profile image
          String? displayImageUrl = profileImageUrl ?? googlePhotoUrl;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: width * 0.2,
                    child: CircleAvatar(
                      radius: width * 0.2 - 4,
                      backgroundImage: displayImageUrl != null
                          ? NetworkImage(
                              displayImageUrl) // Show uploaded or Google image
                          : const AssetImage(
                              'assets/images/images.png'), // Default image if no image available
                    ),
                  ),
                ),
                const Gap(10),
                Text(
                  '$userName $lastName',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rubik(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const Gap(15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Edit Profile"),
                ),
                const Gap(15),
                Card(
                  elevation: 4, // Added elevation for shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Gap(10),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text("About Us"),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AboutUsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(), // Divider for better separation
                      ListTile(
                        leading: const Icon(Icons.contact_emergency_outlined),
                        title: const Text("Emergency Contact Numbers"),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                const EmergencyContactsScreen(),
                          ));
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.person_off_outlined),
                        title: const Text("Blocked Users"),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BlockedUserScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text("Dark Mode"),
                        value: widget.isDarkMode,
                        onChanged: widget.onToggleTheme,
                        secondary: const Icon(Icons.dark_mode_outlined),
                      ),
                      const Gap(10),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout_outlined),
                        title: const Text("Logout"),
                        onTap: () => logout(),
                      ),
                      const Gap(10),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
