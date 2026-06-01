import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama eklendi
import '../database/db_helper.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/committee_item_model.dart';
import '../models/sponsorship_package_model.dart';
import '../models/reels_draft_model.dart';
import '../models/stream_question_model.dart';
import '../models/event_duty_model.dart';
import '../models/announcement_model.dart'; // Duyuru modeli eklendi
import 'add_event_screen.dart';
import 'edit_event_screen.dart';
import 'login_screen.dart';
import 'committee_selection_screen.dart'; // Komitelere göz atmak için eklendi

// --- CUSTOM PAINTER PROGRESS RING ---
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  ProgressRingPainter({required this.progress, required this.color, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background Ring - Ekstra kompakt halka için kalınlık ve konum ayarlandı
    final bgPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.08 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius - 3, bgPaint);

    // Progress Arc - Ekstra kompakt halka için kalınlık ve konum ayarlandı
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
      
    final rect = Rect.fromCircle(center: center, radius: radius - 3);
    canvas.drawArc(
      rect,
      -3.14159265 / 2, // Start at the top
      2 * 3.14159265 * progress, // Sweep angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}

class HomeScreen extends StatefulWidget {
  final User user;
  final String committeeName;
  final String committeeDetail;
  final Color committeeColor;
  final IconData committeeIcon;

  const HomeScreen({
    super.key,
    required this.user,
    required this.committeeName,
    required this.committeeDetail,
    required this.committeeColor,
    required this.committeeIcon,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Event> _events = [];

  bool get _isLeadDashboard => (widget.user.primaryCommittee == 'Kampüs Elçisi' || widget.user.primaryCommittee == 'Kampüs Elçisi Yardımcısı') && (widget.committeeName == 'Kampüs Elçisi' || widget.committeeName == 'Kampüs Elçisi Yardımcısı');

  // --- DUYURU VE ELÇİ VERİLERİ ---
  List<Announcement> _announcements = []; // Komite veya tüm duyurular listesi
  List<Event> _allEvents = []; // Tüm komitelerin etkinlikleri (Elçi için)
  String _selectedLeadCommitteeFilter = 'Tüm Komiteler'; // Elçi filtreleme seçeneği
  
  // --- KOMİTE ÖZEL ARAÇ VERİLERİ (SQLite) ---
  List<CommitteeItem> _committeeBrands = [];
  List<CommitteeItem> _committeeContents = [];
  List<CommitteeItem> _committeeYoutube = [];
  List<CommitteeItem> _committeeChecklist = [];
  List<CommitteeItem> _committeeCapacities = [];

  // --- İLERİ SEVİYE YARATICI ARAÇ VERİLERİ (SQLite) ---
  List<SponsorshipPackage> _packages = [];
  List<ReelsDraft> _drafts = [];
  List<StreamQuestion> _streamQuestions = [];
  List<EventDuty> _duties = [];

  int _selectedIndex = 0; // 0: Ana Sayfa, 1: Görevler, 2: Profil
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  // --- SİSTEM AYARLARI ---
  bool _isDarkMode = false;
  final TextEditingController _searchController = TextEditingController();

  // --- DUYURU FORM KONTROLLERİ ---
  final TextEditingController _annTitleController = TextEditingController();
  final TextEditingController _annContentController = TextEditingController();
  String _selectedAnnTarget = 'Tüm Komiteler';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _refreshEvents();
    _refreshCommitteeItems();
    _searchController.addListener(() {
      setState(() {}); 
    });

    // --- YENİ KAYIT ONBOARDING TETİKLEYİCİSİ ---
    if (widget.user.isNewUser == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOnboardingDialog();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
    _annTitleController.dispose();
    _annContentController.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final settings = await _dbHelper.getAppSettings();
    if (settings != null && mounted) {
      setState(() {
        _isDarkMode = settings['isDarkMode'] == 1;
      });
    }
  }

  void _toggleTheme() async {
    final newMode = _isDarkMode ? 0 : 1;
    await _dbHelper.updateAppSettings(newMode, '0xFF3949AB');
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _refreshEvents() async {
    if (_isLeadDashboard) {
      final allEvents = await _dbHelper.getAllEvents();
      final announcements = await _dbHelper.getAllAnnouncements();
      if (mounted) {
        setState(() {
          _allEvents = allEvents;
          _announcements = announcements;
        });
      }
    } else {
      final events = await _dbHelper.getEventsByCommittee(widget.committeeName);
      final announcements = await _dbHelper.getAnnouncementsForCommittee(widget.committeeName);
      if (mounted) {
        setState(() {
          _events = events;
          _announcements = announcements;
        });
      }
    }
  }

  void _refreshCommitteeItems() async {
    final brands = await _dbHelper.getCommitteeItems(widget.committeeName, 'brand');
    final contents = await _dbHelper.getCommitteeItems(widget.committeeName, 'content');
    final youtube = await _dbHelper.getCommitteeItems(widget.committeeName, 'youtube');
    final checklist = await _dbHelper.getCommitteeItems(widget.committeeName, 'checklist');
    
    var capacity = await _dbHelper.getCommitteeItems(widget.committeeName, 'summit_capacity');

    final packages = await _dbHelper.getSponsorshipPackages();
    final drafts = await _dbHelper.getReelsDrafts();
    final questions = await _dbHelper.getStreamQuestions();
    final duties = await _dbHelper.getEventDuties();

    if (mounted) {
      setState(() {
        _committeeBrands = brands;
        _committeeContents = contents;
        _committeeYoutube = youtube;
        _committeeChecklist = checklist;
        _committeeCapacities = capacity;
        _packages = packages;
        _drafts = drafts;
        _streamQuestions = questions;
        _duties = duties;
      });
      if (youtube.isNotEmpty) {
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_committeeYoutube.isNotEmpty && mounted) {
        try {
          final targetDate = DateTime.parse(_committeeYoutube.first.subtitle);
          final diff = targetDate.difference(DateTime.now());
          setState(() {
            _remainingTime = diff.isNegative ? Duration.zero : diff;
          });
        } catch (_) {
          setState(() {
            _remainingTime = Duration.zero;
          });
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _refreshCommitteeItems();
    }
    _refreshEvents();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- YOL GÖSTERİCİ REHBER DIALOGU (ONBOARDING) ---
  void _showOnboardingDialog() {
    final textColor = _isDarkMode ? Colors.white70 : Colors.black87;
    final textSubColor = _isDarkMode ? Colors.white60 : Colors.black54;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            Icon(Icons.school, color: widget.committeeColor, size: 28),
            const SizedBox(width: 10),
            const Expanded(child: Text('Kulüp Yol Gösterici Kılavuzu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: widget.committeeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hoş Geldiniz, ${widget.user.fullName}!\nBirincil Komiteniz: ${widget.user.primaryCommittee ?? "Sponsorluk & İş Geliştirme"}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text('Komitelerimiz ve Sorumlu Görevleri:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const SizedBox(height: 12),
                _buildGuideBullet('💼 Sponsorluk & İş Geliştirme:', 'Markalar ve işletmelerle sponsorluk anlaşmaları kurar, bütçe paketleri tasarlar ve başarı durumunu takip eder.', textSubColor),
                _buildGuideBullet('🎨 Dijital Medya & Tasarım:', 'Sosyal medya hesaplarını yönetir, haftalık içerik takvimi hazırlar ve Reels Viral Simülatörü ile tahminler yapar.', textSubColor),
                _buildGuideBullet('💡 Medium & YouTube Canlı Yayın:', 'Blog yazıları kaleme alır, canlı yayın moderasyonu yapar ve izleyici Q&A soru havuzunu yönetir.', textSubColor),
                _buildGuideBullet('🎉 Etkinlik & Organizasyon:', 'Zirve (Tech Echo) ve online toplantılar düzenler, kontrol checklistlerini yönetir ve Ekip Görev Matrisi ile personelleri koordine eder.', textSubColor),
                const Divider(height: 30),
                const Text(
                  'Önemli Kural: Her üye sadece 1 birincil komiteye ait olabilir ancak profil sekmesindeki "Komitelere Göz At" butonuyla diğer komitelerin panellerine erişip oralara yeni görevler atayabilir.',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                )
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.committeeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (widget.user.isNewUser == 1) {
                await _dbHelper.updateUserOnboarded(widget.user.id!);
                setState(() {
                  widget.user.isNewUser = 0;
                });
              }
            },
            child: const Text('Rehberi Okudum, Başla', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildGuideBullet(String title, String desc, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: widget.committeeColor)),
          const SizedBox(height: 3),
          Text(desc, style: TextStyle(fontSize: 12, color: subColor, height: 1.3)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF121212) : Colors.grey[50];
    final appBarColor = _isDarkMode ? const Color(0xFF1E1E1E) : widget.committeeColor;
    final cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _isLeadDashboard 
              ? (widget.user.primaryCommittee == 'Kampüs Elçisi' 
                  ? 'Kampüs Elçisi Liderlik Portalı' 
                  : 'Kampüs Elçisi Yrd. Portalı')
              : widget.committeeName, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildBody(cardColor),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: cardColor,
            selectedItemColor: widget.committeeColor,
            unselectedItemColor: _isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: _isLeadDashboard
                ? const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Genel Bakış'),
                    BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task_alt), label: 'Tüm Görevler'),
                    BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign), label: 'Duyurular'),
                    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
                  ]
                : const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Ana Sayfa'),
                    BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task_alt), label: 'Görevler'),
                    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
                  ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton(
              backgroundColor: widget.committeeColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEventScreen(
                      selectedCommittee: _isLeadDashboard 
                          ? (widget.user.primaryCommittee ?? 'Kampüs Elçisi') 
                          : widget.committeeName
                    ),
                  ),
                );
                _refreshEvents();
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildBody(Color cardColor) {
    if (_isLeadDashboard) {
      switch (_selectedIndex) {
        case 0:
          return _buildLeadOverviewTab(cardColor);
        case 1:
          return _buildLeadTasksTab(cardColor);
        case 2:
          return _buildLeadAnnouncementsTab(cardColor);
        case 3:
          return _buildProfileTab(cardColor);
        default:
          return _buildLeadOverviewTab(cardColor);
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return _buildOverviewTab(cardColor);
        case 1:
          return _buildTasksTab(cardColor);
        case 2:
          return _buildProfileTab(cardColor);
        default:
          return _buildOverviewTab(cardColor);
      }
    }
  }

  Widget _buildOverviewTab(Color cardColor) {
    int totalTasks = _events.length;
    int completedTasks = _events.where((e) => e.isCompleted == 1).length;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KAMPÜS ELÇİSİ DUYURU PANOSU ---
          if (_announcements.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode
                      ? [const Color(0xFF1A237E), const Color(0xFF283593)]
                      : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDarkMode ? const Color(0xFF303F9F) : const Color(0xFF9FA8DA),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: Color(0xFF3949AB), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Elçi Duyuruları',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : const Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90, // Duyuru listesi için yükseklik
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _announcements.length,
                      itemBuilder: (context, idx) {
                        final ann = _announcements[idx];
                        return Opacity(
                          opacity: ann.isCompleted == 1 ? 0.6 : 1.0,
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? const Color(0xFF212121) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ann.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 13,
                                          decoration: ann.isCompleted == 1 ? TextDecoration.lineThrough : null,
                                          color: ann.isCompleted == 1 ? Colors.grey : (_isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () async {
                                        ann.isCompleted = ann.isCompleted == 1 ? 0 : 1;
                                        await _dbHelper.updateAnnouncement(ann);
                                        _refreshEvents();
                                      },
                                      child: Icon(
                                        ann.isCompleted == 1 ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: ann.isCompleted == 1 ? Colors.green : Colors.grey.shade400,
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      ann.date,
                                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    ann.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      decoration: ann.isCompleted == 1 ? TextDecoration.lineThrough : null,
                                      color: ann.isCompleted == 1 
                                          ? Colors.grey.shade500 
                                          : (_isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Vizyon Kartı (Hero Animasyonu ile)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.committeeColor, widget.committeeColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: widget.committeeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Hero(
                  tag: 'committee_${widget.committeeName}',
                  child: Material(
                    color: Colors.transparent,
                    child: Icon(widget.committeeIcon, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Komite Vizyonu',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.committeeDetail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          
          // İstatistikler (Dinamik CustomPainter Grafik Dahil)
          Text(
            'İstatistikler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildStatCardMini('Toplam Görev', totalTasks.toString(), Icons.assignment, cardColor),
                    const SizedBox(height: 12),
                    _buildStatCardMini('Tamamlanan', completedTasks.toString(), Icons.check_circle_outline, cardColor),
                  ],
                ),
              ),
              const SizedBox(width: 25),
              // CustomPainter Çizimi ile Animasyonlu Ring (Ekstra kompakt saran boyut)
              SizedBox(
                width: 65,
                height: 65,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: totalTasks == 0 ? 0.0 : completedTasks / totalTasks),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: ProgressRingPainter(progress: value, color: widget.committeeColor, isDark: _isDarkMode),
                      child: Center(
                        child: Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12, // Ekstra küçük halkaya tam oturup bitişik durması için 12 olarak ayarlandı
                            fontWeight: FontWeight.bold,
                            color: widget.committeeColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 30),

          // KOMİTEYE ÖZEL DİNAMİK VE YARATICI ARAÇLAR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Özel Araçlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              _buildAddButtonForTools(),
            ],
          ),
          const SizedBox(height: 15),
          _buildCommitteeSpecificWidgets(cardColor),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCardMini(String title, String count, IconData icon, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: widget.committeeColor),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.committeeColor)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddButtonForTools() {
    if (widget.committeeName.contains('Medium') || widget.committeeName.contains('Etkinlik')) return const SizedBox(); 

    return IconButton(
      icon: Icon(Icons.add_circle, color: widget.committeeColor, size: 30),
      onPressed: () {
        if (widget.committeeName.contains('Sponsorluk')) {
          _showAddBrandDialog();
        } else if (widget.committeeName.contains('Dijital Medya')) {
          _showAddContentDialog();
        }
      },
    );
  }

  // --- KOMİTEYE ÖZEL WIDGET YÖNLENDİRİCİ ---
  Widget _buildCommitteeSpecificWidgets(Color cardColor) {
    if (widget.committeeName.contains('Sponsorluk')) {
      return _buildSponsorshipWidgets(cardColor);
    } else if (widget.committeeName.contains('Dijital Medya')) {
      return _buildMediaWidgets(cardColor);
    } else if (widget.committeeName.contains('Medium')) {
      return _buildYoutubeWidgets(cardColor);
    } else if (widget.committeeName.contains('Etkinlik')) {
      return _buildEventWidgets(cardColor);
    }
    return const SizedBox();
  }

  // 1. GELİŞMİŞ SPONSORLUK BÖLÜMÜ
  Widget _buildSponsorshipWidgets(Color cardColor) {
    double completedRatio = 0.0;
    if (_committeeBrands.isNotEmpty) {
      int approved = _committeeBrands.where((b) => b.subtitle == 'Onaylandı').length;
      completedRatio = approved / _committeeBrands.length;
    }
    final textColor = _isDarkMode ? Colors.white : Colors.black87;

    return Column(
      children: [
        // Marka Görüşmeleri Listesi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.handshake, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 10),
                  Text('Aktif Marka Görüşmeleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Durumu değiştirmek için tıklayın, silmek için basılı tutun.', style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 15),
              _committeeBrands.isEmpty
                  ? const Center(child: Text('Henüz marka eklenmemiş.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _committeeBrands.length,
                        itemBuilder: (context, index) {
                          final item = _committeeBrands[index];
                          final colorVal = int.tryParse(item.statusColor) ?? 0xFF9E9E9E;
                          return GestureDetector(
                            onTap: () => _toggleBrandStatus(item),
                            onLongPress: () => _deleteCommitteeItemConfirm(item),
                            child: Container(
                              width: 125,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: _isDarkMode ? Colors.transparent : Colors.grey.shade200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(colorVal).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.subtitle,
                                      style: TextStyle(color: Color(colorVal), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
            ],
          ),
        ),
        const SizedBox(height: 15),
        // Hedef İlerleme Barı
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Row(
            children: [
              SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(
                  value: completedRatio,
                  color: const Color(0xFF4CAF50),
                  backgroundColor: _isDarkMode ? Colors.grey.shade900 : const Color(0xFFE8F5E9),
                  strokeWidth: 7,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sponsorluk Başarı Hedefi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                    const SizedBox(height: 5),
                    Text(
                      '%${(completedRatio * 100).toInt()} Onaylanmış Sponsor Oranı',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        // ---------------- YARATICI ÖZELLİK: SPONSORLUK BÜTÇE/PAKET HESAPLAYICI ----------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Text('Sponsorluk Paket Hesaplayıcı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                    onPressed: _showSponsorshipPackageWizard,
                  )
                ],
              ),
              const SizedBox(height: 5),
              const Text('Kendi özel sponsorluk paketinizi tasarlayın ve kaydedin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 25),
              _packages.isEmpty
                  ? const Center(child: Text('Kaydedilmiş özel paket bulunmuyor.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _packages.length,
                      itemBuilder: (context, index) {
                        final pkg = _packages[index];
                        return Card(
                          color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.blue.shade50.withOpacity(0.3),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(pkg.packageName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                            subtitle: Text(
                              'Taban: ₺${pkg.budgetLimit.toInt()} | Paylaşım: ${pkg.socialMediaPosts} | Logo: ${pkg.logoBanner == 1 ? "Var" : "Yok"} | Stant: ${pkg.standArea == 1 ? "Var" : "Yok"}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            trailing: Text(
                              '₺${pkg.totalPrice.toInt()}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: widget.committeeColor, fontSize: 15),
                            ),
                            onTap: () => _showEditSponsorshipPackageWizard(pkg),
                            onLongPress: () => _deleteSponsorshipPackageConfirm(pkg),
                          ),
                        );
                      },
                    )
            ],
          ),
        ),
      ],
    );
  }

  void _toggleBrandStatus(CommitteeItem item) async {
    String newStatus;
    String newColor;
    if (item.subtitle == 'Görüşülüyor') {
      newStatus = 'Onaylandı';
      newColor = '0xFF4CAF50'; 
    } else if (item.subtitle == 'Onaylandı') {
      newStatus = 'Beklemede';
      newColor = '0xFF9E9E9E'; 
    } else {
      newStatus = 'Görüşülüyor';
      newColor = '0xFFFF9800'; 
    }
    item.subtitle = newStatus;
    item.statusColor = newColor;
    await _dbHelper.updateCommitteeItem(item);
    _refreshCommitteeItems();
  }

  void _showAddBrandDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Marka Görüşmesi Ekle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Görüşülen Marka Adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.committeeColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newItem = CommitteeItem(
                  committee: widget.committeeName,
                  type: 'brand',
                  title: controller.text.trim(),
                  subtitle: 'Görüşülüyor',
                  statusColor: '0xFFFF9800',
                );
                await _dbHelper.insertCommitteeItem(newItem);
                _refreshCommitteeItems();
                if (mounted) Navigator.pop(context);
              } else {
                _showErrorSnackBar('Marka adı boş bırakılamaz.');
              }
            },
            child: const Text('Ekle'),
          )
        ],
      ),
    );
  }

  void _showSponsorshipPackageWizard() {
    final nameController = TextEditingController();
    double budgetLimit = 15000.0;
    int socialMediaPosts = 2;
    bool logoBanner = true;
    bool standArea = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double totalPrice = budgetLimit + (socialMediaPosts * 2500) + (logoBanner ? 5000 : 0) + (standArea ? 10000 : 0);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sponsorluk Paket Tasarlayıcı'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Paket Adı (Örn: Gümüş Paket)'),
                  ),
                  const SizedBox(height: 15),
                  Text('Taban Bütçe Limiti: ₺${budgetLimit.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Slider(
                    value: budgetLimit,
                    min: 5000,
                    max: 100000,
                    divisions: 19,
                    activeColor: widget.committeeColor,
                    onChanged: (val) {
                      setDialogState(() => budgetLimit = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Sosyal Medya Post Paylaşımı: $socialMediaPosts Adet', style: const TextStyle(fontSize: 13)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: socialMediaPosts > 0 ? () => setDialogState(() => socialMediaPosts--) : null,
                      ),
                      Text('$socialMediaPosts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: socialMediaPosts < 10 ? () => setDialogState(() => socialMediaPosts++) : null,
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text('Afiş/Banner Logo Görseli', style: TextStyle(fontSize: 13)),
                    value: logoBanner,
                    activeColor: widget.committeeColor,
                    onChanged: (val) => setDialogState(() => logoBanner = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Zirve Alanı Stant Alanı Kurulumu', style: TextStyle(fontSize: 13)),
                    value: standArea,
                    activeColor: widget.committeeColor,
                    onChanged: (val) => setDialogState(() => standArea = val!),
                  ),
                  const Divider(),
                  const SizedBox(height: 5),
                  Text(
                    'Hesaplanan Değer: ₺${totalPrice.toInt()}',
                    style: TextStyle(color: widget.committeeColor, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.committeeColor, foregroundColor: Colors.white),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final newPkg = SponsorshipPackage(
                      packageName: name,
                      budgetLimit: budgetLimit,
                      socialMediaPosts: socialMediaPosts,
                      logoBanner: logoBanner ? 1 : 0,
                      standArea: standArea ? 1 : 0,
                      totalPrice: totalPrice,
                    );
                    await _dbHelper.insertSponsorshipPackage(newPkg);
                    _refreshCommitteeItems();
                    if (mounted) Navigator.pop(context);
                  } else {
                    _showErrorSnackBar('Paket adı boş geçilemez.');
                  }
                },
                child: const Text('Kaydet'),
              )
            ],
          );
        },
      ),
    );
  }

  void _showEditSponsorshipPackageWizard(SponsorshipPackage pkg) {
    final nameController = TextEditingController(text: pkg.packageName);
    double budgetLimit = pkg.budgetLimit;
    int socialMediaPosts = pkg.socialMediaPosts;
    bool logoBanner = pkg.logoBanner == 1;
    bool standArea = pkg.standArea == 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double totalPrice = budgetLimit + (socialMediaPosts * 2500) + (logoBanner ? 5000 : 0) + (standArea ? 10000 : 0);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sponsorluk Paketini Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Paket Adı (Örn: Gümüş Paket)'),
                  ),
                  const SizedBox(height: 15),
                  Text('Taban Bütçe Limiti: ₺${budgetLimit.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Slider(
                    value: budgetLimit,
                    min: 5000,
                    max: 100000,
                    divisions: 19,
                    activeColor: widget.committeeColor,
                    onChanged: (val) {
                      setDialogState(() => budgetLimit = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Sosyal Medya Post Paylaşımı: $socialMediaPosts Adet', style: const TextStyle(fontSize: 13)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: socialMediaPosts > 0 ? () => setDialogState(() => socialMediaPosts--) : null,
                      ),
                      Text('$socialMediaPosts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: socialMediaPosts < 10 ? () => setDialogState(() => socialMediaPosts++) : null,
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text('Afiş/Banner Logo Görseli', style: TextStyle(fontSize: 13)),
                    value: logoBanner,
                    activeColor: widget.committeeColor,
                    onChanged: (val) => setDialogState(() => logoBanner = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Zirve Alanı Stant Alanı Kurulumu', style: TextStyle(fontSize: 13)),
                    value: standArea,
                    activeColor: widget.committeeColor,
                    onChanged: (val) => setDialogState(() => standArea = val!),
                  ),
                  const Divider(),
                  const SizedBox(height: 5),
                  Text(
                    'Hesaplanan Değer: ₺${totalPrice.toInt()}',
                    style: TextStyle(color: widget.committeeColor, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.committeeColor, foregroundColor: Colors.white),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    pkg.packageName = name;
                    pkg.budgetLimit = budgetLimit;
                    pkg.socialMediaPosts = socialMediaPosts;
                    pkg.logoBanner = logoBanner ? 1 : 0;
                    pkg.standArea = standArea ? 1 : 0;
                    pkg.totalPrice = totalPrice;
                    
                    await _dbHelper.updateSponsorshipPackage(pkg);
                    _refreshCommitteeItems();
                    if (mounted) Navigator.pop(context);
                  } else {
                    _showErrorSnackBar('Paket adı boş geçilemez.');
                  }
                },
                child: const Text('Güncelle'),
              )
            ],
          );
        },
      ),
    );
  }

  void _deleteSponsorshipPackageConfirm(SponsorshipPackage pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Paketi Sil'),
        content: Text('"${pkg.packageName}" özel bütçe paketini kalıcı olarak silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _dbHelper.deleteSponsorshipPackage(pkg.id!);
              _refreshCommitteeItems();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sil'),
          )
        ],
      ),
    );
  }

  // 2. GELİŞMİŞ DİJİTAL MEDYA BÖLÜMÜ
  Widget _buildMediaWidgets(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;

    return Column(
      children: [
        // İçerik Takvimi
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFFE91E63)),
                  const SizedBox(width: 10),
                  Text('Haftalık İçerik Takvimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Silmek için içeriğe basılı tutabilirsiniz.', style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 15),
              _committeeContents.isEmpty
                  ? const Center(child: Text('Henüz içerik planlanmamış.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _committeeContents.length,
                      itemBuilder: (context, index) {
                        final item = _committeeContents[index];
                        IconData contentIcon = Icons.image;
                        if (item.subtitle.toLowerCase().contains('reels') || item.subtitle.toLowerCase().contains('video')) {
                          contentIcon = Icons.video_collection;
                        } else if (item.subtitle.toLowerCase().contains('story')) {
                          contentIcon = Icons.amp_stories;
                        }
                        
                        return GestureDetector(
                          onTap: () => _showEditContentDialog(item),
                          onLongPress: () => _deleteCommitteeItemConfirm(item),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 90,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(contentIcon, size: 16, color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.subtitle,
                                    style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey.shade800, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        // ---------------- YARATICI ÖZELLİK: REELS VİRAL SKOR TAHMİNCİSİ ----------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.amber),
                      const SizedBox(width: 10),
                      Text('Reels Viral Skor Tahmincisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_chart, color: Colors.amber),
                    onPressed: _showReelsDraftWizard,
                  )
                ],
              ),
              const SizedBox(height: 5),
              const Text('Reels kurgunuzun viral performansını tahmin edin ve taslak olarak kaydedin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 25),
              _drafts.isEmpty
                  ? const Center(child: Text('Henüz planlanmış Reels taslağı yok.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _drafts.length,
                      itemBuilder: (context, index) {
                        final draft = _drafts[index];
                        Color progressColor = Colors.redAccent;
                        if (draft.calculatedViralScore >= 75) {
                          progressColor = Colors.green;
                        } else if (draft.calculatedViralScore >= 50) {
                          progressColor = Colors.orange;
                        }

                        return Card(
                          color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.amber.shade50.withOpacity(0.2),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        draft.concept,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'Skor: %${draft.calculatedViralScore}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: progressColor),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Süre: ${draft.duration} sn | Müzik: ${draft.isTrendingMusic == 1 ? "Trend" : "Normal"} | Hook: ${draft.hookStrength}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Colors.black26 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.tips_and_updates, size: 16, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          draft.recommendations,
                                          style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.white60 : Colors.black54),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showEditReelsDraftWizard(draft),
                                      child: const Text('Düzenle', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _deleteReelsDraftConfirm(draft),
                                      child: const Text('Sil', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    )
            ],
          ),
        ),
      ],
    );
  }

  void _showAddContentDialog() {
    final dayController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yeni İçerik Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dayController,
              decoration: const InputDecoration(labelText: 'Planlanan Gün (Örn: Salı)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Paylaşım Konusu / Türü'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.committeeColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (dayController.text.trim().isNotEmpty && contentController.text.trim().isNotEmpty) {
                final newItem = CommitteeItem(
                  committee: widget.committeeName,
                  type: 'content',
                  title: dayController.text.trim(),
                  subtitle: contentController.text.trim(),
                  statusColor: '0xFFE91E63',
                );
                await _dbHelper.insertCommitteeItem(newItem);
                _refreshCommitteeItems();
                if (mounted) Navigator.pop(context);
              } else {
                _showErrorSnackBar('Lütfen tüm alanları doldurun.');
              }
            },
            child: const Text('Ekle'),
          )
        ],
      ),
    );
  }

  void _showEditContentDialog(CommitteeItem item) {
    final dayController = TextEditingController(text: item.title);
    final contentController = TextEditingController(text: item.subtitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İçerik Planını Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dayController,
              decoration: const InputDecoration(labelText: 'Planlanan Gün (Örn: Salı)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Paylaşım Konusu / Türü'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.committeeColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (dayController.text.trim().isNotEmpty && contentController.text.trim().isNotEmpty) {
                item.title = dayController.text.trim();
                item.subtitle = contentController.text.trim();
                await _dbHelper.updateCommitteeItem(item);
                _refreshCommitteeItems();
                if (mounted) Navigator.pop(context);
              } else {
                _showErrorSnackBar('Lütfen tüm alanları doldurun.');
              }
            },
            child: const Text('Güncelle'),
          )
        ],
      ),
    );
  }

  void _showReelsDraftWizard() {
    final conceptController = TextEditingController();
    int duration = 12;
    bool isTrendingMusic = true;
    String hookStrength = 'Orta';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int score = 0;
          if (duration <= 15) {
            score += 40;
          } else if (duration <= 30) {
            score += 20;
          } else {
            score += 5;
          }

          if (isTrendingMusic) score += 20;

          if (hookStrength == 'Yüksek') {
            score += 40;
          } else if (hookStrength == 'Orta') {
            score += 20;
          } else {
            score += 5;
          }

          String recs = 'Mükemmel planlama! Skorunuz yüksek.';
          if (duration > 15) {
            recs = 'Tavsiye: Reels süresini 15 saniyenin altına çekerek izlenme tamamlama oranını artırın.';
          } else if (!isTrendingMusic) {
            recs = 'Tavsiye: Keşfet etkileşimi yakalamak için mutlaka güncel bir Trend ses ekleyin.';
          } else if (hookStrength != 'Yüksek') {
            recs = 'Tavsiye: Giriş saniyesine (Hook) daha vurucu bir metin veya görsel ekleyin.';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Reels Viral Simülatör'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: conceptController,
                    decoration: const InputDecoration(labelText: 'Reels Konsepti (Örn: Tech Zirve Duyurusu)'),
                  ),
                  const SizedBox(height: 15),
                  Text('Video Süresi: $duration Saniye', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: Colors.amber,
                    onChanged: (val) {
                      setDialogState(() => duration = val.toInt());
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Trend Müzik / Ses', style: TextStyle(fontSize: 13)),
                    value: isTrendingMusic,
                    activeColor: Colors.amber,
                    onChanged: (val) => setDialogState(() => isTrendingMusic = val),
                  ),
                  DropdownButtonFormField<String>(
                    value: hookStrength,
                    decoration: const InputDecoration(labelText: 'Giriş Hook Gücü (İlk 3 sn)'),
                    items: ['Düşük', 'Orta', 'Yüksek']
                        .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => hookStrength = val!),
                  ),
                  const Divider(),
                  Text(
                    'Tahmini Viral Gücü: %$score',
                    style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                onPressed: () async {
                  final concept = conceptController.text.trim();
                  if (concept.isNotEmpty) {
                    final newDraft = ReelsDraft(
                      concept: concept,
                      duration: duration,
                      isTrendingMusic: isTrendingMusic ? 1 : 0,
                      hookStrength: hookStrength,
                      calculatedViralScore: score,
                      recommendations: recs,
                    );
                    await _dbHelper.insertReelsDraft(newDraft);
                    _refreshCommitteeItems();
                    if (mounted) Navigator.pop(context);
                  } else {
                    _showErrorSnackBar('Lütfen Reels konseptini girin.');
                  }
                },
                child: const Text('Taslağı Kaydet'),
              )
            ],
          );
        },
      ),
    );
  }

  void _showEditReelsDraftWizard(ReelsDraft draft) {
    final conceptController = TextEditingController(text: draft.concept);
    int duration = draft.duration;
    bool isTrendingMusic = draft.isTrendingMusic == 1;
    String hookStrength = draft.hookStrength;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int score = 0;
          if (duration <= 15) {
            score += 40;
          } else if (duration <= 30) {
            score += 20;
          } else {
            score += 5;
          }

          if (isTrendingMusic) score += 20;

          if (hookStrength == 'Yüksek') {
            score += 40;
          } else if (hookStrength == 'Orta') {
            score += 20;
          } else {
            score += 5;
          }

          String recs = 'Mükemmel planlama! Skorunuz yüksek.';
          if (duration > 15) {
            recs = 'Tavsiye: Reels süresini 15 saniyenin altına çekerek izlenme tamamlama oranını artırın.';
          } else if (!isTrendingMusic) {
            recs = 'Tavsiye: Keşfet etkileşimi yakalamak için mutlaka güncel bir Trend ses ekleyin.';
          } else if (hookStrength != 'Yüksek') {
            recs = 'Tavsiye: Giriş saniyesine (Hook) daha vurucu bir metin veya görsel ekleyin.';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Reels Viral Simülatörünü Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: conceptController,
                    decoration: const InputDecoration(labelText: 'Reels Konsepti (Örn: Tech Zirve Duyurusu)'),
                  ),
                  const SizedBox(height: 15),
                  Text('Video Süresi: $duration Saniye', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: Colors.amber,
                    onChanged: (val) {
                      setDialogState(() => duration = val.toInt());
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Trend Müzik / Ses', style: TextStyle(fontSize: 13)),
                    value: isTrendingMusic,
                    activeColor: Colors.amber,
                    onChanged: (val) => setDialogState(() => isTrendingMusic = val),
                  ),
                  DropdownButtonFormField<String>(
                    value: hookStrength,
                    decoration: const InputDecoration(labelText: 'Giriş Hook Gücü (İlk 3 sn)'),
                    items: ['Düşük', 'Orta', 'Yüksek']
                        .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => hookStrength = val!),
                  ),
                  const Divider(),
                  Text(
                    'Tahmini Viral Gücü: %$score',
                    style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                onPressed: () async {
                  final concept = conceptController.text.trim();
                  if (concept.isNotEmpty) {
                    draft.concept = concept;
                    draft.duration = duration;
                    draft.isTrendingMusic = isTrendingMusic ? 1 : 0;
                    draft.hookStrength = hookStrength;
                    draft.calculatedViralScore = score;
                    draft.recommendations = recs;

                    await _dbHelper.updateReelsDraft(draft);
                    _refreshCommitteeItems();
                    if (mounted) Navigator.pop(context);
                  } else {
                    _showErrorSnackBar('Lütfen Reels konseptini girin.');
                  }
                },
                child: const Text('Güncelle'),
              )
            ],
          );
        },
      ),
    );
  }

  void _deleteReelsDraftConfirm(ReelsDraft draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Taslağı Sil'),
        content: Text('"${draft.concept}" Reels taslağını silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _dbHelper.deleteReelsDraft(draft.id!);
              _refreshCommitteeItems();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sil'),
          )
        ],
      ),
    );
  }

  // 3. GELİŞMİŞ MEDIUM & YOUTUBE CANLI YAYIN BÖLÜMÜ
  Widget _buildYoutubeWidgets(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    String streamTitle = 'Tanımlanmamış Canlı Yayın';
    String timeDisplay = '00 GÜN : 00 SAAT : 00 DAK';
    
    if (_committeeYoutube.isNotEmpty) {
      final stream = _committeeYoutube.first;
      streamTitle = stream.title;
      
      final days = _remainingTime.inDays.toString().padLeft(2, '0');
      final hours = (_remainingTime.inHours % 24).toString().padLeft(2, '0');
      final minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
      
      timeDisplay = '$days GÜN : $hours SAAT : $minutes DAK';
    }

    return Column(
      children: [
        // Canlı Yayın Sayacı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF44336),
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFC62828)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFFF44336).withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.live_tv, color: Colors.white, size: 28),
                  Row(
                    children: [
                      if (_committeeYoutube.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                          onPressed: _deleteCountdownConfirm,
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _showEditYoutubeDialog,
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 2),
              const Text('Sıradaki Canlı Yayın Geri Sayımı', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                streamTitle,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                child: Text(
                  timeDisplay,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _committeeYoutube.isNotEmpty ? 'Hedef Tarih: ${_committeeYoutube.first.subtitle}' : 'Hedef Tarih Belirlenmedi',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              )
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        // ---------------- YARATICI ÖZELLİK: CANLI YAYIN SORU HAVUZU VE MODERATÖRÜ ----------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.question_answer, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Text('Canlı Yayın Soru Havuzu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_comment, color: Colors.redAccent),
                    onPressed: _showAddStreamQuestionDialog,
                  )
                ],
              ),
              const SizedBox(height: 5),
              const Text('Konuklara sorulmak üzere chatten gelen soruları düzenleyin (Sorulanları işaretleyin).', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 25),
              _streamQuestions.isEmpty
                  ? const Center(child: Text('Soru havuzu boş.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _streamQuestions.length,
                      itemBuilder: (context, index) {
                        final question = _streamQuestions[index];
                        final isAsked = question.isAsked == 1;
                        return Card(
                          color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.red.shade50.withOpacity(0.2),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Checkbox(
                              value: isAsked,
                              activeColor: Colors.redAccent,
                              onChanged: (val) async {
                                question.isAsked = val == true ? 1 : 0;
                                await _dbHelper.updateStreamQuestion(question);
                                _refreshCommitteeItems();
                              },
                            ),
                            title: Text(
                              question.questionText,
                              style: TextStyle(
                                fontSize: 13,
                                color: isAsked ? Colors.grey : textColor,
                                decoration: isAsked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              'Gönderen: ${question.questioner} | ${question.guestName}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            trailing: Text(
                              question.priority,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: question.priority == 'Yüksek' ? Colors.red : Colors.grey,
                              ),
                            ),
                            onLongPress: () => _deleteStreamQuestionConfirm(question),
                          ),
                        );
                      },
                    )
            ],
          ),
        ),
      ],
    );
  }

  void _deleteCountdownConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Geri Sayımı Sıfırla / Sil'),
        content: const Text('Aktif canlı yayın geri sayımını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (_committeeYoutube.isNotEmpty) {
                await _dbHelper.deleteCommitteeItem(_committeeYoutube.first.id!);
                _countdownTimer?.cancel();
                _refreshCommitteeItems();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sil/Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _showAddCapacityDialog() {
    final titleController = TextEditingController();
    final regController = TextEditingController(text: '0');
    final capController = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yeni Katılım Takibi Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Etkinlik / Organizasyon Adı',
                  hintText: 'Örn: Tech Echo Zirve Katılımı',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: regController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kayıtlı Katılımcı Sayısı'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: capController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maksimum Kapasite'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.committeeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = titleController.text.trim();
              final reg = int.tryParse(regController.text.trim());
              final cap = int.tryParse(capController.text.trim());
              if (name.isEmpty) {
                _showErrorSnackBar('Etkinlik adı boş bırakılamaz.');
                return;
              }
              if (reg == null || reg < 0) {
                _showErrorSnackBar('Kayıtlı katılımcı sayısı geçerli bir pozitif sayı olmalıdır.');
                return;
              }
              if (cap == null || cap <= 0) {
                _showErrorSnackBar('Maksimum kapasite 0\'dan büyük bir sayı olmalıdır.');
                return;
              }
              if (reg > cap) {
                _showErrorSnackBar('Kayıtlı katılımcı sayısı maksimum kapasiteden büyük olamaz.');
                return;
              }

              final newItem = CommitteeItem(
                committee: widget.committeeName,
                type: 'summit_capacity',
                title: name,
                subtitle: '$reg/$cap',
                statusColor: '0xFFFF9800',
              );
              await _dbHelper.insertCommitteeItem(newItem);
              _refreshCommitteeItems();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Ekle'),
          )
        ],
      ),
    );
  }

  void _showEditCapacityDialog(CommitteeItem item) {
    final titleController = TextEditingController(text: item.title);
    final parts = item.subtitle.split('/');
    final initialReg = parts.isNotEmpty ? parts[0] : '0';
    final initialCap = parts.length > 1 ? parts[1] : '100';
    
    final regController = TextEditingController(text: initialReg);
    final capController = TextEditingController(text: initialCap);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Katılım Takibini Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Etkinlik / Organizasyon Adı'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: regController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kayıtlı Katılımcı Sayısı'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: capController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maksimum Kapasite'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Etkinliği Sil'),
                  content: const Text('Bu etkinlik katılım takibini sonlandırıp silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      onPressed: () async {
                        await _dbHelper.deleteCommitteeItem(item.id!);
                        _refreshCommitteeItems();
                        if (mounted) {
                          Navigator.pop(context); // Close confirm
                          Navigator.pop(context); // Close edit dialog
                        }
                      },
                      child: const Text('Sil / Bitir'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.committeeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = titleController.text.trim();
              final reg = int.tryParse(regController.text.trim());
              final cap = int.tryParse(capController.text.trim());
              if (name.isEmpty) {
                _showErrorSnackBar('Etkinlik adı boş bırakılamaz.');
                return;
              }
              if (reg == null || reg < 0) {
                _showErrorSnackBar('Kayıtlı katılımcı sayısı geçerli bir pozitif sayı olmalıdır.');
                return;
              }
              if (cap == null || cap <= 0) {
                _showErrorSnackBar('Maksimum kapasite 0\'dan büyük bir sayı olmalıdır.');
                return;
              }
              if (reg > cap) {
                _showErrorSnackBar('Kayıtlı katılımcı sayısı maksimum kapasiteden büyük olamaz.');
                return;
              }

              item.title = name;
              item.subtitle = '$reg/$cap';
              await _dbHelper.updateCommitteeItem(item);
              _refreshCommitteeItems();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          )
        ],
      ),
    );
  }

  void _showEditYoutubeDialog() {
    final titleController = TextEditingController(text: _committeeYoutube.isEmpty ? 'Canlı Yayın Toplantısı' : _committeeYoutube.first.title);
    final dateController = TextEditingController(text: _committeeYoutube.isEmpty ? '2026-06-08 19:30:00' : _committeeYoutube.first.subtitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Canlı Yayın Planla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Yayın Konusu / Başlığı'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Tarih Saat (YYYY-MM-DD HH:MM:SS)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.committeeColor, foregroundColor: Colors.white),
            onPressed: () async {
              final title = titleController.text.trim();
              final dateStr = dateController.text.trim();
              if (title.isNotEmpty && dateStr.isNotEmpty) {
                try {
                  DateTime.parse(dateStr);
                  
                  if (_committeeYoutube.isNotEmpty) {
                    final item = _committeeYoutube.first;
                    item.title = title;
                    item.subtitle = dateStr;
                    await _dbHelper.updateCommitteeItem(item);
                  } else {
                    final newItem = CommitteeItem(
                      committee: widget.committeeName,
                      type: 'youtube',
                      title: title,
                      subtitle: dateStr,
                      statusColor: '0xFFF44336',
                    );
                    await _dbHelper.insertCommitteeItem(newItem);
                  }
                  _refreshCommitteeItems();
                  if (mounted) Navigator.pop(context);
                } catch (_) {
                  _showErrorSnackBar('Lütfen geçerli bir tarih formatı girin (Örn: 2026-06-08 19:30:00)');
                }
              } else {
                _showErrorSnackBar('Alanlar boş bırakılamaz.');
              }
            },
            child: const Text('Kaydet'),
          )
        ],
      ),
    );
  }

  void _showAddStreamQuestionDialog() {
    final guestController = TextEditingController(text: 'Canlı Yayın Konuğu');
    final questionerController = TextEditingController();
    final questionController = TextEditingController();
    String priority = 'Orta';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Soru Havuzuna Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: guestController,
                decoration: const InputDecoration(labelText: 'Konuşmacı/Konuk Adı'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: questionerController,
                decoration: const InputDecoration(labelText: 'Soruyu Soran Chat Adı'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(labelText: 'Konuğa Yöneltilecek Soru'),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: priority,
                items: ['Yüksek', 'Orta', 'Düşük'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setDialogState(() => priority = val!),
                decoration: const InputDecoration(labelText: 'Soru Öncelik Derecesi'),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                final qText = questionController.text.trim();
                final name = questionerController.text.trim();
                if (qText.isNotEmpty && name.isNotEmpty) {
                  final newQ = StreamQuestion(
                    guestName: guestController.text.trim(),
                    questioner: name,
                    questionText: qText,
                    isAsked: 0,
                    priority: priority,
                  );
                  await _dbHelper.insertStreamQuestion(newQ);
                  _refreshCommitteeItems();
                  if (mounted) Navigator.pop(context);
                } else {
                  _showErrorSnackBar('Lütfen chat adını ve soruyu girin.');
                }
              },
              child: const Text('Ekle'),
            )
          ],
        ),
      ),
    );
  }

  void _deleteStreamQuestionConfirm(StreamQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Soruyu Sil'),
        content: const Text('Bu soruyu soru havuzundan kalıcı olarak silmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _dbHelper.deleteStreamQuestion(question.id!);
              _refreshCommitteeItems();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sil'),
          )
        ],
      ),
    );
  }

  // 4. GELİŞMİŞ ETKİNLİK BÖLÜMÜ
  Widget _buildEventWidgets(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zirve & Etkinlik Katılım Takibi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF9800), size: 28),
              tooltip: 'Yeni Etkinlik Katılımı Ekle',
              onPressed: _showAddCapacityDialog,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_committeeCapacities.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'Henüz katılım takibi bulunmuyor.\nYeni bir etkinlik katılım takibi eklemek için yukarıdaki (+) butonuna dokunun.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ..._committeeCapacities.map((item) {
            final parts = item.subtitle.split('/');
            final reg = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
            final cap = parts.length > 1 ? (int.tryParse(parts[1]) ?? 100) : 100;
            final ratio = cap > 0 ? (reg / cap).clamp(0.0, 1.0) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map, color: Color(0xFFFF9800)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditCapacityDialog(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit, color: Colors.orange, size: 18),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kayıtlı Katılımcı Sayısı', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '$reg / $cap',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.orange.shade50,
                              color: Colors.orange,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => _showEditCapacityDialog(item),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.location_city, color: Colors.orange, size: 28),
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          }),
        const SizedBox(height: 15),
        
        // Acil İhtiyaç Kontrol Listesi
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Organizasyon İhtiyaçları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF9800), size: 24),
                    tooltip: 'Yeni İhtiyaç Ekle',
                    onPressed: _showAddChecklistDialog,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Tamamlamak için tıklayın, silmek için basılı tutun.', style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 12),
              _committeeChecklist.isEmpty
                  ? const Center(child: Text('Henüz ihtiyaç listesi eklenmemiş.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _committeeChecklist.length,
                      itemBuilder: (context, index) {
                        final item = _committeeChecklist[index];
                        final isDone = item.isDone == 1;
                        return GestureDetector(
                          onLongPress: () => _deleteCommitteeItemConfirm(item),
                          child: InkWell(
                            onTap: () async {
                              item.isDone = isDone ? 0 : 1;
                              await _dbHelper.updateCommitteeItem(item);
                              _refreshCommitteeItems();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  AnimatedScale(
                                    scale: isDone ? 1.0 : 0.95,
                                    duration: const Duration(milliseconds: 150),
                                    child: Icon(
                                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isDone ? Colors.green : Colors.grey,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                        color: isDone ? Colors.grey : textColor,
                                        fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.subtitle == 'Acil' 
                                          ? Colors.red.shade50 
                                          : (item.subtitle == 'Öncelikli' ? Colors.orange.shade50 : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.subtitle,
                                      style: TextStyle(
                                        color: item.subtitle == 'Acil' 
                                            ? Colors.red 
                                            : (item.subtitle == 'Öncelikli' ? Colors.orange : Colors.grey),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // ---------------- YARATICI ÖZELLİK: İNTERAKTİF EKİP GÖREV MATRİSİ ----------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt, color: Colors.deepOrange),
                      const SizedBox(width: 10),
                      Text('Ekip Görev Matrisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.deepOrange),
                    onPressed: _showAddDutyDialog,
                  )
                ],
              ),
              const SizedBox(height: 5),
              const Text('Tech Echo zirve günü alanlarındaki görev dağılımlarını anlık matristen izleyin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 25),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _buildZoneCard('Karşılama', Icons.door_front_door, Colors.green),
                  _buildZoneCard('Ses Kontrol', Icons.volume_up, Colors.blue),
                  _buildZoneCard('Sahne Arkası', Icons.theater_comedy, Colors.purple),
                  _buildZoneCard('İkram', Icons.coffee, Colors.orange),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildZoneCard(String zoneName, IconData icon, Color color) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    int count = _duties.where((d) => d.dutyZone == zoneName).length;
    return InkWell(
      onTap: () => _showZoneStaffDetails(zoneName),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF2C2C2C) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _isDarkMode ? Colors.transparent : color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(zoneName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count Görevli',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            )
          ],
        ),
      ),
    );
  }

  void _showZoneStaffDetails(String zoneName) {
    List<EventDuty> zoneStaff = _duties.where((d) => d.dutyZone == zoneName).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('$zoneName Bölgesi Görevlileri'),
          content: zoneStaff.isEmpty
              ? const SizedBox(
                  height: 60,
                  child: Center(child: Text('Bu bölgede henüz görevlendirilmiş biri bulunmuyor.', style: TextStyle(color: Colors.grey, fontSize: 12))),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: zoneStaff.length,
                    itemBuilder: (context, index) {
                      final staff = zoneStaff[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(staff.staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('Saat: ${staff.timeSlot}', style: const TextStyle(fontSize: 11)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: staff.status == 'Görevde' ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              staff.status,
                              style: TextStyle(
                                color: staff.status == 'Görevde' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          onLongPress: () async {
                            await _dbHelper.deleteEventDuty(staff.id!);
                            _refreshCommitteeItems();
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ],
        ),
      ),
    );
  }

  void _showAddDutyDialog() {
    final staffController = TextEditingController();
    String dutyZone = 'Karşılama';
    String timeSlot = '09:00 - 12:00';
    String status = 'Görevde';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Görev Matrisine Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: staffController,
                decoration: const InputDecoration(labelText: 'Görevli Ad Soyad'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: dutyZone,
                items: ['Karşılama', 'Ses Kontrol', 'Sahne Arkası', 'İkram']
                    .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                    .toList(),
                onChanged: (val) => setDialogState(() => dutyZone = val!),
                decoration: const InputDecoration(labelText: 'Görev Alanı'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: timeSlot,
                items: ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setDialogState(() => timeSlot = val!),
                decoration: const InputDecoration(labelText: 'Zaman Aralığı'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                items: ['Görevde', 'Molada']
                    .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                    .toList(),
                onChanged: (val) => setDialogState(() => status = val!),
                decoration: const InputDecoration(labelText: 'Mevcut Durum'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
              onPressed: () async {
                final name = staffController.text.trim();
                if (name.isNotEmpty) {
                  final newDuty = EventDuty(
                    staffName: name,
                    dutyZone: dutyZone,
                    timeSlot: timeSlot,
                    status: status,
                  );
                  await _dbHelper.insertEventDuty(newDuty);
                  _refreshCommitteeItems();
                  if (mounted) Navigator.pop(context);
                } else {
                  _showErrorSnackBar('Lütfen görevli ismini girin.');
                }
              },
              child: const Text('Ata'),
            )
          ],
        ),
      ),
    );
  }

  void _showAddChecklistDialog() {
    final controller = TextEditingController();
    String priority = 'Normal';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni İhtiyaç Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'İhtiyaç / Malzeme Adı'),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: priority,
                items: ['Acil', 'Öncelikli', 'Normal'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) {
                  setDialogState(() {
                    priority = val!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Öncelik Derecesi'),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.committeeColor, foregroundColor: Colors.white),
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  final newItem = CommitteeItem(
                    committee: widget.committeeName,
                    type: 'checklist',
                    title: controller.text.trim(),
                    subtitle: priority,
                    statusColor: '0xFFFF9800',
                  );
                  await _dbHelper.insertCommitteeItem(newItem);
                  _refreshCommitteeItems();
                  if (mounted) Navigator.pop(context);
                } else {
                  _showErrorSnackBar('İhtiyaç adı boş bırakılamaz.');
                }
              },
              child: const Text('Ekle'),
            )
          ],
        ),
      ),
    );
  }

  void _deleteCommitteeItemConfirm(CommitteeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Öğeyi Sil'),
        content: Text('"${item.title}" kaydını kalıcı olarak silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              await _dbHelper.deleteCommitteeItem(item.id!);
              _refreshCommitteeItems();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sil'),
          )
        ],
      ),
    );
  }

  // --- 2. GÖREVLER (TASKS) SEKMESİ ---
  Widget _buildTasksTab(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    
    final query = _searchController.text.toLowerCase().trim();
    final filteredEvents = _events.where((e) {
      return e.title.toLowerCase().contains(query) || e.location.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Arama Çubuğu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Görevlerde Ara...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: query.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                  : null,
              fillColor: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            ),
          ),
        ),
        
        Expanded(
          child: filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      Text(
                        'Eşleşen görev bulunamadı.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sağ alt köşeden yeni bir görev oluşturabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 5, bottom: 80, left: 16, right: 16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final isCompleted = event.isCompleted == 1;
                    return Card(
                      color: cardColor,
                      elevation: isCompleted ? 1 : 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
                          );
                          _refreshEvents();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isCompleted,
                                activeColor: widget.committeeColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (bool? value) async {
                                  event.isCompleted = value == true ? 1 : 0;
                                  await _dbHelper.updateEvent(event);
                                  _refreshEvents();
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 16, 
                                        color: isCompleted ? Colors.grey : textColor,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: isCompleted ? Colors.grey.shade400 : Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.date,
                                            style: TextStyle(
                                              color: isCompleted ? Colors.grey.shade400 : Colors.grey, 
                                              fontSize: 12,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: isCompleted ? Colors.grey.shade400 : Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location,
                                            style: TextStyle(
                                              color: isCompleted ? Colors.grey.shade400 : Colors.grey, 
                                              fontSize: 12,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (event.committee.isNotEmpty || (event.assignedTo != null && event.assignedTo!.isNotEmpty)) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: widget.committeeColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              event.committee,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: widget.committeeColor,
                                              ),
                                            ),
                                          ),
                                          if (event.assignedTo != null && event.assignedTo!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.person, size: 10, color: Colors.blue),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    event.assignedTo!,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 28),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Silmeyi Onayla'),
                                      content: Text('"${event.title}" görevini silmek istediğinize emin misiniz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context), 
                                          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await _dbHelper.deleteEvent(event.id!);
                                            _refreshEvents();
                                          },
                                          child: const Text('Sil'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- KAMPÜS ELÇİSİ LİDERLİK TAB METOTLARI ---

  Widget _buildLeadOverviewTab(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    int totalTasksGlobal = _allEvents.length;
    int completedTasksGlobal = _allEvents.where((e) => e.isCompleted == 1).length;
    int totalAnnouncements = _announcements.length;
    
    final List<Map<String, dynamic>> committeeSummaries = [
      {
        'name': 'Sponsorluk & İş Geliştirme',
        'icon': Icons.handshake,
        'color': const Color(0xFF4CAF50),
        'tasks': _allEvents.where((e) => e.committee == 'Sponsorluk & İş Geliştirme').toList(),
      },
      {
        'name': 'Dijital Medya & Tasarım',
        'icon': Icons.design_services,
        'color': const Color(0xFFE91E63),
        'tasks': _allEvents.where((e) => e.committee == 'Dijital Medya & Tasarım').toList(),
      },
      {
        'name': 'Medium & YouTube',
        'icon': Icons.video_camera_front,
        'color': const Color(0xFFF44336),
        'tasks': _allEvents.where((e) => e.committee == 'Medium & YouTube').toList(),
      },
      {
        'name': 'Etkinlik & Organizasyon',
        'icon': Icons.event_available,
        'color': const Color(0xFFFF9800),
        'tasks': _allEvents.where((e) => e.committee == 'Etkinlik & Organizasyon').toList(),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [const Color(0xFF1E265C), const Color(0xFF1F2937)]
                    : [const Color(0xFF3949AB), const Color(0xFF5C6BC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF3949AB).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Elçi Liderlik Paneli',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Topluluktaki tüm komite süreçlerini, duyuruları ve görev dağılımlarını tek bir merkezden koordine edin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          Text(
            'Genel İstatistikler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCardMini('Toplam', totalTasksGlobal.toString(), Icons.assignment, cardColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCardMini('Tamamlanan', completedTasksGlobal.toString(), Icons.check_circle_outline, cardColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCardMini('Duyurular', totalAnnouncements.toString(), Icons.campaign, cardColor),
              ),
            ],
          ),
          const SizedBox(height: 25),

          Text(
            'Komitelerin Durumu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemCount: committeeSummaries.length,
            itemBuilder: (context, index) {
              final summary = committeeSummaries[index];
              final List<Event> list = summary['tasks'];
              final total = list.length;
              final completed = list.where((e) => e.isCompleted == 1).length;
              final double percent = total == 0 ? 0.0 : completed / total;

              return Card(
                color: cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      _selectedLeadCommitteeFilter = summary['name'];
                      _selectedIndex = 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(summary['icon'], color: summary['color'], size: 36),
                        const SizedBox(height: 10),
                        Text(
                          summary['name'].toString().split(' & ').first,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$completed / $total Görev',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: summary['color'].withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(summary['color']),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '%${(percent * 100).toInt()} Tamamlandı',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: summary['color']),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLeadTasksTab(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final query = _searchController.text.toLowerCase().trim();
    final filteredEvents = _allEvents.where((e) {
      final matchesSearch = e.title.toLowerCase().contains(query) || e.location.toLowerCase().contains(query);
      final matchesCommittee = _selectedLeadCommitteeFilter == 'Tüm Komiteler' || e.committee == _selectedLeadCommitteeFilter;
      return matchesSearch && matchesCommittee;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF3949AB)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLeadCommitteeFilter,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF3949AB), size: 20),
                  items: const [
                    DropdownMenuItem(value: 'Tüm Komiteler', child: Text('Tüm Komiteler', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'Sponsorluk & İş Geliştirme', child: Text('Sponsorluk & İş Geliştirme', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'Dijital Medya & Tasarım', child: Text('Dijital Medya & Tasarım', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'Medium & YouTube', child: Text('Medium & YouTube', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'Etkinlik & Organizasyon', child: Text('Etkinlik & Organizasyon', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLeadCommitteeFilter = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Liderlik Görevlerinde Ara...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: query.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                  : null,
              fillColor: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            ),
          ),
        ),
        
        Expanded(
          child: filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      Text(
                        'Eşleşen görev bulunamadı.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sağ alt köşeden yeni bir elçi görevi oluşturabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 5, bottom: 80, left: 16, right: 16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final isCompleted = event.isCompleted == 1;
                    
                    Color commColor = const Color(0xFF3949AB);
                    if (event.committee.contains('Sponsor')) commColor = const Color(0xFF4CAF50);
                    else if (event.committee.contains('Dijital')) commColor = const Color(0xFFE91E63);
                    else if (event.committee.contains('Medium')) commColor = const Color(0xFFF44336);
                    else if (event.committee.contains('Etkinlik')) commColor = const Color(0xFFFF9800);

                    return Card(
                      color: cardColor,
                      elevation: isCompleted ? 1 : 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
                          );
                          _refreshEvents();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isCompleted,
                                activeColor: commColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (bool? value) async {
                                  event.isCompleted = value == true ? 1 : 0;
                                  await _dbHelper.updateEvent(event);
                                  _refreshEvents();
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 16, 
                                        color: isCompleted ? Colors.grey : textColor,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: isCompleted ? Colors.grey.shade400 : Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.date,
                                            style: TextStyle(
                                              color: isCompleted ? Colors.grey.shade400 : Colors.grey, 
                                              fontSize: 12,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: isCompleted ? Colors.grey.shade400 : Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location,
                                            style: TextStyle(
                                              color: isCompleted ? Colors.grey.shade400 : Colors.grey, 
                                              fontSize: 12,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: commColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            event.committee,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: commColor,
                                            ),
                                          ),
                                        ),
                                        if (event.assignedTo != null && event.assignedTo!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.person, size: 10, color: Colors.blue),
                                                const SizedBox(width: 3),
                                                Text(
                                                  event.assignedTo!,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 28),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Silmeyi Onayla'),
                                      content: Text('"${event.title}" görevini silmek istediğinize emin misiniz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context), 
                                          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await _dbHelper.deleteEvent(event.id!);
                                            _refreshEvents();
                                          },
                                          child: const Text('Sil'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLeadAnnouncementsTab(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.campaign, color: Color(0xFF3949AB), size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Yeni Duyuru Yayınla',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _annTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Duyuru Başlığı',
                      prefixIcon: Icon(Icons.title, color: Color(0xFF3949AB)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _annContentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Duyuru İçeriği / Mesaj',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.description, color: Color(0xFF3949AB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _selectedAnnTarget,
                    decoration: const InputDecoration(
                      labelText: 'Hedef Komite',
                      prefixIcon: Icon(Icons.group, color: Color(0xFF3949AB)),
                    ),
                    icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF3949AB)),
                    items: const [
                      DropdownMenuItem(value: 'Tüm Komiteler', child: Text('Tüm Komiteler')),
                      DropdownMenuItem(value: 'Sponsorluk & İş Geliştirme', child: Text('Sponsorluk & İş Geliştirme')),
                      DropdownMenuItem(value: 'Dijital Medya & Tasarım', child: Text('Dijital Medya & Tasarım')),
                      DropdownMenuItem(value: 'Medium & YouTube', child: Text('Medium & YouTube')),
                      DropdownMenuItem(value: 'Etkinlik & Organizasyon', child: Text('Etkinlik & Organizasyon')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedAnnTarget = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3949AB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final title = _annTitleController.text.trim();
                        final content = _annContentController.text.trim();
                        if (title.isEmpty || content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen duyuru başlığını ve içeriğini doldurun!')),
                          );
                          return;
                        }

                        final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
                        final newAnn = Announcement(
                          title: title,
                          content: content,
                          date: dateStr,
                          targetCommittee: _selectedAnnTarget,
                        );

                        await _dbHelper.insertAnnouncement(newAnn);
                        _annTitleController.clear();
                        _annContentController.clear();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Duyuru başarıyla yayınlandı!')),
                        );
                        _refreshEvents();
                      },
                      child: const Text('Duyuruyu Yayınla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          Text(
            'Aktif Duyurular',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 15),

          _announcements.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('Yayında aktif duyuru bulunmamaktadır.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _announcements.length,
                  itemBuilder: (context, idx) {
                    final ann = _announcements[idx];
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Opacity(
                        opacity: ann.isCompleted == 1 ? 0.6 : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3949AB).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ann.targetCommittee,
                                      style: const TextStyle(color: Color(0xFF3949AB), fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          ann.isCompleted == 1 ? Icons.check_circle : Icons.check_circle_outline,
                                          color: ann.isCompleted == 1 ? Colors.green : Colors.grey,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          ann.isCompleted = ann.isCompleted == 1 ? 0 : 1;
                                          await _dbHelper.updateAnnouncement(ann);
                                          _refreshEvents();
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text(ann.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          await _dbHelper.deleteAnnouncement(ann.id!);
                                          _refreshEvents();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                ann.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16, 
                                  color: ann.isCompleted == 1 ? Colors.grey : textColor,
                                  decoration: ann.isCompleted == 1 ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ann.content,
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: ann.isCompleted == 1 
                                      ? Colors.grey.shade500 
                                      : (_isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                  decoration: ann.isCompleted == 1 ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- 3. PROFİL SEKMESİ ---
  Widget _buildProfileTab(Color cardColor) {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.committeeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 80, color: widget.committeeColor),
          ),
          const SizedBox(height: 20),
          Text(
            widget.user.fullName,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            '@${widget.user.username}',
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 35),
          
          // ---------------- TEMA VE AYARLAR KARTI (SQLITE DESTEKLİ) ----------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.dark_mode, color: widget.committeeColor),
                  title: Text('Karanlık Mod', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                  subtitle: const Text('Tema tercihinizi veritabanına kalıcı olarak yazar.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  value: _isDarkMode,
                  activeColor: widget.committeeColor,
                  onChanged: (val) => _toggleTheme(),
                ),
                const Divider(),
                
                // ---------------- YOL GÖSTERİCİ KILAVUZ BUTONU (PERSISTENT REHBER) ----------------
                ListTile(
                  leading: Icon(Icons.help_center_outlined, color: widget.committeeColor),
                  title: Text('Yol Gösterici Kılavuz', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                  subtitle: const Text('Kulüp ve komite görev rehberini inceleyin.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  onTap: _showOnboardingDialog,
                ),
                const Divider(),

                // ---------------- KOMİTELERE GÖZ AT VE GÖREV ATA BUTONU ----------------
                ListTile(
                  leading: const Icon(Icons.explore_outlined, color: Colors.blueAccent),
                  title: Text('Komitelere Göz At / Görev Ata', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                  subtitle: const Text('Diğer komite panellerine geçerek yeni görevler atayın.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommitteeSelectionScreen(user: widget.user),
                      ),
                    ).then((_) => _refreshEvents());
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 25),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}