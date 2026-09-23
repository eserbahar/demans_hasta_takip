# Demans Hasta Takip

Bu proje, demans hastası için günlük bakım, ilaç takibi ve sıvı/idrara ilişkin takip işlemlerini kolaylaştırmak amacıyla geliştirilmiş bir Flutter mobil uygulamasıdır.

## Proje Hakkında

Uygulama; hasta, bakıcı ve doktor rollerini destekleyecek şekilde geliştirilen, merkezi Supabase veritabanı kullanan bir demans bakım takip uygulamasıdır. Kullanıcı girişinden sonra yetkili hastalar listelenir; seçilen hastaya ait bakım dashboard'u açılır.

## Yapılanlar

- Hasta profili ekranı ve düzenleme işlemleri
- Yaş, doğum tarihi ve kronik durumların gösterimi
- İlaç listesi ve veriliş takibi
- Sabah/öğle/akşam zaman dilimlerine göre ilaç planlaması
- Günlük sıvı hedefi takibi
- Günlük idrar hedefi takibi
- Uyarı ve hedef aşımı gösterimi
- Aktivite/işlem geçmişi kaydı
- Flutter Material 3 tasarım dili kullanımı
- Supabase Auth ile e-posta/şifre girişi
- Supabase PostgreSQL bağlantısı ve RLS tabanlı erişim
- Hasta listesi, hasta seçimi ve hasta değiştirme akışı
- Hasta ekleme ve otomatik `patient_access` kaydı
- İlaçların seçilen hastaya göre Supabase'ten yüklenmesi
- İlaç ekleme ve ilaç veriliş/iptal loglarının merkezi kaydı
- Sıvı ve idrar kayıtlarının seçilen `patient_id` ile saklanması
- Günlük sıvı, idrar ve ilaç durumlarının veritabanından geri yüklenmesi

## Özellikler

### Hasta Profili
- Hasta adı, doğum tarihi ve yaşı
- Bilinen rahatsızlıklar / kronik hastalıklar
- Profil düzenleme butonu ile bilgiler güncellenebilir

### İlaç Takibi
- İlaç adı, doz, saat ve zaman dilimi bilgisi
- Verildi / verilmedi durumu
- Kullanım sonrası zaman kaydı
- İlaç iptali için onay mekanizması

### Sıvı ve İdrar Takibi
- Günlük hedef değerleri ayarlanabilir
- Mevcut sıvı ve idrar miktarı takip edilir
- Hedefe ulaşılmadığında uyarı gösterimi sağlanır

### Aktivite Logları
- İlaç verilişi, su tüketimi ve idrar takibi gibi olaylar loglanır
- Zaman damgası ile geçmiş görüntülenebilir

## Teknoloji Stack

- Flutter
- Dart
- Material 3
- Supabase Auth
- Supabase PostgreSQL
- Supabase Row Level Security (RLS)

## Çalıştırma

Proje klasöründe aşağıdaki komutları çalıştırın:

```bash
flutter pub get
flutter run --dart-define="SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co" --dart-define="SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY"
```

`SUPABASE_PUBLISHABLE_KEY` mobil/web istemcide kullanılabilir anahtardır. `service_role` anahtarını uygulamaya eklemeyin. Gerçek anahtarları README, Git veya sohbet kayıtlarına yazmayın.

## GitHub Pages

`main` dalına yapılan her push, [deploy-pages.yml](.github/workflows/deploy-pages.yml) workflow'u ile Flutter Web sürümünü GitHub Pages'e deploy eder.

GitHub repository settings içinde **Settings → Secrets and variables → Actions → Variables** bölümüne şu iki repository variable'ı ekleyin:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

İlk deployment'tan önce **Settings → Pages → Source** değerini **GitHub Actions** olarak seçin. Proje URL'si:

```text
https://eserbahar.github.io/demans_hasta_takip/
```

Supabase Auth kullanıldığı için bu domaini Supabase Authentication URL Configuration bölümündeki redirect allow list'e ekleyin.

## Geliştirme Ortamı

Projeyi yerel olarak çalıştırmak için aşağıdakiler gereklidir:

- Flutter SDK
- Dart SDK
- Android Studio veya VS Code
- Bir Android/iOS emülatörü veya cihaz

## Proje Yapısı

```text
lib/
  main.dart

supabase/
  migrations/
    001_initial_schema.sql

test/
  widget_test.dart
```

## Mevcut Durum

İlk Supabase entegrasyonu çalışır durumdadır. Auth, profil sorgusu, yetkili hasta listesi, hasta ekleme, ilaç kayıtları, ilaç logları, sıvı ve idrar kayıtları merkezi veritabanına bağlanmıştır. SQL şeması ve RLS politikaları [supabase/migrations/001_initial_schema.sql](supabase/migrations/001_initial_schema.sql) dosyasındadır.

Henüz tamamlanmamış başlıca konular:

- Günlük notların Flutter ekranına bağlanması
- Doktor/bakıcı rolüne göre ayrı yetki ve ekranlar
- Hasta erişimi yönetim ekranı
- Haftalık/aylık raporlar ve grafikler
- Bildirimler ve üretim güvenliği kontrolleri
- Uygulama kodunun `main.dart` dışındaki feature klasörlerine ayrılması

## Lisans

Bu proje için lisans bilgisi eklenmemiştir. İstendiğinde uygun lisans dosyası eklenebilir.
