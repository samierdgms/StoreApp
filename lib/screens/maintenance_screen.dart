import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Hafif gri arka plan
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build_circle, size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 40),
              const Text(
                "Sistem Bakım Çalışması",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                "Uygulama şu anda planlı bir bakım sürecindedir. Daha iyi bir deneyim sunmak için çalışıyoruz.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
              const SizedBox(height: 20),
              const Text("Kısa süre sonra tekrar deneyin.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}