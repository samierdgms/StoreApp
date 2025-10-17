import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storeappp/screens/admin_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/login_screen.dart';
import 'user_profile/user_profile_screen.dart';
import 'services/maintenance_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  // Supabase'ı başlatıyoruz.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Bakım modu durumunu kontrol ediyoruz.
  final isMaintenance = await MaintenanceService.isMaintenanceActive();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(isMaintenance: isMaintenance),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isMaintenance;
  const MyApp({super.key, required this.isMaintenance});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSplashFinished = false;
  final _supabaseClient = Supabase.instance.client;
  bool _isLoggedIn = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  // Kullanıcıyı kontrol ediyoruz ve admin olup olmadığını belirliyoruz.
  Future<void> _checkUserLoggedIn() async {
    final user = _supabaseClient.auth.currentUser;

    if (user != null) {
      setState(() {
        _isLoggedIn = true;
      });
      // Kullanıcı giriş yaptıysa, admin olup olmadığını kontrol edelim.
      final response = await _supabaseClient
          .from('users')  // users tablosu
          .select('is_admin')
          .eq('id', user.id)
          .single();
      if (response != null && response['is_admin'] == true) {
        setState(() {
          _isAdmin = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market Uygulaması',
      theme: ThemeData(primarySwatch: Colors.green),
      routes: {
        '/userProfile': (context) => UserProfileScreen(),
        '/adminProfile': (context) => AdminProfileScreen(),
        '/register': (context) => RegistrationScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
      home: _isSplashFinished
          ? (_isAdmin
          ? widget.isMaintenance
          ? const AdminProfileScreen()
          : const HomeScreen()
          : widget.isMaintenance
          ? const MaintenanceScreen()
          : const HomeScreen())
          : SplashScreen(
        onFinished: () {
          setState(() {
            _isSplashFinished = true;
          });
        },
      ),
    );
  }
}
