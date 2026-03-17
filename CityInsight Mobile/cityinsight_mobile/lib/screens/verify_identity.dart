import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String? faceImageUrl;
  String? idImageUrl;
  bool isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkUserVerification();
  }

  Future<void> _checkUserVerification() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

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

  Future<void> pickImage({required bool isFace}) async {
    try {
      XFile? res = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (res != null) {
        await uploadImageToFirebase(File(res.path), isFace: isFace);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error Uploading Image: $e"),
        ),
      );
    }
  }

  Future<void> uploadImageToFirebase(File image, {required bool isFace}) async {
    setState(() {
      isLoading = true;
    });

    try {
      String imageType = isFace ? "face" : "id";
      Reference reference = FirebaseStorage.instance.ref().child(
          "identity_verification/$imageType/${DateTime.now().microsecondsSinceEpoch}.png");

      await reference.putFile(image).whenComplete(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            content: Text("Image Uploaded Successfully"),
          ),
        );
      });

      String downloadUrl = await reference.getDownloadURL();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          if (isFace)
            'faceImageUrl': downloadUrl
          else
            'idImageUrl': downloadUrl,
        });

        setState(() {
          if (isFace) {
            faceImageUrl = downloadUrl;
          } else {
            idImageUrl = downloadUrl;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> submitVerification() async {
    if (faceImageUrl != null && idImageUrl != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'faceImageUrl': faceImageUrl,
            'idImageUrl': idImageUrl,
            'isFullyVerified': false,
            'submittedAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text("Verification submitted successfully."),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error submitting verification: $e"),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content:
              Text("Please upload both face and ID images before submitting."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Your Identity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload the required images to verify your identity.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Face Image Upload Button
                ElevatedButton.icon(
                  onPressed: () => pickImage(isFace: true),
                  icon: const Icon(Icons.person),
                  label: const Text("Upload Face Image"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // ID Image Upload Button
                ElevatedButton.icon(
                  onPressed: () => pickImage(isFace: false),
                  icon: const Icon(Icons.perm_identity),
                  label: const Text("Upload ID Image"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Display Face Image
              if (faceImageUrl != null) ...[
                const Text(
                  "Face Image Uploaded:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    faceImageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Display ID Image
              if (idImageUrl != null) ...[
                const Text(
                  "ID Image Uploaded:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    idImageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: submitVerification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  "Submit Verification",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Verification Status
              if (_isVerified)
                const Center(
                  child: Text(
                    "Your account is verified!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Center(
                  child: Text(
                    "Your account is not verified yet.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
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
