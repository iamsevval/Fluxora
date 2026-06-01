# 🎓 EFC304 Mobil Uygulama Tasarımı ve Geliştirme Final Projesi
## 📱 Üniversite Topluluk Ajandası ve SQLite Tabanlı Eşgüdüm Sistemi

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

### Yerel SQLite Mimarisi
Projenin veritabanı motoru SQLite (`sqflite`) kütüphanesine dayanmaktadır. Uygulama veritabanı şeması son derece kapsamlı ve normalize edilmiştir:
- `users`: Kullanıcı hesapları, şifreler, birincil komiteler ve onboarding flag'leri.
- `events`: Atanan kişi, komite ve tamamlanma durumlarını tutan etkinlik/görev tablosu.
- `committee_items`: Markalar, içerik planları ve katılım takipleri için esnek veri yapısı.
- `sponsorship_packages`: Gelişmiş sponsorluk paket detayları tablosu.
- `reels_drafts`: Reels video taslak parametreleri ve viral skorları tablosu.
- `stream_questions`: Canlı yayın soru havuzu tablosu.
- `event_duties`: Organizasyon günü görev matrisi tablosu.
- `announcements`: Kampüs elçisi duyuruları tablosu.
- `app_settings`: Kullanıcı tema (Dark/Light Mode) tercihlerini saklayan ayarlar tablosu.

---

## 🔑 Hızlı Başlangıç & Test Hesapları

Uygulamanın veri dolu ve çalışır vaziyette test edilebilmesi için veritabanına otomatik olarak tohumlanmış (seeded) varsayılan kullanıcılar ve örnek kayıtlar eklenmiştir:

| Rol | Kullanıcı Adı | Şifre | Erişim Yetkisi |
| :--- | :--- | :--- | :--- |
| **Kampüs Elçisi (Lider)** | `elci` | `elci12345` | Global Liderlik Portalı, Duyuru Yayını, Tüm Görevler |
| **Etkinlik Üyesi** | `etkinlik` | `etkinlik123` | Etkinlik & Organizasyon Komitesi Özel Sayfası |
| **Sponsorluk Üyesi** | `sponsorluk` | `sponsorluk123` | Sponsorluk & İş Geliştirme Komitesi Özel Sayfası |

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
