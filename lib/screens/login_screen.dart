import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';
import 'registration_screen.dart';
import 'help_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseClient = Supabase.instance.client;

  String? _emailErrorText;
  String? _passwordErrorText;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
      _isLoading = true;
    });

    if (email.isEmpty) {
      setState(() {
        _emailErrorText = 'E-posta gerekli.';
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordErrorText = 'Şifre gerekli.';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Giriş Yap
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {

        // 2. Market Sahibi Kontrolü (Admin mi?)
        final ownerResponse = await _supabaseClient
            .from('market_owners')
            .select('market_id, markets(name)')
            .eq('user_id', user.id)
            .maybeSingle();

        if (ownerResponse != null) {
          // ✅ EVET, BU BİR MARKET SAHİBİ!
          final String ownerMarketId = ownerResponse['market_id'];
          final String ownerMarketName = ownerResponse['markets']['name'];

          // Uygulamanın marketini zorla bu market yap
          if (mounted) {
            Provider.of<MarketProvider>(context, listen: false)
                .setMarket(ownerMarketId, ownerMarketName);

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Yönetici Girişi: $ownerMarketName'),
              backgroundColor: Colors.green,
            ));

            // Admin Paneline Gönder
            Navigator.pushReplacementNamed(context, '/adminProfile');
          }
        } else {
          // ❌ HAYIR, NORMAL MÜŞTERİ
          final currentMarketId = Provider.of<MarketProvider>(context, listen: false).marketId;

          if (mounted) {
            if (currentMarketId == null) {
              Navigator.pushReplacementNamed(context, '/selectMarket');
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Giriş başarısız: ${e.message}'),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Hafif arka plan
      appBar: AppBar(
        title: const Text("Giriş Yap", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Hesabınıza Giriş Yapın",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 30),

                  // E-posta input
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      errorText: _emailErrorText,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Şifre input
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      errorText: _passwordErrorText,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Giriş butonu
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kayıt ol butonu
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()),
                      );
                    },
                    child: const Text('Hesabınız yok mu? Kayıt olun', style: TextStyle(color: Colors.blue)),
                  ),

                  // Yardım butonu
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpScreen()),
                      );
                    },
                    child: const Text('Şifremi unuttum / Yardım al', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}