# 📱 Üniversite Topluluk Ajandası Mobil Uygulaması

Bu proje, üniversite öğrenci topluluklarının iç koordinasyonunu, komite yönetimini, görev dağılımlarını ve zirve organizasyonlarını tek bir merkezden sürdürülebilir kılmak amacıyla geliştirilmiş, **tamamen yerel (native) ve veri kalıcılığına sahip bir mobil ajanda uygulamasıdır.** 

Akademik proje kriterlerine tam uyum sağlamak üzere, harici hiçbir bulut servisi veya karmaşık state management kütüphanesi kullanılmamış; tüm veri yönetimi ve iş mantığı **Flutter & SQLite (`sqflite`)** mimarisi üzerine inşa edilmiştir.

---

## 🚀 Öne Çıkan Gelişmiş Özellikler

### 1. Kampüs Elçisi (Liderlik) Portalı
* **Global Genel Bakış (Overview):** Giriş yapan kullanıcının rolü "Kampüs Elçisi" veya "Kampüs Elçisi Yardımcısı" ise, tüm komitelerin genel durumunu gösteren grafiksel liderlik paneli açılır.
* **Grafiksel Takip:** Her komitenin toplam görev sayısı, tamamlanan görev sayısı ve yüzde bazlı başarı oranları `LinearProgressIndicator` ve özel görsel tasarımlarla canlı olarak izlenir.
* **Etkileşimli Filtreleme:** Lider panosundaki komite özet kartlarına dokunulduğunda, sistem otomatik olarak Görevler sekmesine geçer ve ilgili komiteyi filtreler.
* **Merkezi Görev Havuzu:** Tüm komitelere ait görevlerin tek ekranda listelendiği, arama motorlu ve komite filtreli gelişmiş görev paneli.

### 2. Kişiye Özel Görev Atama Sistemi
* **Dinamik Üye Listesi:** Görev ekleme (`AddEventScreen`) ve düzenleme (`EditEventScreen`) ekranlarına SQLite veritabanındaki tüm üyeleri dinamik olarak çeken bir üye dropdown listesi (`DbHelper.getAllUsers()`) entegre edilmiştir.
* **Görsel Atama Kartları:** Oluşturulan görevlerin kime atandığı (`assignedTo`) görev kartlarının altında profil ikonlu çiplerle şık bir şekilde gösterilir.

### 3. Hedefli Duyuru Dağıtım Sistemi
* **Duyuru Yönetim Paneli:** Kampüs Elçisi, topluluk geneline ("Tüm Komiteler") veya belirli bir komiteye özel (Örn: "Sponsorluk & İş Geliştirme") zengin içerikli duyurular yayınlayabilir ve bunları silebilir.
* **Kişiye Özel Duyuru Panosu:** Komite üyeleri kendi panellerine girdiğinde, ana ekranın en üstünde yalnızca kendi komitelerini veya tüm kulübü ilgilendiren güncel duyuruların kaydığı horizontal (yatay) bir elçi duyuruları panosuyla karşılaşırlar.

### 4. Zirve & Etkinlik Katılım Takip Sistemi (Tam CRUD)
* **Çoklu Takip Kartları:** Zirve ve etkinlikler için dinamik katılım takip kartları oluşturulabilir.
* **Canlı İlerleme Çubukları:** Kayıtlı katılımcı sayısı ile hedef maksimum kapasite girildiğinde doluluk oranları ve ilerleme barları otomatik hesaplanır.
* **Katı Doğrulama (Validation):** Kayıtlı katılımcı sayısının negatif olması, maksimum kapasiteden büyük olması veya kapasitenin sıfır/altında girilmesi sistem tarafından engellenir ve kullanıcıya SnackBar uyarısı gösterilir.
* **Etkinlik Bitti (Silme) Seçeneği:** Başarıyla tamamlanan etkinlikler düzenleme menüsünden kalıcı olarak silinebilir.

### 5. Gelişmiş Komite Özel Araçları
Uygulama, her komitenin özgün ihtiyaçlarına göre tasarlanmış akıllı araçlar içerir:
* **Sponsorluk & İş Geliştirme:**
  * *Sponsorluk Paket Hesaplayıcısı:* Bütçe limitleri, sosyal medya paylaşımları, stant alanları ve logo konumlarına göre dinamik fiyat hesaplayan CRUD destekli paket simülatörü.
  * *Marka Görüşme Listesi:* Potansiyel sponsor firmaların görüşme durumlarını takip eden veri kartları.
* **Dijital Medya & Tasarım:**
  * *Reels Taslak Skorlama Motoru:* Trend müzik kullanımı, video süresi ve kanca (hook) gücüne göre Reels videolarının viral potansiyelini (Viral Score) puanlayan akıllı algoritma.
  * *Haftalık İçerik Takvimi:* Günlere göre paylaşılacak görsellerin durum kartları.
* **Medium & YouTube (Yayıncılık):**
  * *Canlı Yayın Soru Havuzu:* Yayın konuklarına sorulacak soruları öncelik sırasına göre derleyen ve soruldu olarak işaretleyen etkileşimli havuz.
  * *YouTube Geri Sayım Sayacı:* Planlanan canlı yayın saatine kalan süreyi saniye bazında canlı geri sayan sayaç motoru.
* **Etkinlik & Organizasyon:**
  * *Zirve Görev Matrisi:* Etkinlik günü ekibin hangi saat diliminde hangi alanda (Karşılama, Ses, Sahne arkası vb.) görevli olduğunu gösteren görev matrisi.
  * *Organizasyon İhtiyaçları:* Etkinlik malzemeleri ve kontrol listesi yönetim kartı.

---

## 🛠️ Teknik Altyapı ve Veri Kalıcılığı

### 📂 1. Proje Mimarisi ve Dosya Yapısı
Uygulama, Flutter geliştirme standartlarına uygun olarak Clean Architecture (Temiz Mimari) prensipleri doğrultusunda modüler bir yapıya sahiptir. Projede kodların okunabilirliğini ve bakımını kolaylaştırmak için veri modelleri, veritabanı katmanı ve kullanıcı arayüzü (UI) tamamen birbirinden ayrılmıştır.

```
lib/
│
├── main.dart                      # Uygulamanın giriş noktası (Giriş kontrolü ve Tema yükleme)
│
├── database/
│   └── db_helper.dart             # SQLite veritabanı bağlantısı, şema kurulumu ve CRUD metotları
│
├── models/                        # SQLite tabloları için Dart veri modelleri (Serialization)
│   ├── announcement_model.dart    # Duyuru veri modeli
│   ├── committee_item_model.dart  # Genel komite araçları modeli (Marka, Zirve kapasitesi vb.)
│   ├── event_duty_model.dart      # Görev matrisi (Zaman/Alan dağılımı) modeli
│   ├── event_model.dart           # Görev/Etkinlik veri modeli
│   ├── reels_draft_model.dart     # Reels video taslağı ve viral skor modeli
│   ├── sponsorship_package_model.dart # Sponsorluk paketi veri modeli
│   ├── stream_question_model.dart # Canlı yayın soru havuzu modeli
│   └── user_model.dart            # Kullanıcı ve rol modeli
│
└── screens/                       # Arayüz (Görsel Tasarım) ekranları
    ├── splash_screen.dart         # Karşılama ve yönlendirme ekranı
    ├── login_screen.dart          # Kullanıcı giriş ekranı (SQLite doğrulamalı)
    ├── register_screen.dart       # Yeni üye kayıt ekranı (SQLite entegrasyonlu)
    ├── home_screen.dart           # Ana ekran (Lider paneli, komite sekmeleri ve özel araçlar)
    ├── committee_selection_screen.dart # İlk giriş sonrası komite seçimi ve yönlendirme ekranı
    ├── add_event_screen.dart      # SQLite dinamik üye seçimli yeni görev ekleme ekranı
    └── edit_event_screen.dart     # SQLite dinamik üye seçimli görev düzenleme ve silme ekranı
```

### 🗄️ 2. SQLite Veritabanı Mimarisi (`db_helper.dart`)
Uygulamanın kalbini SQLite tabanlı `DbHelper` sınıfı oluşturur. Bu sınıf **Singleton Tasarım Deseni (Singleton Pattern)** kullanılarak yazılmıştır. Bu sayede uygulama genelinde veritabanına tek bir bağlantı kanalı açılır, gereksiz bellek tüketiminin ve veritabanı kilitlenmelerinin önüne geçilir.

#### Veritabanı Tablo Şemaları

| Tablo Adı | Görevi / Kolonları | Kritik Detaylar |
| :--- | :--- | :--- |
| **`users`** | `id`, `fullName`, `username` (UNIQUE), `password`, `primaryCommittee`, `isNewUser` | Kullanıcı kimlik doğrulama ve onboarding durumu. |
| **`events`** | `id`, `title`, `date`, `location`, `description`, `committee`, `isCompleted`, `assignedTo` | Komite içi görevler. `assignedTo` kolonu ile `users` tablosundaki bir üyeye dinamik atama yapılır. |
| **`announcements`** | `id`, `title`, `content`, `date`, `targetCommittee`, `isCompleted` | Kampüs Elçisinin yayınladığı duyurular. |
| **`committee_items`** | `id`, `committee`, `type`, `title`, `subtitle`, `statusColor`, `isDone` | Komitelere özel dinamik veri takipleri (Marka görüşmeleri, bütçe takipleri, zirve doluluk durumu). |
| **`sponsorship_packages`**| `id`, `packageName`, `budgetLimit`, `socialMediaPosts`, `logoBanner`, `standArea`, `totalPrice` | Sponsorluk Paket Hesaplayıcısının CRUD verileri. |
| **`reels_drafts`** | `id`, `concept`, `duration`, `isTrendingMusic`, `hookStrength`, `calculatedViralScore`, `recommendations` | Reels Taslak Motorunun kaydettiği video verileri ve hesaplanan viral skorları. |
| **`stream_questions`** | `id`, `guestName`, `questioner`, `questionText`, `isAsked`, `priority` | Canlı yayın soru havuzu verileri. |
| **`event_duties`** | `id`, `staffName`, `dutyZone`, `timeSlot`, `status` | Zirve görev matrisindeki ekip görevleri. |
| **`app_settings`** | `id` (PRIMARY KEY 1), `isDarkMode` (0 veya 1), `themeColor` | SQLite destekli kalıcı tema ayarları. |

#### Veritabanı Yaşam Döngüsü (Lifecycle) Metotları
- **`initDb()`:** Veritabanı dosyasını (`topluluk_v14.db`) cihaz hafızasında oluşturur veya var olan dosyaya bağlanır.
- **`onCreate()`:** Veritabanı ilk kez oluşturulurken yukarıdaki 9 tabloyu SQL sorgularıyla kurar ve Seed Verileri (varsayılan kullanıcı `elci`, örnek duyurular, görev matrisi, taslak reels vb.) ekler. Hoca uygulamayı ilk açtığında boş ekran görmez, dolu ve çalışan bir sistemle karşılaşır.
- **`onUpgrade()`:** İleride veritabanı şemasında güncelleme veya kolon ekleme gerektiğinde verileri kaybetmeden şemayı günceller.

---

## 🔑 Hızlı Başlangıç & Test Hesapları

Uygulamanın veri dolu ve çalışır vaziyette test edilebilmesi için veritabanına otomatik olarak tohumlanmış (seeded) varsayılan kullanıcılar ve örnek kayıtlar eklenmiştir:

| Rol | Kullanıcı Adı | Şifre | Erişim Yetkisi |
| :--- | :--- | :--- | :--- |
| **Kampüs Elçisi (Lider)** | `elci` | `elci12345` | Global Liderlik Portalı, Duyuru Yayını, Tüm Görevler |
| **Dijital Medya & Tasarım** | `tasarim_uyesi1` | `1tasarim123` | Tasarım Araçları ve Reels Taslakları Paneli |
| **Medium & YouTube** | `medium_uyesi1` | `1medium123` | Yayıncılık ve Canlı Yayın Soruları Havuzu |
| **Sponsorluk & İş Geliştirme** | `sponsorluk_uyesi` | `1sponsorluk123` | Sponsorluk Paket Hesaplayıcısı ve Marka Görüşmeleri |
| **Etkinlik & Organizasyon** | `etkinlik_uyesi` | `1etkinlik123` | Zirve Görev Matrisi ve Organizasyon Yönetimi |

---

## 💻 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK (v3.0.0 veya üzeri)
- Android Studio / VS Code
- Android veya iOS Simülatörü ya da fiziksel test cihazı

### Çalıştırma Adımları
1. Proje dizinine gidin:
   ```bash
   cd Fluxora
   ```
2. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
3. Uygulamayı başlatın:
   ```bash
   flutter run
   ```

### Testleri Çalıştırma
Uygulama içindeki regex veri doğrulama mantığını test etmek için hazırlanan birim testlerini koşturabilirsiniz:
```bash
flutter test
```

---

## 🎨 Tasarım Estetiği ve Kullanıcı Deneyimi
- **Tema Entegrasyonu:** SQLite destekli persistent Dark Mode / Light Mode geçişi.
- **Renk Paletleri:** Her komite için özel HSL tonlarında tanımlanmış premium ve dinamik komite temaları.
- **Ergonomi:** İlgili veri ekleme butonları, sayfa genelindeki dağınıklığı önlemek adına doğrudan ilişkili widget başlıklarına (Örn: "Organizasyon İhtiyaçları" ve "Katılım Takibi" başlıklarının yanına) taşınarak sezgisellik artırılmıştır.
