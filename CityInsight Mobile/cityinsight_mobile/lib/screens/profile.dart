import 'dart:io';

import 'package:cityinsight_mobile/screens/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController fnController;
  late TextEditingController lnController;
  late TextEditingController contactController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  String creationDate = '';
  String? profileImageUrl;
  String? displayName;
  final ImagePicker _imagePicker = ImagePicker();
  String? imageUrl;
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fnController = TextEditingController();
    lnController = TextEditingController();
    contactController = TextEditingController();
    addressController = TextEditingController();
    emailController = TextEditingController();
    fetchUserData();
  }

  Future<void> pickImage() async {
    try {
      XFile? res = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (res != null) {
        await uploadImageToFirebase(File(res.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error Uploading Image: ${e}"),
        ),
      );
    }
  }

  Future<void> uploadImageToFirebase(File image) async {
    setState(() {
      isLoading = true;
    });
    try {
      Reference reference = FirebaseStorage.instance
          .ref()
          .child("assets/images/${DateTime.now().microsecondsSinceEpoch}.png");

      await reference.putFile(image).whenComplete(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            content: Text("Image Uploaded Successfully"),
          ),
        );
      });

      imageUrl = await reference.getDownloadURL();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileImageUrl': imageUrl,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: ${e}"),
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  void fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            fnController.text = data['firstname'] ?? '';
            lnController.text = data['lastname'] ?? '';
            contactController.text = data['contact'] ?? '';
            addressController.text = data['address'] ?? '';
            emailController.text = data['email'] ?? '';
            imageUrl = data['profileImageUrl'];
          });
          Timestamp? createdAt = data['created_at'] as Timestamp?;
          creationDate = createdAt != null
              ? DateFormat.yMMMd().format(createdAt.toDate())
              : 'Not available';
        }

        setState(() {
          profileImageUrl = user.photoURL;
          displayName = user.displayName;
        });
      }
    } catch (err) {
      print('Error fetching client data: $err');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error Fetching Data: $err"),
      ));
    }
  }

  void updateUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'firstname': fnController.text,
          'lastname': lnController.text,
          'contact': contactController.text,
          'address': addressController.text,
          'email': emailController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User Data Updated')),
        );
      }
    } catch (err) {
      print('Error Updating User Data: $err');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error Updating User Data: $err"),
      ));
    }
  }

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

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    fnController.dispose();
    lnController.dispose();
    contactController.dispose();
    addressController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Account Details"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Gap(22),
                  GestureDetector(
                    child: Stack(
                      children: [
                        Center(
                          child: CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: width * 0.30,
                            child: CircleAvatar(
                              radius: width * 0.30 - 5,
                              backgroundImage: profileImageUrl != null
                                  ? NetworkImage(
                                      profileImageUrl!) // For Gmail logged-in user
                                  : (imageUrl !=
                                          null // For Firebase Storage image
                                      ? NetworkImage(imageUrl!)
                                      : const AssetImage(
                                          'assets/images/images.png') // Default image if none available
                                  ),
                            ),
                          ),
                        ),
                        if (isLoading)
                          const Positioned(
                            top: 70,
                            right: 190,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 110,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: pickImage,
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: const Color.fromARGB(255, 0, 53, 97),
                              size: MediaQuery.of(context).size.height * 0.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(15),
                  Text(
                    displayName ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(15),
                  TextFormField(
                    controller: fnController,
                    decoration: const InputDecoration(
                      labelText: "First Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: lnController,
                    decoration: const InputDecoration(
                      labelText: "Last Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: "Contact Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(15),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: "Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(15),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(15),
                  ElevatedButton(
                    onPressed: () => updateUserData(),
                    child: const Text("Update"),
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Date Joined: $creationDate"),
                  const Spacer(),
                  TextButton(
                    onPressed: () => logout(),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
