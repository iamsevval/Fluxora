import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/committee_item_model.dart';
import '../models/sponsorship_package_model.dart';
import '../models/reels_draft_model.dart';
import '../models/stream_question_model.dart';
import '../models/event_duty_model.dart';
import '../models/announcement_model.dart'; // Yeni duyuru modeli eklendi

class DbHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    // Sürüm yükseltmesi ve dinamik zirve silme özellikleri için topluluk_v9.db kullanıyoruz
    String path = join(await getDatabasesPath(), 'topluluk_v9.db');
    return await openDatabase(
      path, 
      version: 7, 
      onCreate: (db, version) async {
        // 1. Etkinlikler Tablosu (assignedTo eklendi)
        await db.execute('''
          CREATE TABLE events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            date TEXT,
            location TEXT,
            description TEXT,
            committee TEXT,
            isCompleted INTEGER DEFAULT 0,
            assignedTo TEXT
          )
        ''');

        // 2. Kullanıcılar Tablosu (Genişletilmiş)
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fullName TEXT,
            username TEXT UNIQUE,
            password TEXT,
            primaryCommittee TEXT,
            isNewUser INTEGER DEFAULT 1
          )
        ''');

        // 3. Komite Özel Araçlar Tablosu (Eski Tablo)
        await db.execute('''
          CREATE TABLE committee_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            committee TEXT,
            type TEXT,
            title TEXT,
            subtitle TEXT,
            statusColor TEXT,
            isDone INTEGER DEFAULT 0
          )
        ''');

        // 4. Yeni İleri Seviye Sponsorluk Paket Tablosu
        await db.execute('''
          CREATE TABLE sponsorship_packages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            packageName TEXT,
            budgetLimit REAL,
            socialMediaPosts INTEGER,
            logoBanner INTEGER,
            standArea INTEGER,
            totalPrice REAL
          )
        ''');

        // 5. Yeni İleri Seviye Reels Taslak Tablosu
        await db.execute('''
          CREATE TABLE reels_drafts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            concept TEXT,
            duration INTEGER,
            isTrendingMusic INTEGER,
            hookStrength TEXT,
            calculatedViralScore INTEGER,
            recommendations TEXT
          )
        ''');

        // 6. Yeni İleri Seviye Soru Havuzu Tablosu
        await db.execute('''
          CREATE TABLE stream_questions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            guestName TEXT,
            questioner TEXT,
            questionText TEXT,
            isAsked INTEGER DEFAULT 0,
            priority TEXT
          )
        ''');

        // 7. Yeni İleri Seviye Zirve Görev Dağılım Tablosu
        await db.execute('''
          CREATE TABLE event_duties(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            staffName TEXT,
            dutyZone TEXT,
            timeSlot TEXT,
            status TEXT
          )
        ''');

        // 8. Uygulama Tema Ayarlar Tablosu
        await db.execute('''
          CREATE TABLE app_settings(
            id INTEGER PRIMARY KEY,
            isDarkMode INTEGER DEFAULT 0,
            themeColor TEXT
          )
        ''');

        // 9. Yeni Elçi Duyuruları Tablosu
        await db.execute('''
          CREATE TABLE announcements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            date TEXT,
            targetCommittee TEXT,
            isCompleted INTEGER DEFAULT 0
          )
        ''');

        // --- SEED VERİLERİ (İLK AÇILIŞ ÖRNEKLERİ) ---
        // Uygulama Ayarları İlkleme
        await db.insert('app_settings', {
          'id': 1,
          'isDarkMode': 0,
          'themeColor': '0xFF3949AB',
        });

        // Kampüs Elçisi (Lider) seeding
        await db.insert('users', {
          'fullName': 'Kampüs Elçisi (Lider)',
          'username': 'elci',
          'password': 'elci12345',
          'primaryCommittee': 'Kampüs Elçisi',
          'isNewUser': 0,
        });

        // Örnek Elçi Duyuruları seeding
        await db.insert('announcements', {
          'title': 'Haftalık Eşgüdüm Toplantısı',
          'content': 'Tüm komite üyelerinin katılımıyla Pazar günü saat 20:00\'de Discord kanalımızda genel durum değerlendirme toplantısı yapılacaktır.',
          'date': '2026-06-02',
          'targetCommittee': 'Tüm Komiteler',
        });
        await db.insert('announcements', {
          'title': 'Sponsorluk Hedef Güncellemesi',
          'content': 'Sponsorluk görüşmelerinde taban paket bütçemizi ₺20,000 seviyesine çektik. Lütfen güncel paket hesaplayıcısını kullanın.',
          'date': '2026-06-01',
          'targetCommittee': 'Sponsorluk & İş Geliştirme',
        });

        // Temel Komite Araçları Seeding
        await db.insert('committee_items', {
          'committee': 'Sponsorluk & İş Geliştirme',
          'type': 'brand',
          'title': 'X Markası',
          'subtitle': 'Görüşülüyor',
          'statusColor': '0xFFFF9800',
          'isDone': 0,
        });
        await db.insert('committee_items', {
          'committee': 'Sponsorluk & İş Geliştirme',
          'type': 'brand',
          'title': 'Y Şirketi',
          'subtitle': 'Onaylandı',
          'statusColor': '0xFF4CAF50',
          'isDone': 0,
        });

        await db.insert('committee_items', {
          'committee': 'Dijital Medya & Tasarım',
          'type': 'content',
          'title': 'Pazartesi',
          'subtitle': 'Motivasyon Postu',
          'statusColor': '0xFFE91E63',
          'isDone': 0,
        });

        await db.insert('committee_items', {
          'committee': 'Medium & YouTube',
          'type': 'youtube',
          'title': 'Tech Echo Zirvesi Canlı Yayını',
          'subtitle': '2026-06-08 19:30:00',
          'statusColor': '0xFFF44336',
          'isDone': 0,
        });

        await db.insert('committee_items', {
          'committee': 'Etkinlik & Organizasyon',
          'type': 'checklist',
          'title': 'Yaka Kartları Basımı',
          'subtitle': 'Acil',
          'statusColor': '0xFFFF9800',
          'isDone': 1,
        });

        // Dynamic Summit Capacity Seeding (Only created once on DB creation, so user can safely delete it)
        await db.insert('committee_items', {
          'committee': 'Etkinlik & Organizasyon',
          'type': 'summit_capacity',
          'title': 'Tech Echo Zirve Katılımı',
          'subtitle': '380/500',
          'statusColor': '0xFFFF9800',
          'isDone': 0,
        });

        // 1. Sponsorluk Paket Seeding
        await db.insert('sponsorship_packages', {
          'packageName': 'Teknoloji Sponsorluğu',
          'budgetLimit': 25000.0,
          'socialMediaPosts': 4,
          'logoBanner': 1,
          'standArea': 0,
          'totalPrice': 37000.0
        });

        // 2. Reels Taslak Seeding
        await db.insert('reels_drafts', {
          'concept': 'Bir Yazılımcının 1 Günü',
          'duration': 14,
          'isTrendingMusic': 1,
          'hookStrength': 'Yüksek',
          'calculatedViralScore': 90,
          'recommendations': 'Mükemmel planlama! Süre 15 saniyenin altında ve trend müzik seçilmiş.'
        });

        // 3. Canlı Yayın Soru Seeding
        await db.insert('stream_questions', {
          'guestName': 'Konuk: Ahmet Yılmaz',
          'questioner': 'Berke Ş.',
          'questionText': 'Flutter Impeller performansı Android cihazlarda şu an ne durumda?',
          'isAsked': 0,
          'priority': 'Yüksek'
        });

        // 4. Görev Matrisi Seeding
        await db.insert('event_duties', {
          'staffName': 'Şevval Arslan',
          'dutyZone': 'Karşılama',
          'timeSlot': '09:00 - 12:00',
          'status': 'Görevde'
        });
        await db.insert('event_duties', {
          'staffName': 'Ahmet K.',
          'dutyZone': 'Ses Kontrol',
          'timeSlot': '12:00 - 15:00',
          'status': 'Molada'
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Upgrade işlemleri
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE events ADD COLUMN isCompleted INTEGER DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE committee_items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              committee TEXT,
              type TEXT,
              title TEXT,
              subtitle TEXT,
              statusColor TEXT,
              isDone INTEGER DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  // --- KULLANICI (AUTH) İŞLEMLERİ ---

  Future<int> registerUser(User user) async {
    var dbClient = await db;
    return await dbClient.insert('users', user.toMap());
  }

  Future<User?> loginUser(String username, String password) async {
    var dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<bool> checkUserExists(String username) async {
    var dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  Future<int> updateUserOnboarded(int userId) async {
    var dbClient = await db;
    return await dbClient.update(
      'users',
      {'isNewUser': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int userId) async {
    var dbClient = await db;
    return await dbClient.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // --- ETKİNLİK İŞLEMLERİ ---

  Future<int> insertEvent(Event event) async {
    var dbClient = await db;
    return await dbClient.insert('events', event.toMap());
  }

  Future<List<Event>> getEventsByCommittee(String committee) async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      'events',
      where: 'committee = ?',
      whereArgs: [committee],
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<int> updateEvent(Event event) async {
    var dbClient = await db;
    return await dbClient.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- KOMİTE ÖZEL ARAÇ İŞLEMLERİ (Eski Tablo) ---

  Future<int> insertCommitteeItem(CommitteeItem item) async {
    var dbClient = await db;
    return await dbClient.insert('committee_items', item.toMap());
  }

  Future<List<CommitteeItem>> getCommitteeItems(String committee, String type) async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      'committee_items',
      where: 'committee = ? AND type = ?',
      whereArgs: [committee, type],
    );
    return List.generate(maps.length, (i) => CommitteeItem.fromMap(maps[i]));
  }

  Future<int> updateCommitteeItem(CommitteeItem item) async {
    var dbClient = await db;
    return await dbClient.update(
      'committee_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteCommitteeItem(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'committee_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- 1. SPONSORLUK PAKET CRUD İŞLEMLERİ ---

  Future<int> insertSponsorshipPackage(SponsorshipPackage package) async {
    var dbClient = await db;
    return await dbClient.insert('sponsorship_packages', package.toMap());
  }

  Future<List<SponsorshipPackage>> getSponsorshipPackages() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('sponsorship_packages');
    return List.generate(maps.length, (i) => SponsorshipPackage.fromMap(maps[i]));
  }

  Future<int> deleteSponsorshipPackage(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'sponsorship_packages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSponsorshipPackage(SponsorshipPackage package) async {
    var dbClient = await db;
    return await dbClient.update(
      'sponsorship_packages',
      package.toMap(),
      where: 'id = ?',
      whereArgs: [package.id],
    );
  }

  // --- 2. REELS DRAFT CRUD İŞLEMLERİ ---

  Future<int> insertReelsDraft(ReelsDraft draft) async {
    var dbClient = await db;
    return await dbClient.insert('reels_drafts', draft.toMap());
  }

  Future<List<ReelsDraft>> getReelsDrafts() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('reels_drafts');
    return List.generate(maps.length, (i) => ReelsDraft.fromMap(maps[i]));
  }

  Future<int> deleteReelsDraft(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'reels_drafts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateReelsDraft(ReelsDraft draft) async {
    var dbClient = await db;
    return await dbClient.update(
      'reels_drafts',
      draft.toMap(),
      where: 'id = ?',
      whereArgs: [draft.id],
    );
  }

  // --- 3. STREAM QUESTION CRUD İŞLEMLERİ ---

  Future<int> insertStreamQuestion(StreamQuestion question) async {
    var dbClient = await db;
    return await dbClient.insert('stream_questions', question.toMap());
  }

  Future<List<StreamQuestion>> getStreamQuestions() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('stream_questions');
    return List.generate(maps.length, (i) => StreamQuestion.fromMap(maps[i]));
  }

  Future<int> updateStreamQuestion(StreamQuestion question) async {
    var dbClient = await db;
    return await dbClient.update(
      'stream_questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> deleteStreamQuestion(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'stream_questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- 4. EVENT DUTY CRUD İŞLEMLERİ ---

  Future<int> insertEventDuty(EventDuty duty) async {
    var dbClient = await db;
    return await dbClient.insert('event_duties', duty.toMap());
  }

  Future<List<EventDuty>> getEventDuties() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('event_duties');
    return List.generate(maps.length, (i) => EventDuty.fromMap(maps[i]));
  }

  Future<int> updateEventDuty(EventDuty duty) async {
    var dbClient = await db;
    return await dbClient.update(
      'event_duties',
      duty.toMap(),
      where: 'id = ?',
      whereArgs: [duty.id],
    );
  }

  Future<int> deleteEventDuty(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'event_duties',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- 5. TEMA VE AYARLAR İŞLEMLERİ ---

  Future<Map<String, dynamic>?> getAppSettings() async {
    var dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.query('app_settings', where: 'id = 1');
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> updateAppSettings(int isDarkMode, String themeColor) async {
    var dbClient = await db;
    return await dbClient.update(
      'app_settings',
      {
        'isDarkMode': isDarkMode,
        'themeColor': themeColor,
      },
      where: 'id = 1',
    );
  }

  // --- 6. DUYURU VE ORTAK ELÇİ İŞLEMLERİ ---

  Future<int> insertAnnouncement(Announcement announcement) async {
    var dbClient = await db;
    return await dbClient.insert('announcements', announcement.toMap());
  }

  Future<List<Announcement>> getAnnouncementsForCommittee(String committeeName) async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      'announcements',
      where: 'targetCommittee = ? OR targetCommittee = ?',
      whereArgs: [committeeName, 'Tüm Komiteler'],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Announcement.fromMap(maps[i]));
  }

  Future<List<Announcement>> getAllAnnouncements() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('announcements', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Announcement.fromMap(maps[i]));
  }

  Future<int> deleteAnnouncement(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'announcements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateAnnouncement(Announcement announcement) async {
    var dbClient = await db;
    return await dbClient.update(
      'announcements',
      announcement.toMap(),
      where: 'id = ?',
      whereArgs: [announcement.id],
    );
  }

  Future<List<User>> getAllUsers() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<List<Event>> getAllEvents() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('events');
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }
}