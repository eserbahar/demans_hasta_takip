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

Migration dosyaları:

```text
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_activity_tracking.sql
```

`001` ile oluşturulan tablolar:

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

`002` ile eklenenler (9 kategorili günlük takip için, **ek/additive** — hiçbir mevcut tablo/veri değiştirilmedi/silinmedi):

- Yeni enum: `activity_category` (`physical`, `mental`, `social`)
- Mevcut `medication_logs`, `fluid_entries`, `urine_entries` tablolarına `rating smallint` kolonu (1-5, nullable)
- Yeni tablolar: `nutrition_entries`, `bowel_entries`, `activity_entries` (Fiziksel/Zihinsel/Sosyal ortak, `category` kolonuyla ayrılır), `vitals_entries` (sıcaklık/nabız/tansiyon, en az biri zorunlu — `vitals_entries_has_a_value` check constraint'i)
- Her yeni tablo `001`'deki `has_patient_access(patient_id)` + tek `for all` RLS policy deseniyle korunur; `logged_by = auth.uid()` kontrolü `with check`'te
- `<tablo>_patient_logged_at_idx` indeks deseni korunur
- Migration sonunda `grant select, insert, update, delete on all tables in schema public to authenticated;` tekrar çalıştırılır (001'deki gibi, `alter default privileges` kullanılmadığı için gerekli)
- Bu migration Supabase SQL Editor üzerinden elle çalıştırıldı (proje `supabase link` ile bağlı değil, CLI ile push edilmedi)

## Tamamlanan Flutter akışı

1. Uygulama Supabase'i başlatır.
2. Kullanıcı Auth ile e-posta/şifre girişi yapar.
3. Oturum yoksa login ekranı gösterilir.
4. Oturum varsa hasta seçim ekranı açılır.
5. Yetkili hastalar `patients` tablosundan listelenir.
6. Hasta ekleme seçim ekranındaki butondan yapılır (ad, doğum tarihi, kronik durumlar, acil iletişim, bakıcı adı, notlar).
7. Hasta eklenince `patient_access` kaydı otomatik oluşturulur.
8. Hasta seçilince **"Bugünü Kaydet"** ekranı açılır (eski "dashboard"/"Ana Sayfa" ekranının yerini aldı, aynı zamanda ana ekrandır).
9. Ekranda 9 kategori kutusu (İlaç, Ateş/Nabız/Tansiyon, Beslenme, Sıvı Alımı, İdrar Çıkışı, Dışkılama, Fiziksel/Zihinsel/Sosyal Aktivite) sabit sırada gösterilir; her kutu o günün durumunu (yıldız + detay veya boş/hatırlatma) canlı olarak Supabase'ten okur.
10. Kutuya dokununca ilgili kategorinin giriş penceresi açılır; kaydedince ilgili tabloya `insert` yapılır ve grid yeniden yüklenir.
11. Üst çubuktaki "Geçmiş/Raporlar" ikonu **Günlük** ekranına gider; Günlük ekranı 9 kategoriyi de gerçek Supabase verisiyle (sayfa yenilense de kaybolmadan) listeler.
12. "PDF dışa aktar" ve "Doktorla paylaş" ikonları şimdilik "Yakında" snackbar'ı gösterir, gerçek işlev yok.

## Önemli uygulama notları

- `main.dart` artık yalnızca bootstrap/tema/Auth gate/login içeriyor; kod `lib/config`, `lib/models`, `lib/widgets`, `lib/screens`, `lib/screens/entries` klasörlerine bölündü (feature-based yapı).
- 9 kategorinin giriş formu alanları (`nutrition_entry_dialog.dart` vb.) **taslak/placeholder** — kesinleşmiş tasarım değil, kullanıcı ayrıca belirleyecek.
- İlaç kutusu artık tek bir ilaç yerine bekleyen/verilmiş ilaçları listeleyen bir "hub" penceresi açıyor (birden fazla ilaç tek kutuda temsil edildiği için).
- Eski Ana Sayfa'daki sıvı/idrar hedef ayarı, ilerleme çubukları, "SIVI ALARMI" banner'ı ve hasta profili düzenleme penceresi bu tasarımda **kaldırıldı** (kullanıcı onayıyla, şimdilik gerekli değil).
- Bakıcı yalnızca seçilen hastanın bakım verilerini görmelidir.
- Hasta listesi ve erişim kapsamı RLS tarafından sınırlandırılmalıdır.
- Her kayıt `patient_id` ve işlemi yapan kullanıcı ID'si (`logged_by`) ile ilişkilendirilmelidir.
- Sağlık verileri nedeniyle RLS kapatılmamalıdır.
- Veritabanı sorguları başarısız olduğunda local state başarı gibi güncellenmemelidir.
- `GridView` içindeki kategori kutularının `childAspectRatio` değeri yeterince küçük tutulmalı (şu an `0.56`); aksi halde kutu içeriği (ikon+etiket+yıldız+hatırlatma metni) üst üste biner — bu hata bu oturumda bulunup düzeltildi, benzer bir grid eklenirse tekrar dikkat edilmeli.

## Doğrulama

Çalıştırılmış kontroller:

```powershell
flutter analyze lib
flutter build web --dart-define="SUPABASE_URL=..." --dart-define="SUPABASE_PUBLISHABLE_KEY=..."
```

`flutter analyze lib`: yeni hata/uyarı yok, yalnızca 1 önceden var olan `unnecessary_underscores` info uyarısı (`patient_selection_screen.dart`, orijinal koddan taşınmış). `flutter build web` başarılı.

Supabase endpoint bağlantısı ve `profiles` sorgusu gerçek projede doğrulanmıştır. `1 profil bulundu` sonucu Auth oturumu ve RLS ile profil erişiminin çalıştığını göstermiştir.

9 kategorinin `insert`/okuma kodu, `002_activity_tracking.sql`'deki kolon adları ve tipleriyle birebir eşleşecek şekilde kod incelemesiyle doğrulandı (`nutrition_entries`, `bowel_entries`, `activity_entries`, `vitals_entries`). Tarayıcı üzerinden canlı tıklama testi otomasyon aracının koordinat/ölçek tutarsızlığı nedeniyle tamamlanamadı; kod incelemesi yeterli görüldü.

## Sıradaki işler

- 9 kategorinin giriş formu alanlarını kesinleştirmek
- Raporlar ekranı
- PDF dışa aktarma ve doktorla paylaşma özellikleri
- Eski sıvı/idrar hedef ayarı, ilerleme çubukları, uyarı banner'ı ve hasta profili düzenlemenin bu tasarımda nereye/nasıl geri ekleneceği
- `daily_notes` için CRUD ekranı
- doktor/bakıcı rol bazlı ekran ve izinler
- hasta erişim yönetimi
- günlük ve haftalık raporlar
- bildirimler
- widget/integration testleri
- Supabase CLI + Docker ile migration lint doğrulaması (proje şu an `supabase link` ile bağlı değil, migration'lar SQL Editor'den elle çalıştırılıyor)

## Güvenlik uyarısı

Bir Supabase key sohbet veya log içine yanlışlıkla gönderilirse dashboard üzerinden key yenilenmeli ve yeni key yalnızca yerel secret/CI değişkeni olarak kullanılmalıdır.
