import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        title: const Text(
          "Emergency Contacts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CDRRMO Contact Number",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Card(
              child: ListTile(
                title: const Text(
                  "0917-818-5374",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    IconButton(
                        onPressed: () async {
                          const emergencyNumber = '+639178185347';
                          final Uri url = Uri(
                            scheme: 'tel',
                            path: emergencyNumber,
                          );

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            print('show dialog: cannot launch this url');
                          }
                        },
                        icon: const FaIcon(FontAwesomeIcons.phone)),
                    const Divider(),
                    IconButton(
                        onPressed: () async {
                          const emergencyNumber = '+639178185347';
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
                        icon: const FaIcon(FontAwesomeIcons.sms)),
                  ],
                ),
              ),
            ),
            const Gap(20),
            const Text(
              "Bureau of Fire Protection Contact Number",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Card(
              child: ListTile(
                title: const Text(
                  "0917-184-4611",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    IconButton(
                        onPressed: () async {
                          const emergencyNumber = '+639171844611';
                          final Uri url = Uri(
                            scheme: 'tel',
                            path: emergencyNumber,
                          );

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            print('show dialog: cannot launch this url');
                          }
                        },
                        icon: const FaIcon(FontAwesomeIcons.phone)),
                    const Divider(),
                    IconButton(
                        onPressed: () async {
                          const emergencyNumber = '+639171844611';
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
                        icon: const FaIcon(FontAwesomeIcons.sms)),
                  ],
                ),
              ),
            ),
            const Gap(20),
            const Text(
              "PNP Contact Number",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Card(
              child: ListTile(
                title: const Text(
                  "0916-226-3641",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    IconButton(
                        onPressed: () async {
                          const emergencyNumber = '+639162263641';
                          final Uri url = Uri(
                            scheme: 'tel',
                            path: emergencyNumber,
                          );

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            print('show dialog: cannot launch this url');
                          }
                        },
                        icon: const FaIcon(FontAwesomeIcons.phone)),
                    const Divider(),
                    IconButton(
                        onPressed: () async {
                          const emergencyNumber = '+639162263641';
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
                        icon: const FaIcon(FontAwesomeIcons.sms)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
