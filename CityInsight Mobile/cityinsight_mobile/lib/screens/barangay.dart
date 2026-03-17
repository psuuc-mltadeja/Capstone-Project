import 'package:cityinsight_mobile/screens/brgy-details.dart';
import 'package:cityinsight_mobile/screens/crime_charts.dart';
import 'package:cityinsight_mobile/screens/floodmaps.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Barangay extends StatefulWidget {
  const Barangay(
      {super.key,
      required this.userId,
      required this.isDarkMode,
      required this.onToggleTheme});
  final String userId;
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  @override
  State<Barangay> createState() => _BarangayState();
}

class _BarangayState extends State<Barangay>
    with SingleTickerProviderStateMixin {
  String query = '';
  String? _selectedCollection; // For selected collection ('crimes' or 'floods')

  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Set default collection to 'crimes'
    _selectedCollection = 'crimes';

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define the opacity animation
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start the animation to ensure it plays when the widget is first built
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller
    super.dispose();
  }

  void fetchMarkers() {
    // Implement fetching logic here
  }

  @override
  Widget build(BuildContext context) {
    // final bgColor = widget.isDarkMode ? Colors.black : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Information List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CrimeCharts(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const FloodMaps(),
              ));
            },
            icon: const Icon(Icons.map),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Overall padding for body
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
              ),
              child: TextField(
                onChanged: (value) => setState(() {
                  query = value.toLowerCase();
                }),
                decoration: InputDecoration(
                  hintText:
                      "Search ${_selectedCollection?.toLowerCase() ?? 'items'}",
                  hintStyle: TextStyle(color: textColor),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: textColor),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            const Gap(10),
            // Toggle Buttons for selecting collections
            ToggleButtons(
              isSelected: [
                _selectedCollection == 'crimes',
                _selectedCollection == 'floods',
                _selectedCollection == 'barangays', // Updated to 'barangays'
              ],
              onPressed: (int index) {
                setState(() {
                  if (index == 0) {
                    _selectedCollection = 'crimes';
                  } else if (index == 1) {
                    _selectedCollection = 'floods';
                  } else {
                    _selectedCollection = 'barangays'; // Updated to 'barangays'
                  }
                  // Fetch markers based on the updated selection
                  fetchMarkers();
                });
              },
              borderRadius: BorderRadius.circular(20),
              selectedColor: Colors.white,
              fillColor: widget.isDarkMode ? Colors.grey[700] : Colors.blue,
              color: textColor,
              constraints: BoxConstraints(
                minHeight: 40.0,
                minWidth: (MediaQuery.of(context).size.width - 48) / 3,
              ),
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel, size: 18),
                    SizedBox(width: 5),
                    Text("Crimes"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flood_outlined, size: 18),
                    SizedBox(width: 5),
                    Text("Floods"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_city, size: 18), // Icon for barangays
                    SizedBox(width: 5),
                    Text("Barangays"),
                  ],
                ),
              ],
            ),
            const Gap(10),
            // Expanded list of items
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(_selectedCollection?.toLowerCase() ??
                        'crimes') // Default to 'crimes'
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No Items Found"));
                  }

                  final items = snapshot.data!.docs;

                  // Filter items based on the query
                  final filteredItems = query.isEmpty
                      ? items
                      : items.where((item) {
                          final itemData = item.data() as Map<String, dynamic>;
                          String? itemName;

                          // Use the appropriate field based on the selected category
                          if (_selectedCollection?.toLowerCase() ==
                              'barangays') {
                            itemName =
                                itemData['name']?.toString().toLowerCase();
                          } else {
                            itemName =
                                itemData['type']?.toString().toLowerCase();
                          }

                          return itemName != null &&
                              itemName.contains(
                                  query); // Ensure itemName is not null
                        }).toList();

                  // Sort items based on their names or types alphabetically
                  filteredItems.sort((a, b) {
                    final nameA = (a.data() as Map<String, dynamic>)[
                                _selectedCollection?.toLowerCase() ==
                                        'barangays'
                                    ? 'name'
                                    : 'type']
                            ?.toString()
                            .toLowerCase() ??
                        ''; // Handle null
                    final nameB = (b.data() as Map<String, dynamic>)[
                                _selectedCollection?.toLowerCase() ==
                                        'barangays'
                                    ? 'name'
                                    : 'type']
                            ?.toString()
                            .toLowerCase() ??
                        ''; // Handle null
                    return nameA.compareTo(nameB); // Sort alphabetically
                  });

                  return FadeTransition(
                    opacity: _opacityAnimation,
                    child: SingleChildScrollView(
                      child: Column(
                        children: filteredItems.map((item) {
                          final itemData = item.data() as Map<String, dynamic>;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 5), // Margin for cards
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Rounded corners
                              ),
                              child: ListTile(
                                title: Text(
                                  _selectedCollection?.toLowerCase() ==
                                          'barangays'
                                      ? itemData['name'] ??
                                          'Unnamed' // Display 'name' for barangays
                                      : itemData['type'] ??
                                          'Unnamed', // Display 'type' for crimes and floods
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: _selectedCollection?.toLowerCase() !=
                                        'barangays'
                                    ? Text(
                                        "Location: \n  ${itemData['latitude'] ?? 'No Latitude'}, ${itemData['longitude'] ?? 'No Longitude'}",
                                        style: TextStyle(color: textColor),
                                      )
                                    : null,
                                onTap: () => itemDetails(itemData),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void itemDetails(Map<String, dynamic> itemData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (_selectedCollection?.toLowerCase() == 'barangays') {
            return BarangayDetails(brgyData: itemData);
          }
          // Add detail pages for crimes and floods here if applicable
          return Container(); // Placeholder for other categories
        },
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}
