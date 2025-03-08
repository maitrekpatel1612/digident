// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/camera_view_screen.dart';
import 'screens/wifi_connection_screen.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app config
  await AppConfig().init();
  
  // Set initial system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final bool _skipWifiScreen = false; // Set to true to skip WiFi screen during development

  @override
  void initState() {
    super.initState();
    // Request permissions at app startup
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request storage permission silently at startup
    await Permission.storage.request();
    // Request location permission (needed for WiFi scanning)
    await Permission.location.request();
  }

  void toggleTheme() {
    // This function is kept for compatibility but does nothing now
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digident Camera',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 8,
          shadowColor: Colors.blue.withAlpha(128),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      home: _skipWifiScreen 
          ? CameraViewScreen(toggleTheme: toggleTheme)
          : WiFiConnectionScreen(toggleTheme: toggleTheme),
    );
  }
}
