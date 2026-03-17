import 'package:cityinsight_mobile/screens/profile.dart';
import 'package:cityinsight_mobile/screens/report_incidents.dart';
import 'package:cityinsight_mobile/screens/verify_identity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';

class SosScreen extends StatefulWidget {
  const SosScreen(
      {super.key, required this.userId, required this.checkServicePermission});
  final userId;
  final Future<bool> Function() checkServicePermission;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
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

  // * call function
  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $phoneUri');
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }

  // * text function
  Future<void> sendSMS(String phoneNumber, String message) async {
    final String smsUrl =
        'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
    try {
      if (await canLaunchUrlString(smsUrl)) {
        await launchUrlString(smsUrl);
      } else {
        print('Could not launch $smsUrl');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }

  // * SOS function placeholder
  Future<void> sendSOS() async {
    if (!await widget.checkServicePermission()) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    await FirebaseFirestore.instance.collection('sosreqs').add({
      'userId': widget.userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // * emergency number
    const emergencyNumber = '+639566583530';

    // * emergency message
    String message =
        'SOS! My current location is: https://maps.google.com/?q=${position.latitude},${position.longitude}';

    await sendSMS(emergencyNumber, message);
    await makePhoneCall(emergencyNumber);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS sent! Your location has been shared.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOS Alert',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isVerified
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image at the top
                  Image.asset(
                    'assets/images/sos.png', // Replace with your image path
                    width: 100, // Adjust width as needed
                    height: 100, // Adjust height as needed
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Emergency SOS Alert',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'If you are in danger, press the button below to send an SOS alert to your emergency contacts and share your current location.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      // Call the sendSOS function to send the SOS request to Firebase and make the call/SMS
                      await sendSOS();

                      // Show the dialog only after the SOS request is successfully sent
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('SOS Alert Sent'),
                          content: const Text(
                              'Your SOS alert has been sent successfully! Help is on the way.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Send SOS',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const Gap(10),
                  ElevatedButton(
                    onPressed: () async {
                      const emergencyNumber = '+639566583530';
                      final Uri url = Uri(
                        scheme: 'sms',
                        path: emergencyNumber,
                      );

                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        print('show dialog: cannot launch this url');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Send Help Message to Police',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "You are not verified. Please verify your identity.",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const VerifyIdentityScreen(),
                          ));
                        },
                        child: const Text("Verify"))
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          if (_isVerified) {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (context) => const ReportIncidentScreen(),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text("You are not verified. Please verify your identity."),
            ));
          }
        },
        heroTag: "UniqueTag2",
        child: const Icon(
          Icons.report_gmailerrorred_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}
