import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Animated logo with fade-in effect
              Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(
                            'assets/images/logo_aboutus.png'), // Replace with your logo
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Company Name and Tagline
              const Text(
                'Cityinsight Inc.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'Connecting People, Transforming Cities',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // About Us Section with Card
              const Card(
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Us',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'At Cityinsight Inc., we believe in creating solutions that bridge communities with smarter city planning '
                        'and innovative technologies. Our mission is to make urban life more efficient, sustainable, and inclusive.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Our Team Section with Icon
              const ListTile(
                leading: Icon(Icons.people, color: Colors.blue),
                title: Text(
                  'Our Team',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Our diverse and talented team consists of urban planners, data scientists, software developers, and designers.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
              ),
              SizedBox(height: 20),

              // Contact Information with Interactive Elements
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.blue),
                        title: const Text('Email: info@cityinsight.com'),
                        onTap: () => _launchURL('mailto:info@cityinsight.com'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone, color: Colors.blue),
                        title: const Text('Phone: +123 456 7890'),
                        onTap: () => _launchURL('tel:+1234567890'),
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.location_on, color: Colors.blue),
                        title: const Text(
                            'Address: 123 Urban St., Smart City, CA'),
                        onTap: () => _launchURL(
                            'https://www.google.com/maps/search/?api=1&query=123+Urban+St.+Smart+City+CA'), // Opens Google Maps
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Social Media Links (Optional, for further interactivity)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.facebook, color: Colors.blue),
                    onPressed: () => _launchURL('https://www.facebook.com'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.linked_camera, color: Colors.blue),
                    onPressed: () => _launchURL('https://www.instagram.com'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.web, color: Colors.blue),
                    onPressed: () => _launchURL('https://www.cityinsight.com'),
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
