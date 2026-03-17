import 'package:cityinsight_mobile/auth/otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';

class PhoneAuth extends StatefulWidget {
  const PhoneAuth({super.key});

  @override
  State<PhoneAuth> createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
  TextEditingController phoneC = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 10,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: () {
          showDialogBox(context);
        },
        child: const Row(
          children: [
            FaIcon(FontAwesomeIcons.phone),
            Gap(10),
            Text(
              "Sign in with Phone Number",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          ],
        ),
      ),
    );
  }

  void showDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    const Text(
                      "Phone Authentication",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Gap(20),
                TextField(
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "+6391211221",
                    labelText: "Enter your Phone Number",
                  ),
                ),
                const Gap(20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });
                          await FirebaseAuth.instance.verifyPhoneNumber(
                            phoneNumber: phoneC.text,
                            verificationCompleted: (phoneAuthCredential) {},
                            verificationFailed: (error) {
                              print(error);
                            },
                            codeSent: (verificationId, forceResendingToken) {
                              setState(() {
                                isLoading = false;
                              });
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => OTPScreen(
                                    verificationId: verificationId,
                                  ),
                                ),
                              );
                            },
                            codeAutoRetrievalTimeout: (verificationId) {},
                          );
                        },
                        child: const Text(
                          "Send Code",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
