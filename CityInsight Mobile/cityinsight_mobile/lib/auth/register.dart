import 'package:cityinsight_mobile/auth/login.dart';
import 'package:cityinsight_mobile/auth/verifye_email.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:quickalert/quickalert.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool showPassword = true;

  final formKey = GlobalKey<FormState>();
  var fn = TextEditingController();
  var ln = TextEditingController();
  var email = TextEditingController();
  var address = TextEditingController();
  var contactno = TextEditingController();
  var password = TextEditingController();
  var cpass = TextEditingController();

  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Register',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        ' as User',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Gap(12),
                  const Text(
                    'Please enter the needed information.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(20),
                  TextFormField(
                    controller: fn,
                    decoration: setTextDecoration('First Name', Icons.person),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required.';
                      }
                      return null;
                    },
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: ln,
                    decoration: setTextDecoration('Last Name', Icons.person),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: email,
                    decoration: setTextDecoration('Email Address', Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required.';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: address,
                    decoration: setTextDecoration('Address', Icons.home),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required.';
                      }
                      return null;
                    },
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: contactno,
                    decoration:
                        setTextDecoration('Contact Number', Icons.phone),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Required";
                      }
                      return null;
                    },
                  ),
                  const Gap(12),
                  TextFormField(
                    obscureText: showPassword,
                    controller: password,
                    decoration: setTextDecoration('Password', Icons.lock,
                        isPassword: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required.';
                      }
                      return null;
                    },
                  ),
                  const Gap(12),
                  TextFormField(
                    obscureText: showPassword,
                    controller: cpass,
                    decoration: setTextDecoration(
                        'Confirm Password', Icons.lock,
                        isPassword: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required.';
                      }
                      if (password.text != value) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),
                  ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Gap(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration setTextDecoration(String name, IconData icon,
      {bool isPassword = false}) {
    return InputDecoration(
      border: const OutlineInputBorder(),
      label: Text(name),
      filled: true,
      fillColor: Colors.grey[200],
      prefixIcon: Icon(icon),
      suffixIcon: isPassword
          ? IconButton(
              onPressed: toggleShowPassword,
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
              ),
            )
          : null,
    );
  }

  void register() {
    // * validate
    if (!formKey.currentState!.validate()) {
      return;
    }
    // * confirm to the user
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      // ? text: 'sample',
      title: 'Are you sure?',
      confirmBtnText: 'YES',
      cancelBtnText: 'No',
      onConfirmBtnTap: () {
        // * register in firebase auth
        Navigator.of(context).pop();
        registerUser();
      },
    );
  }

  void registerUser() async {
    try {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.loading,
        title: 'Loading',
        text: 'Registering your account',
      );
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email.text, password: password.text);

      // * Get the UID of the registered user
      String userId = userCredential.user!.uid;

      // * Firestore add document
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'uid': userId, // Add the user's UID
        'firstname': fn.text,
        'lastname': ln.text,
        'address': address.text,
        'contact': contactno.text,
        'email': email.text,
        'created_at': FieldValue.serverTimestamp(),
      });

      // * Send email verification
      await userCredential.user!.sendEmailVerification();

      Navigator.of(context).pop();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const VerifyEmailScreen(),
        ),
      );
    } on FirebaseAuthException catch (ex) {
      Navigator.of(context).pop();
      var errorTitle = '';
      var errorText = '';
      if (ex.code == 'weak-password') {
        errorText = 'Please enter a password with more than 6 characters';
        errorTitle = 'Weak Password';
      } else if (ex.code == 'email-already-in-use') {
        errorText = 'Email is already registered';
        errorTitle = 'Please enter a new email.';
      }

      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: errorTitle,
        text: errorText,
      );
    }
  }
}
