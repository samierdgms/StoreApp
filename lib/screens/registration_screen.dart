import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthYearController = TextEditingController();

  final _client = Supabase.instance.client;

  bool _isSubmitting = false;

  String? _emailErrorText;
  String? _phoneErrorText;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final password = _passwordController.text.trim();
    final birthYear = int.tryParse(_birthYearController.text.trim());

    setState(() => _isSubmitting = true);

    try {
      // Kullanıcı zaten kayıtlı mı?
      final existingUsers = await _client
          .from('users')
          .select()
          .or('email.eq.$email,phone_number.eq.$phoneNumber');

      _emailErrorText = null;
      _phoneErrorText = null;

      for (final user in existingUsers) {
        if (user['email'] == email) _emailErrorText = 'Bu e-posta zaten kayıtlı.';
        if (user['phone_number'] == phoneNumber) _phoneErrorText = 'Bu numara zaten kayıtlı.';
      }

      if (_emailErrorText != null || _phoneErrorText != null) {
        setState(() {}); // UI'yi güncelle
        _isSubmitting = false;
        return;
      }

      final authRes = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final userId = authRes.user?.id;
      if (userId == null) {
        _showSnackBar('Kayıt başarısız oldu.');
        setState(() => _isSubmitting = false);
        return;
      }

      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'phone_number': phoneNumber,
        'name': name,
        'surname': surname,
        'birth_year': birthYear,
      });

      // Başarılı kayıt bildirimi
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Kayıt Başarılı'),
            ],
          ),
          content: Text('Ana ekrana yönlendiriliyorsunuz...'),
        ),
      );

      // 2 saniye sonra dialogu kapat ve ana ekrana yönlendir
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context); // Dialogu kapat
        Navigator.pushReplacementNamed(context, '/home'); // Ana ekrana yönlendir
      });
    } catch (e) {
      _showSnackBar('Hata oluştu: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kayıt Ol")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Aramıza katılmanıza sevindik!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Color(0xFFFFC067)),
                  ),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    errorText: _emailErrorText,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'E-posta gerekli.';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return 'Geçerli bir e-posta giriniz.';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Telefon Numarası',
                    errorText: _phoneErrorText,
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Telefon numarası gerekli.';
                    if (!value.startsWith('0')) return 'Telefon 0 ile başlamalı.';
                    if (value.length != 11) return 'Telefon 11 haneli olmalı.';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Ad'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Ad gerekli.' : null,
                ),
                TextFormField(
                  controller: _surnameController,
                  decoration: InputDecoration(labelText: 'Soyad'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Soyad gerekli.' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  maxLength: 8,
                  decoration: InputDecoration(labelText: 'Şifre (8 karakter)'),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Şifre gerekli.';
                    if (value.length < 8)
                      return 'Şifre en az 8 karakter olmalı.';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _birthYearController,
                  decoration: InputDecoration(labelText: 'Doğum Yılı'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Doğum yılı gerekli.';
                    final year = int.tryParse(value);
                    if (year == null || year < 1900 || year > DateTime.now().year)
                      return 'Geçerli bir doğum yılı giriniz.';
                    return null;
                  },
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _register,
                    child: Text(_isSubmitting ? 'Kaydediliyor...' : 'Kayıt Ol'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Zaten hesabınız var mı? Giriş yapın'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
