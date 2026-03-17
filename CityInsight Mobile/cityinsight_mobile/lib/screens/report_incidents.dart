import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _firstName = '';
  String _lastName = '';
  String? profileImageUrl;
  String? imageUrl;
  String? selectedCategory; // Holds the selected category
  final ImagePicker _picker = ImagePicker();
  String? imagePath;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (image != null) {
      setState(() {
        imagePath = image.path;
      });

      await uploadImageToFirebase(File(image.path));
    }
  }

  Future<String?> uploadImageToFirebase(File image) async {
    setState(() {
      isLoading = true; // Show loading indicator
    });
    String? imageUrl; // Declare imageUrl here to return later
    try {
      Reference reference = FirebaseStorage.instance
          .ref()
          .child("assets/images/${DateTime.now().microsecondsSinceEpoch}.png");

      await reference.putFile(image).whenComplete(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            content: Text("Added Image / Video"),
          ),
        );
      });

      imageUrl = await reference.getDownloadURL(); // Get the image URL
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
    setState(() {
      isLoading = false; // Hide loading indicator
    });
    return imageUrl; // Return the image URL
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _firstName = userDoc['firstname'] ?? 'Unknown';
          _lastName = userDoc['lastname'] ?? '';
          profileImageUrl = userDoc['profileImageUrl']; // Fetch directly
        });
        print('Profile Image URL: $profileImageUrl'); // Debugging
      } else {
        setState(() {
          _firstName = 'Unknown';
          _lastName = '';
          profileImageUrl = null;
        });
      }
    }
  }

  void _submitData() async {
    final String title = _titleController.text;
    final String body = _bodyController.text;
    String _username = "$_firstName $_lastName";
    String? uploadedImageUrl;

    if (title.isNotEmpty && body.isNotEmpty && selectedCategory != null) {
      try {
        // Check if an image has been selected and upload it
        if (imagePath != null) {
          uploadedImageUrl = await uploadImageToFirebase(File(imagePath!));
        }

        // Get user's current location
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        var newPost = {
          'title': title,
          'body': body,
          'username': _username,
          'date': FieldValue.serverTimestamp(),
          'status': 'pending',
          'imageUrl': uploadedImageUrl,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'category': selectedCategory,
        };

        await FirebaseFirestore.instance.collection('reports').add(newPost);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report Posted successfully!'),
            duration: Duration(seconds: 2),
          ),
        );

        _titleController.clear();
        _bodyController.clear();
        setState(() {
          imagePath = null; // Reset the image path after posting
          selectedCategory = null; // Reset category
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields, including category.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: _submitData, child: const Text("Post")),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Report Incident',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: width * .10 / 2,
                  child: CircleAvatar(
                    radius: width * 0.10 - 5,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : (imageUrl != null
                            ? NetworkImage(imageUrl!)
                            : const AssetImage('assets/images/images.png')),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  'Posting as: $_firstName $_lastName',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: const [
                DropdownMenuItem(
                  value: 'Crimes',
                  child: Text('Crimes'),
                ),
                DropdownMenuItem(
                  value: 'Floods',
                  child: Text('Floods'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const Gap(10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: "What’s happening?",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const Gap(10),
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 2 / 5,
                  child: Image.file(
                    File(imagePath!),
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const Spacer(),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                      SizedBox(
                        width: 50,
                      ),
                      Text(
                        "or",
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                      SizedBox(
                        width: 50,
                      ),
                      Icon(
                        Icons.video_camera_back_outlined,
                        color: Colors.white,
                        size: 36,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
