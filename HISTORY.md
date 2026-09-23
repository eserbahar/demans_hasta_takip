# Teknik Geliştirme Geçmişi

Bu dosya, başka bir geliştiricinin projeyi kaldığı yerden sürdürebilmesi için teknik kararları ve tamamlanan işleri özetler.

## Proje ve GitHub

- Flutter proje adı: `demans_1`
- GitHub repository: `eserbahar/demans_hasta_takip`
- Ana dal: `main`
- Gerçek Supabase key'leri bu dosyada tutulmaz.

## Supabase bağlantısı

- Flutter bağımlılığı: `supabase_flutter`
- Başlatma dosyası: `lib/main.dart`
- Yapılandırma `--dart-define` ile sağlanır:

```powershell
flutter run `
  --dart-define="SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co" `
  --dart-define="SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY"
```

- İstemci uygulamasında `publishableKey` kullanılır.
- `service_role` key kesinlikle Flutter uygulamasına eklenmez.
- Gerçek key'ler Git'e, README'ye veya teknik geçmişe yazılmamalıdır.

## Veritabanı

Migration dosyası:

```text
supabase/migrations/001_initial_schema.sql
```

Oluşturulan tablolar:

- `profiles`
- `patients`
- `patient_access`
- `medications`
- `medication_logs`
- `fluid_entries`
- `urine_entries`
- `daily_notes`
- `alerts`

Şemada ayrıca:

- user role enum'ları: `patient`, `caregiver`, `doctor`, `admin`
- ilaç log status enum'ı
- `updated_at` trigger'ları
- yeni Auth kullanıcısı için otomatik profil trigger'ı
- hasta erişimi için helper function'lar
- RLS politikaları
- authenticated rolü için tablo izinleri

## Tamamlanan Flutter akışı

1. Uygulama Supabase'i başlatır.
2. Kullanıcı Auth ile e-posta/şifre girişi yapar.
3. Oturum yoksa login ekranı gösterilir.
4. Oturum varsa hasta seçim ekranı açılır.
5. Yetkili hastalar `patients` tablosundan listelenir.
6. Hasta ekleme seçim ekranındaki butondan yapılır.
7. Hasta eklenince `patient_access` kaydı otomatik oluşturulur.
8. Hasta seçilince dashboard açılır.
9. Dashboard başlığındaki hasta değiştir düğmesi listeye döner.
10. Seçilen hastanın ilaçları yüklenir.
11. İlaç ekleme, ilaç verilmesi ve iptali Supabase'e yazılır.
12. Sıvı ve idrar girişleri seçilen `patient_id` ile Supabase'e yazılır.
13. Günlük sıvı, idrar ve ilaç logları dashboard açılışında yüklenir.

## Önemli uygulama notları

- `main.dart` şu anda çok sayıda modeli, ekranı ve Supabase işlemini içeriyor; ileride feature-based klasörlere ayrılmalı.
- Dashboard yalnızca seçilen hastanın bakım verilerini göstermelidir.
- Hasta listesi ve erişim kapsamı RLS tarafından sınırlandırılmalıdır.
- Her kayıt `patient_id` ve işlemi yapan kullanıcı ID'si ile ilişkilendirilmelidir.
- Sağlık verileri nedeniyle RLS kapatılmamalıdır.
- Veritabanı sorguları başarısız olduğunda local state başarı gibi güncellenmemelidir.

## Doğrulama

Çalıştırılmış kontroller:

```powershell
dart analyze lib/main.dart
git diff --check
```

Dart analizinde yeni derleme hatası yoktur; mevcut Flutter/Dart API deprecation uyarıları bulunmaktadır.

Supabase endpoint bağlantısı ve `profiles` sorgusu gerçek projede doğrulanmıştır. `1 profil bulundu` sonucu Auth oturumu ve RLS ile profil erişiminin çalıştığını göstermiştir.

## Sıradaki işler

- `daily_notes` için CRUD ekranı
- doktor/bakıcı rol bazlı ekran ve izinler
- hasta erişim yönetimi
- veritabanı servis/repository katmanı
- günlük ve haftalık raporlar
- bildirimler
- widget/integration testleri
- Supabase CLI + Docker ile migration lint doğrulaması

## Güvenlik uyarısı

Bir Supabase key sohbet veya log içine yanlışlıkla gönderilirse dashboard üzerinden key yenilenmeli ve yeni key yalnızca yerel secret/CI değişkeni olarak kullanılmalıdır.
