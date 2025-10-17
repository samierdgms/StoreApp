import 'package:flutter/material.dart';
import 'package:storeappp/services/maintenance_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  _SystemSettingsScreenState createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _isMaintenance = false;
  bool _showConfirmationDialog = false;

  @override
  void initState() {
    super.initState();
    _fetchMaintenanceStatus();
  }

  // Bakım modu durumunu Supabase'den çekiyoruz
  Future<void> _fetchMaintenanceStatus() async {
    try {
      bool maintenanceStatus = await MaintenanceService.isMaintenanceActive();
      setState(() {
        _isMaintenance = maintenanceStatus;
      });
    } catch (e) {
      print('Veritabanından bakım durumu alınamadı: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Bakım durumu alınırken hata oluştu.')),
      );
    }
  }

  // Bakım modunu açmak için veritabanına kaydediyoruz
  Future<void> _activateMaintenanceMode() async {
    try {
      final response = await MaintenanceService.activateMaintenanceMode();

      if (response == true) {
        setState(() {
          _isMaintenance = true;
        });
        _fetchMaintenanceStatus();
      } else {
        _fetchMaintenanceStatus();
      }
    } catch (e) {
      print('Bakım modu aktif edilirken hata: $e');
      _fetchMaintenanceStatus();
    }
  }

  Future<void> _deactivateMaintenanceMode() async {
    try {
      final response = await MaintenanceService.deactivateMaintenanceMode();

      if (response == true) {
        setState(() {
          _isMaintenance = false;
        });
        _fetchMaintenanceStatus();
      } else {
        _fetchMaintenanceStatus();
      }
    } catch (e) {
      print('Bakım modu kapatılırken hata: $e');
      _fetchMaintenanceStatus();
    }
  }

  // Onay kutusunu içeren dialog gösteriyoruz
  void _showMaintenanceConfirmationDialog(bool isActivate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isActivate
                ? '⚠️ Bakım Modunu Açmak Üzeresiniz!'
                : '⚠️ Bakım Modunu Kapatmak Üzeresiniz!',
            style: TextStyle(color: isActivate ? Colors.red : Colors.green),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActivate
                    ? '❗ Bakım modunu açmak geri alınamaz bir işlem olacaktır. Bu işlemden sonra bakım modunu kapatmak için veritabanı müdahalesi gereklidir. Lütfen dikkatlice düşünün!'
                    : '❗ Bakım modunu kapatmak, sistemdeki tüm işlemleri yeniden aktif edecektir. Lütfen dikkatlice düşünün!',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Onaylıyorum (Yazın)',
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: 'Yazın: Onaylıyorum',
                ),
                onChanged: (value) {
                  setState(() {
                    _showConfirmationDialog = value == 'Onaylıyorum';
                  });
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('❌ İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (_showConfirmationDialog) {
                  if (isActivate) {
                    await _activateMaintenanceMode();
                  } else {
                    await _deactivateMaintenanceMode();
                  }
                  await _fetchMaintenanceStatus();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Lütfen onayınızı yazın.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('✅ Onayla'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sistem Ayarları')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Üst uyarı
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                '⚠️ Admin oturum açmamış ise bakım ekranı sadece veritabanından kapatılabilir. Eğer ne yaptığınızı bilmiyorsanız değiştirmeyiniz.',
                style: TextStyle(fontSize: 14, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Bakım modu durumu
            const Text(
              'Bakım Modu Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _isMaintenance
                ? const Text(
              '✅ Bakım modu şu anda **aktif**.',
              style: TextStyle(fontSize: 16, color: Colors.green),
              textAlign: TextAlign.center,
            )
                : const Text(
              '❌ Bakım modu şu anda **pasif**.',
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Bakım modunu açma/kapama butonu
            ElevatedButton(
              onPressed: _isMaintenance
                  ? () {
                _showMaintenanceConfirmationDialog(false);
              }
                  : () {
                _showMaintenanceConfirmationDialog(true);
              },
              child: Text(
                _isMaintenance ? '🛠️ BAKIM MODUNU KAPAT' : '🛠️ BAKIM MODUNU AÇ',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const Spacer(),

            // Alt uyarı
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                '⚠️ Bu ayar sadece admin kullanıcılar için geçerlidir.',
                style: TextStyle(fontSize: 14, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
