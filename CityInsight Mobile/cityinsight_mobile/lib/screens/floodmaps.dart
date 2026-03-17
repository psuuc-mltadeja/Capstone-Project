import 'package:flutter/material.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';

class FloodMaps extends StatefulWidget {
  const FloodMaps({super.key});

  @override
  State<FloodMaps> createState() => _FloodMapsState();
}

class _FloodMapsState extends State<FloodMaps> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        title: const Text(
          "Flood Map",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Flood Map of Urdaneta City",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Center(
              child: Card(
                elevation: 15,
                child: InstaImageViewer(
                  backgroundIsTransparent: true,
                  child: Image.asset(
                    "assets/images/flood_map.jpg",
                    height: MediaQuery.of(context).size.height * 0.6,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
