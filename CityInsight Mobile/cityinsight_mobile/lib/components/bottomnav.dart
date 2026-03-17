import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.backgroundColor, // Add a backgroundColor parameter
  });

  final int selectedIndex;
  final Function(int) onTap;
  final Color backgroundColor; // New field for background color

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: backgroundColor, // Use the passed background color
      height: 60,
      index: selectedIndex,
      items: const <Widget>[
        Icon(
          Icons.maps_home_work,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.newspaper_outlined,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.home,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.sos_sharp,
          size: 30,
          color: Colors.white,
        ),
        Icon(
          Icons.settings,
          size: 30,
          color: Colors.white,
        ),
      ],
      onTap: onTap,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      letIndexChange: (index) => true,
    );
  }
}
