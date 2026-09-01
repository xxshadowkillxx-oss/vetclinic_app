import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/mascotas_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final loggedIn = await ApiService.isLoggedIn();
  runApp(VetClinicApp(loggedIn: loggedIn));
}

class VetClinicApp extends StatelessWidget {
  final bool loggedIn;
  const VetClinicApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetClinic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: loggedIn ? const MascotasScreen() : const LoginScreen(),
    );
  }
}
