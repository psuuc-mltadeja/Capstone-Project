import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class PostStatusScreen extends StatefulWidget {
  const PostStatusScreen({super.key});

  @override
  State<PostStatusScreen> createState() => _PostStatusScreenState();
}

class _PostStatusScreenState extends State<PostStatusScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _firstName = '';
  String _lastName = '';
  String? profileImageUrl;
  String? imageUrl;
  final ImagePicker _picker = ImagePicker();
  String? imagePath;
  bool isLoading = false;
  List<String> _prohibitedWords = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the widget is initialized.
    _fetchProhibitedWords(); // Fetch prohibited words from Firestore.
  }

  Future<void> _fetchProhibitedWords() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('filter_words').get();

      setState(() {
        _prohibitedWords =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Error fetching prohibited words: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching prohibited words: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _containsProhibitedWords(String text) {
    for (String word in _prohibitedWords) {
      if (text.toLowerCase().contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (image != null) {
      setState(() {
        imagePath = image.path; // Store the picked image path
      });
      // Upload the image to Firebase
      await uploadImageToFirebase(
          File(image.path)); // Upload the selected image
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
          content: Text("Error: ${e}"),
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
      String? googlePhotoUrl = user.photoURL; // Check Google photo URL
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _firstName = userDoc['firstname'] ?? 'Unknown';
          _lastName = userDoc['lastname'] ?? '';
          // Use Firestore's profileImageUrl if available, otherwise Google photo URL, otherwise null
          profileImageUrl = userDoc['profileImageUrl'] ?? googlePhotoUrl;
        });
      } else {
        setState(() {
          _firstName = 'Unknown';
          _lastName = '';
          profileImageUrl = googlePhotoUrl;
        });
      }
    }
  }

  void _submitData() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();
    String _username = "$_firstName $_lastName";
    String? uploadedImageUrl;

    if (title.isNotEmpty && body.isNotEmpty) {
      // Check for prohibited words.
      if (_containsProhibitedWords(title) || _containsProhibitedWords(body)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your post contains prohibited words. Please edit.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      try {
        // Generate a unique postId.
        String postId = DateTime.now().microsecondsSinceEpoch.toString();

        // Check if an image has been selected and upload it.
        if (imagePath != null) {
          uploadedImageUrl = await uploadImageToFirebase(File(imagePath!));
        }

        var newPost = {
          'title': title,
          'body': body,
          'username': _username,
          'date': FieldValue.serverTimestamp(),
          'imageUrl': uploadedImageUrl,
          'profileImageUrl': profileImageUrl,
        };

        // Add the new post to the `crowdsourcing` collection with custom postId.
        await FirebaseFirestore.instance
            .collection('crowdsourcing')
            .doc(postId) // Use postId as document ID.
            .set(newPost);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Posted successfully!'),
            duration: Duration(seconds: 2),
          ),
        );

        _titleController.clear();
        _bodyController.clear();
        setState(() {
          imagePath = null;
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
          content: Text('Please fill in both title and body.'),
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
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView to allow scrolling
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Compose Post',
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
                          : const AssetImage('assets/images/images.png')
                              as ImageProvider,
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
              const SizedBox(height: 20),
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
                        SizedBox(width: 50),
                        Text(
                          "or",
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                        SizedBox(width: 50),
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
      ),
    );
  }
}
