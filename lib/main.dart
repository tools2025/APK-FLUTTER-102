import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'screens/webview_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ATUR STATUS BAR DI SINI - DIPAKSA
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Transparan
    statusBarIconBrightness: Brightness.light, // Ikon PUTIH
    statusBarBrightness: Brightness.dark, // Mode gelap
    systemNavigationBarColor: Color(0xFF0F0A2A), // Nav bar gelap
    systemNavigationBarIconBrightness: Brightness.light, // Ikon nav PUTIH
  ));
  
  // Set orientasi
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // PAKSA PAKAI THEME DARK
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0A2A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0A2A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const WebViewScreen(),
    );
  }
}
