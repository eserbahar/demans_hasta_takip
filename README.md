# Demans Hasta Takip

Bu proje, demans hastası için günlük bakım, ilaç takibi ve sıvı/idrara ilişkin takip işlemlerini kolaylaştırmak amacıyla geliştirilmiş bir Flutter mobil uygulamasıdır.

## Proje Hakkında

Uygulama şu an için tek ekranlı bir bakım takibi kontrol paneli olarak çalışmaktadır. Hasta profili, ilaç takibi, günlük sıvı hedefleri, idrar takibi ve aktivite logları gibi temel işlevleri içermektedir.

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

## Çalıştırma

Proje klasöründe aşağıdaki komutları çalıştırın:

```bash
flutter pub get
flutter run
```

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

test/
  widget_test.dart
```

## Durum

Bu sürüm bir işlevsel prototype olarak hazırdır. Uygulama, bakım takibi için temel ekran ve iş akışlarını kapsamaktadır; ileri safhalarda ek ekranlar, veri kaydı, bildirimler ve kişiselleştirilmiş raporlar eklenebilir.

## Lisans

Bu proje için lisans bilgisi eklenmemiştir. İstendiğinde uygun lisans dosyası eklenebilir.
