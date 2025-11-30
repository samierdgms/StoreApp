import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // DotEnv paketini ekledik

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _emailController = TextEditingController();

  // URL ve Key'i artık buradan sabit vermiyoruz, aşağıda fonksiyonda çağıracağız.

  String? _emailErrorText;
  String? _message;
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // 1. .env dosyasından verileri çekiyoruz
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    // Güvenlik kontrolü: Eğer .env okunamazsa hata verelim
    if (supabaseUrl == null || supabaseAnonKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hata: .env dosyasından Supabase bilgileri okunamadı!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _emailErrorText = null;
      _message = null;
      _isLoading = true;
    });

    if (email.isEmpty) {
      setState(() {
        _emailErrorText = 'E-posta gerekli.';
        _isLoading = false;
      });
      return;
    }

    try {
      // 2. HTTP İsteğini .env'den gelen verilerle yapıyoruz
      final url = Uri.parse('$supabaseUrl/auth/v1/recover');

      final response = await http.post(
        url,
        headers: {
          'apikey': supabaseAnonKey, // Key buradan geliyor
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          // HTML sayfanın linki (Burası sabit kalabilir veya bunu da env'e koyabilirsin)
          'redirect_to': 'https://samierd.dev/reset-password/',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = 'Şifre sıfırlama bağlantısı gönderildi. Lütfen e-postanızı (ve spam klasörünü) kontrol edin.';
        });
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['msg'] ?? 'Bilinmeyen hata: ${response.body}');
      }

    } catch (e) {
      print("Hata Detayı: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hata: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Şifre Sıfırlama', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    "Şifrenizi Sıfırlayın",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Kayıtlı E-posta Adresi',
                      errorText: _emailErrorText,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Şifre Sıfırlama Bağlantısı Gönder', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_message != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        _message!,
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Giriş Ekranına Dön', style: TextStyle(color: Colors.grey)),
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