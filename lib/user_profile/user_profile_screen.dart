import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/order_history_screen.dart';
import '../screens/admin_profile_screen.dart';


class UserProfileScreen extends StatefulWidget {
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  // Yeni şifre için controller'lar
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _email;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    if (response != null) {

      if (response['is_admin'] == true) {

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) =>  AdminProfileScreen()),
          );
        }
        return;
      }

      setState(() {
        _nameController.text = response['name'] ?? '';
        _surnameController.text = response['surname'] ?? '';
        _phoneController.text = response['phone_number'] ?? '';
        _birthYearController.text = response['birth_year']?.toString() ?? '';
        _addressController.text = response['address_line'] ?? '';
        _cityController.text = response['city'] ?? '';
        _districtController.text = response['district'] ?? '';
        _email = response['email'];
        _loading = false;
      });
    }
  }

  // Profil güncelleme fonksiyonu
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('users').update({
      'name': _nameController.text,
      'surname': _surnameController.text,
      'phone_number': _phoneController.text,
      'address_line': _addressController.text,
    }).eq('id', user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bilgiler güncellendi')),
    );
  }

  // Şifre güncelleme fonksiyonu
  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifreler uyuşmuyor')),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Şifreyi güncelle
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifre güncelleme hatası: ${response.error?.message}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreniz başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
    }
  }

  // Çıkış yapma fonksiyonu
  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: _signOut,
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bilgilerim',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_email != null)
                        Text('E-posta: $_email', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Ad'),
                      ),
                      TextFormField(
                        controller: _surnameController,
                        decoration: const InputDecoration(labelText: 'Soyad'),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefon'),
                        keyboardType: TextInputType.phone,
                      ),
                      TextFormField(
                        controller: _birthYearController,
                        decoration: const InputDecoration(labelText: 'Doğum Yılı'),
                        readOnly: true,
                      ),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Şehir'),
                        readOnly: true,
                      ),
                      TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(labelText: 'İlçe'),
                        readOnly: true,
                      ),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Adres'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _updateProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Bilgileri Güncelle'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Şifre Güncelleme Alanı
                      const Text(
                        'Şifrenizi Güncelleyin',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                        obscureText: true,
                      ),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                        obscureText: true,
                      ),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _updatePassword,
                          icon: const Icon(Icons.lock),
                          label: const Text('Şifreyi Güncelle'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OrderHistoryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history),
                            label: const Text("Siparişlerim"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
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
      ),
    );
  }
}

extension on UserResponse {
  get error => null;
}
