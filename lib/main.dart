import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Providerlar
import 'providers/cart_provider.dart';
import 'providers/market_provider.dart';

// Ekranlar
import 'screens/home_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_profile_screen.dart';
import 'screens/market_selection_screen.dart';
import 'user_profile/user_profile_screen.dart';

// Servisler
import 'services/maintenance_service.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart'; // ✅ 1. EKLENDİ: Update servisi import edildi

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ✅ 2. EKLENDİ: Navigator Key (Dialog gösterebilmek için gerekli)
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _isSplashFinished = false;

  // Uygulama Durumları
  bool _isMaintenanceMode = false;
  bool _isSuperAdmin = false;
  bool _isMarketOwner = false;

  final _supabaseClient = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final maintenanceStatus = await MaintenanceService.isMaintenanceActive();
      final superAdminIdFromDb = await MaintenanceService.getSuperAdminId();

      final user = _supabaseClient.auth.currentUser;
      bool superAdminStatus = false;
      bool marketOwnerStatus = false;

      if (user != null) {
        NotificationService.initialize();

        if (superAdminIdFromDb != null && user.id == superAdminIdFromDb) {
          superAdminStatus = true;
          debugPrint("👑 Süper Admin Girişi Algılandı!");
        }

        final ownerDoc = await _supabaseClient
            .from('market_owners')
            .select('market_id, markets(name)')
            .eq('user_id', user.id)
            .maybeSingle();

        if (ownerDoc != null) {
          marketOwnerStatus = true;
          _setupMarketProvider(
              ownerDoc['market_id'],
              ownerDoc['markets']?['name'] ?? 'Yönetim Paneli'
          );
        }
      }

      if (mounted) {
        setState(() {
          _isMaintenanceMode = maintenanceStatus;
          _isSuperAdmin = superAdminStatus;
          _isMarketOwner = marketOwnerStatus;
        });

        // ✅ 3. EKLENDİ: GÜNCELLEME KONTROLÜ
        // Veriler çekildikten hemen sonra versiyon kontrolü yapıyoruz.
        // NavigatorKey kullanarak context'e güvenli erişim sağlıyoruz.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigatorKey.currentContext != null) {
            UpdateService.checkAndUpdate(_navigatorKey.currentContext!);
          }
        });
      }

    } catch (e) {
      debugPrint('Başlangıç hatası: $e');
    }
  }

  void _setupMarketProvider(String marketId, String marketName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MarketProvider>(context, listen: false)
            .setMarket(marketId, marketName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market Uygulaması',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey, // ✅ 4. EKLENDİ: Key'i MaterialApp'a atadık
      scaffoldMessengerKey: NotificationService.messengerKey,
      theme: ThemeData(primarySwatch: Colors.green),
      routes: {
        '/userProfile': (context) => UserProfileScreen(),
        '/adminProfile': (context) => const AdminProfileScreen(),
        '/register': (context) => RegistrationScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/selectMarket': (context) => const MarketSelectionScreen(),
      },
      home: _isSplashFinished
          ? _getInitialScreen()
          : SplashScreen(
        onFinished: () {
          setState(() {
            _isSplashFinished = true;
          });
        },
      ),
    );
  }

  Widget _getInitialScreen() {
    if (_isMaintenanceMode && !_isSuperAdmin) {
      return const MaintenanceScreen();
    }
    if (_isMarketOwner) {
      return const AdminProfileScreen();
    }
    return const MarketSelectionScreen();
  }
}