# Demans Hasta Takip

Bu proje, demans hastası için günlük bakım takibini kolaylaştırmak amacıyla geliştirilmiş bir Flutter mobil uygulamasıdır. Bakıcı, hastanın günlük durumunu 9 kategoride (İlaç, Beslenme, Sıvı Alımı, İdrar Çıkışı, Dışkılama, Fiziksel/Zihinsel/Sosyal Aktivite, Ateş/Nabız/Tansiyon) 1-5 yıldız üzerinden puanlayarak ve isteğe bağlı not ekleyerek kaydeder.

## Proje Hakkında

Uygulama; hasta, bakıcı ve doktor rollerini destekleyecek şekilde geliştirilen, merkezi Supabase veritabanı kullanan bir demans bakım takip uygulamasıdır. Kullanıcı girişinden sonra yetkili hastalar listelenir; seçilen hasta için **"Bugünü Kaydet"** ekranı açılır — bu ekran aynı zamanda uygulamanın ana/karşılama ekranıdır.

## Yapılanlar

- Hasta profili: ad, doğum tarihi, yaş, kronik durumlar, acil iletişim, bakıcı adı, notlar
- **9 kategorili günlük takip**: İlaç, Beslenme, Sıvı Alımı, İdrar Çıkışı, Dışkılama, Fiziksel Aktivite, Zihinsel Aktivite, Sosyal Aktivite, Ateş/Nabız/Tansiyon
- Her kategori için 1-5 yıldız puanlama + isteğe bağlı not; İlaç/Sıvı/İdrar ayrıca kendi klinik alanlarını (doz durumu, ml miktarı, idrar durumu) korur
- "Bugünü Kaydet" ekranı: 3x3 kategori grid'i, her kutu o gün için kayıt yoksa boş/hatırlatma durumunda, kayıt varsa dolu yıldız + detay gösterir
- Günlük olarak sıfırlanan "bugün" durumu, tüm geçmiş kalıcı olarak saklanır (tarih bazlı sorgu, silme/üzerine yazma yok)
- Günlük (Günlük sekmesi): tüm 9 kategori için gerçek Supabase verisiyle geçmiş listesi, sayfa yenilense bile kaybolmaz
- Flutter Material 3 + özel tema (Fraunces/Figtree yazı tipleri, sıcak renk paleti — `google_fonts` paketi ile)
- Supabase Auth ile e-posta/şifre girişi
- Supabase PostgreSQL bağlantısı ve RLS tabanlı erişim
- Hasta listesi, hasta seçimi ve hasta değiştirme akışı
- Hasta ekleme ve otomatik `patient_access` kaydı
- İlaçların seçilen hastaya göre Supabase'ten yüklenmesi
- İlaç ekleme ve ilaç veriliş/iptal loglarının merkezi kaydı

## Özellikler

### Hasta Profili
- Hasta adı, doğum tarihi, yaşı, acil iletişim, bakıcı adı, notlar
- Hasta ekleme formu tüm bu alanları içerir

### Bugünü Kaydet (Ana Ekran)
- 9 kategori kutusu (tile), sabit sırada: İlaç, Ateş/Nabız/Tansiyon, Beslenme / Sıvı Alımı, İdrar Çıkışı, Dışkılama / Fiziksel, Zihinsel, Sosyal Aktivite
- Her kutuya dokununca ilgili kategorinin giriş penceresi açılır (yıldız + nota ek olarak kategoriye özel alanlar — bu alanlar henüz taslak/placeholder, kesinleşmiş tasarım değildir)
- Üst çubukta hasta adı, tarih ve 3 ikon: Geçmiş/Raporlar, PDF dışa aktar, Doktorla paylaş (şimdilik "Yakında" durumunda, ileride bağlanacak)
- Alt gezinme çubuğu yoktur; gezinme üst çubuktaki ikonlar üzerinden yapılır

### İlaç Takibi
- İlaç adı, doz, saat ve zaman dilimi bilgisi
- Verildi / verilmedi durumu, iptal onay mekanizması
- Yıldız puanı + not ile birlikte kaydedilir

### Sıvı, İdrar, Beslenme, Dışkılama, Aktivite, Vital Bulgular
- Sıvı ve idrar mevcut ml bazlı girişlerini korur, üzerine yıldız + not eklenmiştir
- Beslenme: öğün tipi + porsiyon yüzdesi + yıldız + not
- Dışkılama: kıvam + yıldız + not
- Fiziksel/Zihinsel/Sosyal Aktivite: süre + yıldız + not (tek ortak tablo, kategoriye göre ayrılır)
- Ateş/Nabız/Tansiyon: sıcaklık/nabız/tansiyon (en az biri zorunlu) + yıldız + not

> Not: Eski "Ana Sayfa" ekranındaki sıvı/idrar hedef ayarı, ilerleme çubukları ve "SIVI ALARMI" uyarı banner'ı bu tasarımda henüz karşılığı olmadığı için kaldırılmıştır; istenirse ayrı bir ekran olarak geri eklenebilir.

## Teknoloji Stack

- Flutter
- Dart
- Material 3 + `google_fonts` (Fraunces/Figtree)
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
  main.dart                          # bootstrap, tema, Auth gate, giriş ekranı
  config/
    activity_categories.dart         # 9 kategorinin tek kaynak listesi (id, ikon, renk, tablo adı)
    app_colors.dart                  # onaylanan renk paleti
  models/
    patient.dart, medication.dart, entries.dart, journal_entry.dart
  widgets/
    star_rating.dart                 # StarRatingInput / StarRatingDisplay
  screens/
    patient_selection_screen.dart
    log_today_screen.dart            # "Bugünü Kaydet" — ana ekran
    journal_screen.dart              # "Günlük"
    entries/                         # kategori başına bir giriş penceresi dosyası
      medication_entry_dialog.dart
      nutrition_entry_dialog.dart
      fluid_entry_dialog.dart
      urine_entry_dialog.dart
      bowel_entry_dialog.dart
      activity_entry_dialog.dart     # Fiziksel/Zihinsel/Sosyal ortak
      vitals_entry_dialog.dart

supabase/
  migrations/
    001_initial_schema.sql
    002_activity_tracking.sql        # 9 kategori için yıldız + yeni tablolar (ek/additive)

test/
  widget_test.dart
```

## Mevcut Durum

Supabase entegrasyonu ve 9 kategorili günlük takip tasarımı uçtan uca çalışır durumdadır. Auth, profil sorgusu, yetkili hasta listesi, hasta ekleme, ilaç/sıvı/idrar/beslenme/dışkılama/aktivite/vital kayıtları merkezi veritabanına bağlanmıştır. SQL şeması ve RLS politikaları [supabase/migrations/001_initial_schema.sql](supabase/migrations/001_initial_schema.sql) ve [supabase/migrations/002_activity_tracking.sql](supabase/migrations/002_activity_tracking.sql) dosyalarındadır.

Henüz tamamlanmamış / taslak durumda olan başlıca konular:

- 9 kategorinin giriş formu alanları kesinleşmedi — mevcut alanlar (öğün tipi, kıvam, süre vb.) yer tutucu/örnek niteliğindedir
- Raporlar ekranı henüz yok (üst çubuktaki "Geçmiş/Raporlar" ikonu şimdilik Günlük'e yönlendiriyor)
- PDF dışa aktarma ve doktorla paylaşma ikonları şimdilik "Yakında" durumunda, bağlanmadı
- Eski sıvı/idrar hedef ayarı, ilerleme çubukları, "SIVI ALARMI" banner'ı ve hasta profili düzenleme penceresi bu tasarımda henüz yok
- Doktor/bakıcı rolüne göre ayrı yetki ve ekranlar
- Hasta erişimi yönetim ekranı
- Bildirimler ve üretim güvenliği kontrolleri

## Lisans

Bu proje için lisans bilgisi eklenmemiştir. İstendiğinde uygun lisans dosyası eklenebilir.
