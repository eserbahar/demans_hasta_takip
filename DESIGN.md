# Tasarım Sistemi

Bu dosya, 9 kategorili günlük takip yeniden tasarımı için onaylanan görsel tasarım kararlarını kalıcı olarak kaydeder. Kaynak: bir HTML mockup (Artifact) üzerinde kullanıcıyla birlikte çok sayıda yinelemeyle onaylanan tasarım, ardından gerçek Flutter koduna ([lib/config/app_colors.dart](lib/config/app_colors.dart), [lib/config/activity_categories.dart](lib/config/activity_categories.dart)) geçirildi.

Onaylanan mockup (özel/private Artifact, yalnızca hesap sahibi erişebilir): https://claude.ai/artifact/PqeGc5vHsfFtiWJMdH4sxV

## Renk Paleti

| Kullanım | Renk | Hex |
|---|---|---|
| Arka plan (Scaffold + AppBar) | Sıcak krem | `#F6F2EA` |
| Birincil / aksiyon rengi | Koyu ada yeşili | `#2F6F5E` |
| Gövde metni | Sıcak antrasit | `#2B2A28` |
| Soluk / ikincil metin | Kahve grisi | `#8A8378` |
| Kart kenarlığı | Açık bej | `#ECE6D8` |
| Kart yüzeyi | Beyaz | `#FFFFFF` |

Kaynak: [lib/config/app_colors.dart](lib/config/app_colors.dart) — `AppColors` sınıfı.

## Yazı Tipleri

- **Fraunces** (serif, sıcak, "hero" hissi) — başlıklar ve hasta adı gibi öne çıkan metinler için (`titleLarge`/`titleMedium`/`headlineSmall`/`headlineMedium`).
- **Figtree** (sans-serif, okunaklı) — gövde metni ve genel AppBar başlıkları için (varsayılan `textTheme`).
- Her ikisi de `google_fonts` paketiyle (`pubspec.yaml`) CDN üzerinden yüklenir; ekstra font dosyası projeye eklenmedi.
- Neden bu ikili: demans bakıcıları genellikle zaman baskısı altında, bazen yaşlı kullanıcılar — okunaklı ama sıcak/klinik-olmayan bir görünüm hedeflendi (düz mavi Material rengi yerine).

## Kategori → İkon / Renk Eşlemesi

Sabit grid sırası ve her kategorinin kendine özgü vurgu rengi:

| Sıra | Kategori | İkon | Renk |
|---|---|---|---|
| 1 | İlaç | `Icons.medication`-benzeri (şırınga/hap) | Yeşil `#4C8C6B` |
| 2 | Ateş / Nabız / Tansiyon | Kalp (`Icons.favorite`) | Mercan `#C1483F` |
| 3 | Beslenme | Çatal-bıçak (`Icons.restaurant`) | Turuncu-kahve `#C97B4A` |
| 4 | Sıvı Alımı | Su damlası | Mavi `#3E7CB1` |
| 5 | İdrar Çıkışı | İki kişi ikonu | Amber `#D98E3F` |
| 6 | Dışkılama | Kum saati | Kahverengi `#8B6449` |
| 7 | Fiziksel Aktivite | Yürüyen kişi | Teal `#2E8B8B` |
| 8 | Zihinsel Aktivite | Beyin/kafa | Mor `#7C5CA8` |
| 9 | Sosyal Aktivite | Kişi grubu | Pembe `#C15B7C` |

Her kategorinin ikon arkaplanı, kendi rengin ~%15 tonlaşmış hali (`tint`) olarak ayarlanmıştır — bkz. `lib/config/activity_categories.dart`.

Bu sıra hem "Bugünü Kaydet" grid'inde hem de Günlük ekranındaki bölüm sırasında birebir korunmalıdır.

## Yıldız Puanlama

- 1-5 yıldız, "ne kadar iyi geçti" anlamında: 5 = çok iyi/sorunsuz, 1 = reddetti/çok kötü.
- **Tüm 9 kategori de yıldız alır** — Ateş/Nabız/Tansiyon dahil (başlangıçta "vitals yıldız almasın" kararı alınmıştı, tasarım incelemesi sırasında kullanıcı isteğiyle geri alındı; tüm kategoriler tutarlı olsun diye).
- Boş durumda (o gün için kayıt yok): 5 boş/outline yıldız + altında soluk "Günlük veri girişi yapılmadı" metni.
- Dolu durumda: yıldızlar kategori rengiyle dolar, metin kaybolur, yerine gerçek detay (ör. "+200 ml Su", "38.5°C") gelir.
- "Bugün" durumu tamamen okuma-zamanı bir tarih filtresidir (`logged_at` bugünün `[00:00, yarın 00:00)` aralığında mı) — ayrı bir sıfırlama mantığı yoktur, gece yarısı otomatik olarak sıfırlanmış görünür. Hiçbir kayıt silinmez/üzerine yazılmaz.

## Ekran Yerleşimi

- **Bugünü Kaydet**: uygulamanın tek ana/karşılama ekranı (ayrı bir "Ana Sayfa" yoktur). Üst çubukta hasta adı (başlık) + tarih (alt başlık) + 3 ikon (Geçmiş/Raporlar, PDF dışa aktar, Doktorla paylaş — şimdilik "Yakında"). Alt gezinme çubuğu yoktur.
- 3x3 kategori grid'i: her kutu **sabit yükseklikte** (`mainAxisExtent`, `childAspectRatio` DEĞİL — bkz. [HISTORY.md](HISTORY.md) "Önemli uygulama notları"), iki gruba ayrılır:
  - **Üst grup** (dikey ortalanmış): ikon (56px tonlanmış daire) + kategori adı (kalın, 2 satıra kadar).
  - **Alt grup** (kutunun altına sabitlenmiş): yıldız satırı + durum metni.
- **Günlük**: aynı üst çubuk deseni + tarih seçici; 9 kategori bölümü aynı sırada, her biri gerçek Supabase verisiyle (yıldız + detay + not) veya "Bu kategoride bugün için kayıt yok." boş durumuyla.
- **Kayıt Ekle** diyalogları: her kategori için ayrı bir dosya (`lib/screens/entries/*.dart`), ortak desen: yıldız girişi + kategoriye özel alan(lar) + not + Kaydet/İptal. **Bu alanların kesin içeriği henüz taslak** — kullanıcı ayrıca belirleyecek.

## Bilinçli Kapsam Dışı Bırakmalar

Eski "Ana Sayfa" ekranındaki şu özellikler bu tasarımda **kullanıcı onayıyla** kaldırıldı, henüz başka bir yerde karşılığı yok:
- Sıvı/idrar hedef ayarı dialogu ve ilerleme çubukları
- "SIVI ALARMI" (3 saattir sıvı girilmedi) uyarı banner'ı
- Hasta profili düzenleme penceresi (kronik durumlar vb.)

Raporlar ekranı de henüz yapılmadı; üst çubuktaki "Geçmiş/Raporlar" ikonu şimdilik Günlük ekranına yönlendiriyor.
