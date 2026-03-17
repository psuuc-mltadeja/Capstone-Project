import 'package:cityinsight_mobile/screens/barangay.dart';
import 'package:cityinsight_mobile/screens/homescreen.dart';
import 'package:cityinsight_mobile/screens/crowdsourcing.dart';
import 'package:cityinsight_mobile/screens/settings.dart';
import 'package:cityinsight_mobile/screens/splash-screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CityInsight());
}

final navigationKey = GlobalKey<NavigatorState>();

class CityInsight extends StatefulWidget {
  const CityInsight({super.key});

  @override
  State<CityInsight> createState() => _CityInsightState();
}

class _CityInsightState extends State<CityInsight> {
  ThemeMode _themeMode = ThemeMode.system;
  String _mapStyle = 'Standard';

  void toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void changeMapStyle(String newStyle) {
    setState(() {
      _mapStyle = newStyle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/home': (context) => HomeScreen(
              userId: ModalRoute.of(context)!.settings.arguments as String,
              currentMap: ModalRoute.of(context)!.settings.arguments as String,
              onMapChange:
                  ModalRoute.of(context)!.settings.arguments as dynamic,
            ),
        '/barangay': (context) => Barangay(
              userId: ModalRoute.of(context)!.settings.arguments as String,
              isDarkMode: _themeMode == ThemeMode.dark,
              onToggleTheme: toggleTheme,
            ),
        '/crowdsourcing': (context) => const CrowdSourcing(),
        '/settings': (context) => SettingScreen(
              onToggleTheme: toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
              currentMapStyle: _mapStyle,
              onMapStyleChange: changeMapStyle,
            ),
      },
      builder: EasyLoading.init(),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.lato().fontFamily,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w100,
          ),
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
    );
  }
}
