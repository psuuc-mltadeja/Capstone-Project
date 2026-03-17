import 'package:cityinsight_mobile/screens/mainscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.verificationId});
  final String verificationId;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController codeC = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Image.asset("assets/images/otp.jpg"),
            const Text(
              "OTP Verification",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "We need to register your phone using OTP Code.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: codeC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Code",
                ),
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
                      try {
                        final credential = PhoneAuthProvider.credential(
                          verificationId: widget.verificationId,
                          smsCode: codeC.text,
                        );
                        UserCredential userCredential = await FirebaseAuth
                            .instance
                            .signInWithCredential(credential);
                        String userId = userCredential.user!.uid;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MainScreen(userId: userId),
                          ),
                        );
                      } catch (err) {
                        print(err);
                      }
                      setState(() {
                        isLoading = false;
                      });
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
  }
}
