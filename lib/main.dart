import 'package:flutter/material.dart';
import 'core/app_controller.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'widgets/ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KhalidNetworksStaffApp());
}

class KhalidNetworksStaffApp extends StatefulWidget {
  const KhalidNetworksStaffApp({super.key});
  @override
  State<KhalidNetworksStaffApp> createState() => _KhalidNetworksStaffAppState();
}

class _KhalidNetworksStaffAppState extends State<KhalidNetworksStaffApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController()..addListener(_refresh);
    controller.initialize();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Khalid Networks Staff',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
          primary: blue,
          secondary: purple,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 70,
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFEAF1FF),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ),
      home: controller.booting
          ? const _SplashScreen()
          : controller.signedIn
              ? HomeShell(controller: controller)
              : LoginScreen(controller: controller),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F8FF), Color(0xFFF6F3FF), Color(0xFFEAFBF4)],
          ),
        ),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('assets/khalid-networks-logo.png', width: 260),
            const SizedBox(height: 26),
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            const Text('Preparing staff workspace…', style: TextStyle(color: Color(0xFF71809B), fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
