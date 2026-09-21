# Demans Hasta Takip Projesi – Geliştirme Planı

Bu doküman, hem işlevsel hem teknik açıdan uygulamanın geliştirilmesi için yapılacak adımları, öncelik sırasını ve zorluk seviyesini açıklar. Skor sistemi:

- Importance (Öncelik): 1–5
- Complexity (Zorluk): 1–5
- 5 = en yüksek değer

## 1. Proje hedefi

Bu uygulamanın temel amacı, demans hastası için bakım takibini daha güvenli, düzenli ve kullanılabilir hale getirmektir. Sistem, hasta bilgilerini, ilaç kullanımını, sıvı alımını, idrar takibini ve bakım kayıtlarını merkezi ve güvenli bir platformda yönetmelidir.

## 2. Temel teknoloji kararı

Önerilen platform: Supabase

Neden:
- PostgreSQL tabanlı merkezi veri tabanı
- Kullanıcı doğrulama (Auth)
- Row Level Security (RLS) ile veri güvenliği
- Flutter ile kolay entegrasyon
- Hızlı geliştirme ve düşük kurulum maliyeti
- Hasta verileri için uygun güvenlik katmanı

## 3. İşlevsel plan

### 3.1 Hasta yönetimi

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| Çoklu hasta profili | Her hasta için ayrı profil, ad, doğum tarihi, kronik durumlar, notlar | 5 | 3 |
| Hasta arama ve filtreleme | Ad, yaş, aktiflik, bakım durumu filtreleri | 4 | 2 |
| Hasta ekleme/düzenleme | Profilin güncellenmesi ve silinmesi | 5 | 2 |
| Acil iletişim bilgileri | Acil durum telefonu, bakım veren bilgileri | 5 | 2 |
| Hasta durumu etiketleri | Aktif, izlemde, riskli, tamamlandı | 3 | 2 |

### 3.2 İlaç takibi

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| İlaç listesi | İlaç adı, doz, saat, zaman dilimi | 5 | 2 |
| Günlük ilaç planı | Sabah/öğle/akşam/gece planlaması | 5 | 3 |
| İlaç verildi durumu | Verildi / verilmedi takibi | 5 | 2 |
| İlaç hatırlatıcı | Bildirim ve alarm | 5 | 4 |
| İlaç kullanım geçmişi | Geçmiş verilişler ve tarihler | 4 | 2 |
| İlaç iptali / düzeltme | Yanlış girişin düzeltilmesi | 4 | 2 |

### 3.3 Sıvı ve boşaltım takibi

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| Günlük sıvı hedefi | Toplam ml hedefi tanımlama | 5 | 2 |
| Sıvı girişi kaydı | Su, çay, meyve suyu, süt vb. | 5 | 2 |
| İdrar takibi | Miktar, zaman, durum, yoğunluk | 5 | 3 |
| Dışkı / boşaltım takibi | Durum ve zaman kaydı | 4 | 3 |
| Uyarı sistemi | Hedefin altında kalma uyarısı | 5 | 3 |
| Rapor özeti | Günlük / haftalık sıvı ve idrar özeti | 4 | 3 |

### 3.4 Bakım günlüğü ve notlar

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| Günlük bakım notu | Hasta için günlük kısa notlar | 5 | 2 |
| Bakım veren ekibi | Kimin kayıt yaptığı | 4 | 3 |
| Acil durum notları | Hızlı müdahale için özel durumlar | 5 | 3 |
| Görüşme / ziyaret notları | Bakım görevlileri tarafından yazılır | 3 | 2 |
| Rutin ve özel bakım akışı | Özel bakım adımları | 4 | 3 |

### 3.5 Raporlama ve analitik

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| Günlük sağlık özeti | İlaç, sıvı, idrar ve notların tek sayfa özeti | 5 | 3 |
| Haftalık rapor | Son 7 gün değerlendirmesi | 4 | 3 |
| Aylık rapor | Trend analizi | 3 | 4 |
| Grafikler | Sıvı, idrar, ilaç grafikleri | 4 | 4 |
| İstisna / risk göstergeleri | Düşüş veya riskli durumlar | 5 | 4 |

### 3.6 Güvenlik ve erişim

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| Kullanıcı girişi | Email / şifre veya OAuth | 5 | 3 |
| Rol bazlı erişim | Bakım görevlisi / yönetici / doktor | 5 | 4 |
| Veri güvenliği | Kişisel sağlık verilerinin korunması | 5 | 4 |
| Erişim loglaması | Kim ne zaman erişti | 4 | 3 |
| Şifreleme | Veriler sunucuda şifrelenmeli | 5 | 3 |

## 4. Teknik plan

### 4.1 Uygulama mimarisi

Önerilen mimari:

- Flutter mobil uygulama
- Supabase Auth
- Supabase Postgres
- Supabase Storage (gerekirse dosya ekleme)
- API / servis katmanı
- State management: Riverpod veya Provider
- Modüler yapı: feature-based architecture

### 4.2 Önerilen klasör yapısı

```text
lib/
  app/
    app.dart
  core/
    constants/
    theme/
    utils/
    validators/
  features/
    auth/
      data/
      domain/
      presentation/
    patients/
      data/
      domain/
      presentation/
    medications/
      data/
      domain/
      presentation/
    tracking/
      data/
      domain/
      presentation/
    reports/
      data/
      domain/
      presentation/
  services/
    supabase_service.dart
  shared/
    widgets/
    models/
```

### 4.3 Veri modeli önerisi

#### patients
- id
- full_name
- birth_date
- age
- medical_conditions
- emergency_contact
- caregiver_name
- notes
- created_at
- updated_at

#### medications
- id
- patient_id
- name
- dosage
- time_slot
- scheduled_time
- is_active
- created_at

#### medication_logs
- id
- patient_id
- medication_id
- status (taken / missed / cancelled)
- logged_at
- notes

#### fluid_entries
- id
- patient_id
- amount_ml
- type
- logged_at

#### urine_entries
- id
- patient_id
- amount_ml
- status
- logged_at

#### daily_notes
- id
- patient_id
- note
- created_by
- created_at

### 4.4 Güvenlik gereksinimleri

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| RLS politikaları | Kullanıcı sadece kendi hasta verisine erişebilir | 5 | 4 |
| JWT token güvenliği | Yetkilendirme ve session yönetimi | 5 | 3 |
| Veritabanı şifreleme | Hassas veri koruması | 5 | 3 |
| API güvenlik | HTTPS zorunlu | 5 | 2 |
| Loglama | Erişim ve değişiklik izleme | 4 | 3 |
| Yedekleme | Otomatik veri yedekleme düzeni | 4 | 3 |

### 4.5 Notification / alarm sistemi

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| İlaç hatırlatma | Planlanan ilaç saatinde bildirim | 5 | 4 |
| Sıvı uyarısı | Belirli süre boyunca sıvı giriş yoksa uyarı | 4 | 3 |
| Push notification | Mobil cihaz bildirimleri | 4 | 4 |
| Lokal alarm | Uygulama içinde anlık alarm | 3 | 2 |

### 4.6 Test stratejisi

| Başlık | Açıklama | Importance | Complexity |
|---|---|---:|---:|
| Unit test | Veri modeli ve servis katmanı | 4 | 3 |
| Widget test | UI akışı ve form doğrulamaları | 4 | 3 |
| Integration test | Kayıt, takip, rapor akışı | 5 | 4 |
| E2E test | Uygulama akışının son kullanıcı görünümü | 3 | 4 |

## 5. 3 ay roadmap

### Ay 1 – Temel veri ve kullanıcı akışı
- Supabase kurulumu
- Auth kurulumu
- Hasta profil modeli ve tablo yapısı
- Hasta ekleme / düzenleme ekranları
- Temel veri servisleri
- İlk testler

Importance toplam: 5 / 5
Complexity: 3 / 5

### Ay 2 – Takip akışı ve bakım ekranı
- İlaç takibi ve log sistemi
- Sıvı ve idrar giriş ekranları
- Günlük bakım notları
- Hedef ayarları
- Uyarı sistemi
- UI ve state yönetimi iyileştirme

Importance toplam: 5 / 5
Complexity: 4 / 5

### Ay 3 – Raporlama, güvenlik ve release hazırlığı
- Haftalık / aylık raporlar
- Grafikler ve istatistikler
- Rol tabanlı erişim
- Güvenlik ve loglama
- Bildirimler
- App store / play store hazırlığı
- Final testler

Importance toplam: 5 / 5
Complexity: 4 / 5

## 6. Öncelik sırası

1. Kullanıcı güvenliği ve veri koruma
2. Hasta profili ve veri modeli
3. İlaç ve bakım takibi
4. Sıvı / idrar takibi
5. Raporlama ve grafikler
6. Bildirimler ve alarm sistemi
7. Release ve production hazırlığı

## 7. Son karar

En doğru yaklaşım şu şekildedir:
- merkezi veri tabanı kullanılmalı
- SQLite opsiyonel olarak kullanılabilir ama ana veri kayna değil
- Supabase önerilen platform
- güvenlik ve erişim kontrolü ilk aşamada öncelikli olmalı

Bu plan, uygulanabilir ve güvenli bir hasta bakım takip sistemi kurmak için gerekli temel yapıyı verir.
