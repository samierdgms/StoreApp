import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registration_screen.dart'; // Kayıt ekranı import edilecek
import 'help_screen.dart'; // Yardım ekranı import edilecek

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

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    if (email.isEmpty) {
      setState(() {
        _emailErrorText = 'E-posta gerekli.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordErrorText = 'Şifre gerekli.';
      });
      return;
    }

    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.error != null) {
        // Hata durumunda kullanıcıya bildirim
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Giriş başarısız: ${response.error?.message}'),
        ));
        return;
      }

      // Başarılı giriş
      final user = response.user;
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hoş geldiniz, ${user.email}'),
        ));
        Navigator.pushReplacementNamed(context, '/home'); // Burayı güncelledik
      }
    } catch (e) {
      // Hata durumunda kullanıcıyı bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: ${e.toString()}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Giriş Yap")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // E-posta input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-posta',
                errorText: _emailErrorText,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            // Şifre input
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Şifre',
                errorText: _passwordErrorText,
              ),
            ),
            SizedBox(height: 20),
            // Giriş butonu
            ElevatedButton(
              onPressed: _login,
              child: Text('Giriş Yap'),
            ),
            SizedBox(height: 20),
            // Kayıt ol butonu
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text('Hesabınız yok mu? Kayıt ol'),
            ),
            SizedBox(height: 20),
            // Yardım butonu
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpScreen()),
                );
              },
              child: Text('Yardım al'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on AuthResponse {
  get error => null;
}
