# 🛒 Çoklu Market E-Ticaret ve Yönetim Paneli

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)](https://supabase.com)
[![Language](https://img.shields.io/badge/Dil-İngilizce-blue)](README.md)

> **[🇺🇸 Click here for English README](README.md)**

**Flutter** ve **Supabase** kullanılarak geliştirilmiş, uçtan uca bir Full-Stack E-Ticaret çözümüdür. Bu proje, kullanıcıların konumlarına göre en yakın marketi seçebildiği **lokasyon tabanlı çoklu market mimarisine** sahiptir ve market sahipleri için **Gerçek Zamanlı Yönetim Paneli** sunar.

## 🚀 Temel Özellikler

### 📱 Müşteri Uygulaması Deneyimi
* **📍 Konum Tabanlı Market Seçimi:** Kullanıcının GPS konumunu algılar, mesafeleri hesaplar ve hizmet bölgesindeki en yakın aktif marketleri harita üzerinde listeler.
* **🛍️ Akıllı Sepet Mantığı:**
    * **Dinamik Teslimat Ücreti:** Marketin belirlediği kurallara göre kargo ücretini hesaplar.
    * **Ücretsiz Teslimat Barajı:** Belirli bir tutarın üzerinde kargo ücretini otomatik sıfırlar.
    * **Kupon Motoru:** Yüzdelik (%) ve Sabit Tutar (₺) indirimlerini ve alt limit kurallarını destekler.
* **🔎 Gelişmiş Ürün Keşfi:**
    * Kategori bazlı filtreleme.
    * Fiyata (Artan/Azalan) veya İndirime göre akıllı sıralama.
    * Anlık arama fonksiyonu.
* **📦 Sipariş Takibi:**
    * **Canlı Durum Güncellemeleri:** Sipariş durumu (Hazırlanıyor, Yolda, Teslim Edildi) değiştiğinde ekran anlık güncellenir.
    * **Sipariş Geçmişi:** Geçmiş siparişlerin detaylı dökümü ve anlık görüntü (snapshot) verileri.
* **👤 Güvenli Profil Yönetimi:** Adres defteri düzenleme, şifre güncelleme ve profil işlemleri.

### 🛠️ Market Sahibi (Admin) Paneli
* **🛡️ Rol Tabanlı Erişim:** Sistem, giriş yapan kullanıcının "Market Sahibi" olduğunu otomatik algılar ve standart arayüz yerine Yönetim Paneline yönlendirir.
* **🔔 Gerçek Zamanlı Sipariş Merkezi:**
    * **Sesli Bildirim:** Yeni sipariş düştüğü anda uygulama sesli uyarı verir.
    * **Kanban İş Akışı:** Siparişleri yönetin: *Onay Bekleyen -> Hazırlanıyor -> Yolda -> Teslim Edildi*.
    * **Müşteri Snapshot:** Sipariş anındaki müşteri bilgilerini (Ad, Tel, Adres) koruyarak gösterir.
* **📊 Gelir ve Performans Analitiği:**
    * Günlük ve Aylık ciro grafikleri.
    * Satışların **Nakit** ve **Kredi Kartı** dağılımı.
    * "En Çok Satanlar" analizi.
* **⚙️ Mağaza Operasyonları:**
    * **Tek Tuşla Mağaza Aç/Kapa:** Acil durumlarda marketi pasife alma özelliği.
    * **Dinamik Hizmet Limitleri:** Getirme ücretini veya minimum sepet tutarını saniyeler içinde güncelleyin.
* **📦 Stok ve Kampanya:** Ürün ve İndirim Kuponları için tam yetkili Ekle/Sil/Düzenle (CRUD) işlemleri.

### 🔧 Sistem ve Altyapı
* **Bakım Modu:** Sunucu çalışmaları sırasında uygulamayı uzaktan kilitleyerek kullanıcıları bilgilendirme ekranına yönlendirir.
* **Zorunlu Güncelleme (Force Update):** Yüklü versiyonu bulutla kıyaslar ve kritik güncellemelerde kullanıcıyı markete yönlendirir.
* **Supabase Realtime:** Tüm veri akışı PostgreSQL CDC (Change Data Capture) ile milisaniyeler içinde senkronize edilir.

---

## 🏗️ Kullanılan Teknolojiler

* **Frontend:** Flutter (Dart)
* **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
* **State Management:** Provider
* **Harita:** `flutter_map`, `latlong2`, `geolocator`
* **Araçlar:** `audioplayers` (bildirim), `url_launcher`, `package_info_plus`, `flutter_dotenv`

---

## 📧 İletişim

**Sami Erdoğmuş** - [GitHub Profilim](https://github.com/samierdgms)
