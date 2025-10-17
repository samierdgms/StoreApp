# Flutter Market Uygulaması Projesi

Bu proje, [Flutter](https://flutter.dev) çatısı kullanılarak geliştirilmiş kapsamlı bir mobil market (e-ticaret) uygulamasıdır. Uygulama, hem son kullanıcıların alışveriş yapabileceği bir vitrin arayüzü hem de yöneticilerin sistemi yönetebileceği bir admin paneli içerir.

Tüm veriler (ürünler, siparişler, kullanıcılar vb.) dinamiktir ve bir backend/veritabanı ile `services` katmanı üzerinden yönetilmektedir.

## 🚀 Temel Özellikler

Proje, iki ana bölümden oluşmaktadır: Kullanıcı Arayüzü ve Yönetici Paneli.

### 1. Kullanıcı Arayüzü (`/screens`)

Son kullanıcıların market alışverişi yapmak için kullandığı ekranlar:

* **Giriş & Kayıt:** Güvenli kullanıcı kimlik doğrulaması (`login_screen.dart`, `registration_screen.dart`).
* **Ana Sayfa:** Öne çıkan ürünlerin ve kategorilerin listelendiği vitrin (`home_screen.dart`).
* **Ürün Arama:** Kullanıcıların ürünleri arayabilmesi (`search_screen.dart`).
* **Ürün Detay:** Bir ürünün özelliklerinin, fiyatının ve görsellerinin incelendiği ekran (`product_detail_screen.dart`).
* **Sepet:** Alışveriş sepeti yönetimi (ekleme, çıkarma, adet güncelleme) (`cart_screen.dart`).
* **Kampanyalar:** Mevcut indirim ve kampanyaların gösterilmesi (`campaign_screen.dart`).
* **Ödeme:** Sepetin onaylanması ve ödeme işlemlerinin yapılması (`payment_screen.dart`).
* **Sipariş Geçmişi:** Kullanıcının eski siparişlerini ve detaylarını görmesi (`order_history_screen.dart`, `order_detail_screen.dart`).
* **Kullanıcı Profili:** Kullanıcı bilgilerinin ve ayarlarının yönetilmesi (`user_profile_screen.dart`).
* **Yardım & Bakım:** Destek ve bilgilendirme ekranları (`help_screen.dart`, `maintenance_screen.dart`).

### 2. Yönetici Paneli (`/admin_screens`)

Uygulama yöneticilerinin verileri ve sistemi yönettiği bölüm:

* **Gelir Takibi:** Günlük ve genel gelirlerin görüntülendiği dashboard (`revenue_screen.dart`, `daily_revenue_detail_screen.dart`).
* **Ürün Yönetimi:** Sisteme yeni ürün ekleme, mevcut ürünleri düzenleme ve silme (`product_settings_screen.dart`).
* **Kupon Yönetimi:** İndirim kuponları oluşturma ve yönetme (`coupons_settings_screen.dart`).
* **Sipariş Ayarları:** Gelen siparişlerle ilgili ayarların yönetilmesi (`order_settings_screen.dart`).
* **Sistem Ayarları:** Uygulamanın genel ayarları (örn: bakım modu, ücretler) (`system_settings_screen.dart`, `fee_settings_screen.dart`).

## 🛠️ Teknoloji Yığını ve Mimari

* **Platform:** Flutter & Dart
* **Durum Yönetimi (State Management):** Provider (`cart_provider.dart`)
* **Mimari:** Servis Katmanlı Mimari
    * **`models`:** `Product`, `Order`, `CartItem`, `Coupon` gibi temiz veri modelleri.
    * **`services`:** Veritabanı veya API ile iletişimi yöneten soyutlanmış servisler (`product_service.dart`, `order_service.dart`, `coupon_service.dart` vb.).
    * **`screens` & `admin_screens`:** Servislerden alınan verileri kullanıcıya gösteren arayüz katmanı.
    * **`widgets`:** `product_tile.dart` gibi tekrar kullanılabilir arayüz bileşenleri.


