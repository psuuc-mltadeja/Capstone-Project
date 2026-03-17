import 'package:cityinsight_mobile/components/bottomnav.dart';
import 'package:cityinsight_mobile/screens/barangay.dart';
import 'package:cityinsight_mobile/screens/homescreen.dart';
import 'package:cityinsight_mobile/screens/crowdsourcing.dart';
import 'package:cityinsight_mobile/screens/settings.dart';
import 'package:cityinsight_mobile/screens/sos.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends StatefulWidget {
  final String userId;

  const MainScreen({super.key, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<bool> checkServicePermission() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location Service is Disabled")));
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Location Permission is Denied. Please allow the permission to use the app.")));
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Location Permission is permanently denied. Please change it in settings.")));
      return false;
    }

    // SMS Permission
    if (await Permission.sms.request().isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            "SMS Permission is Denied. Please allow the permission to send SMS."),
      ));
      return false;
    }

    // Call Permission
    if (await Permission.phone.request().isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            "Call Permission is Denied. Please allow the permission to make calls."),
      ));
      return false;
    }

    return true;
  }

  int _selectedIndex = 2;
  String _currentMap = '';
  ThemeMode _themeMode = ThemeMode.system;

  // Function to toggle theme mode
  void toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _onScreenTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateMap(String mapType) {
    setState(() {
      _currentMap = mapType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            Barangay(
              userId: widget.userId,
              isDarkMode: _themeMode == ThemeMode.dark,
              onToggleTheme: toggleTheme,
            ),
            const CrowdSourcing(),
            HomeScreen(
              userId: widget.userId,
              currentMap: _currentMap,
              onMapChange: _updateMap,
            ),
            SosScreen(
              checkServicePermission: checkServicePermission,
              userId: widget.userId,
            ),
            SettingScreen(
              onToggleTheme: toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
              currentMapStyle: _currentMap,
              onMapStyleChange: _updateMap,
            ),
          ],
        ),
        bottomNavigationBar: NavBar(
          selectedIndex: _selectedIndex,
          onTap: _onScreenTapped,
          backgroundColor: _selectedIndex == 3 ? Colors.red : Colors.blue,
        ),
      ),
    );
  }
}
