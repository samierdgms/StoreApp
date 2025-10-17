import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _emailController = TextEditingController();
  final _supabaseClient = Supabase.instance.client;
  String? _emailErrorText;
  String? _message;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailErrorText = null;
      _message = null;
    });

    if (email.isEmpty) {
      setState(() {
        _emailErrorText = 'E-posta gerekli.';
      });
      return;
    }

    try {
      // Şifre sıfırlama e-postası gönder
      final response = await _supabaseClient.auth.resetPasswordForEmail(email);



      setState(() {
        _message = 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: ${e.toString()}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yardım')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-posta adresinizi girin',
                errorText: _emailErrorText,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Şifreyi Sıfırla'),
            ),
            SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
