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

      if (!mounted) return;

      // Başarılı kayıt bildirimi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 20),
              Text("Kayıt Başarılı!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Ana ekrana yönlendiriliyorsunuz...", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );

      // 2 saniye sonra dialogu kapat ve ana ekrana yönlendir
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context); // Dialogu kapat
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false); // Ana ekrana yönlendir
        }
      });
    } catch (e) {
      _showSnackBar('Hata oluştu: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green),
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: "", // Karakter sayacını gizle
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Kayıt Ol", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Aramıza Katılın',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hızlıca hesabınızı oluşturun',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Ad',
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? 'Ad gerekli.' : null,
                    ),
                    _buildTextField(
                      controller: _surnameController,
                      label: 'Soyad',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Soyad gerekli.' : null,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'E-posta',
                      icon: Icons.email,
                      errorText: _emailErrorText,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'E-posta gerekli.';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) return 'Geçerli bir e-posta giriniz.';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Telefon Numarası',
                      icon: Icons.phone,
                      errorText: _phoneErrorText,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Telefon numarası gerekli.';
                        if (!value.startsWith('0')) return 'Telefon 0 ile başlamalı.';
                        if (value.length != 11) return 'Telefon 11 haneli olmalı.';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _birthYearController,
                      label: 'Doğum Yılı',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Doğum yılı gerekli.';
                        final year = int.tryParse(value);
                        if (year == null || year < 1900 || year > DateTime.now().year)
                          return 'Geçerli bir doğum yılı giriniz.';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Şifre',
                      icon: Icons.lock,
                      isObscure: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Şifre gerekli.';
                        if (value.length < 6) return 'Şifre en az 6 karakter olmalı.';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          shadowColor: Colors.green.withOpacity(0.4),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Kayıt Ol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Zaten hesabınız var mı? ',
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(text: 'Giriş Yapın', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}