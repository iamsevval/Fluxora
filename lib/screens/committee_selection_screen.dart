import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'home_screen.dart'; // Dashboard ekranı olacak

class CommitteeSelectionScreen extends StatelessWidget {
  final User user;

  const CommitteeSelectionScreen({super.key, required this.user});

  final List<Map<String, dynamic>> _committees = const [
    {
      'title': 'Sponsorluk & İş Geliştirme',
      'icon': Icons.handshake,
      'color': Color(0xFF4CAF50), // Yeşil
      'description': 'Marka iş birlikleri, sponsorluk ve takım ruhu.',
      'detail': 'Sosyal medya üzerinden, markalar ve işletmelerle iş birlikleri kurarak topluluğumuza prestij ve değer katmak.\nEtkinlikleri daha eğlenceli ve akılda kalıcı hale getirmek için özel ödüller ve sponsorluk fırsatları yaratmak.'
    },
    {
      'title': 'Dijital Medya & Tasarım',
      'icon': Icons.design_services,
      'color': Color(0xFFE91E63), // Pembe
      'description': 'Sosyal medya yönetimi ve görsel içerik üretimi.',
      'detail': 'Sosyal medya hesaplarını yaratıcı, dinamik içeriklerle yönetmek.\nGüncel akımları takip ederek eğlenceli reels videoları çekmek, Post ve story tasarımları yapmak.'
    },
    {
      'title': 'Medium & YouTube',
      'icon': Icons.video_camera_front,
      'color': Color(0xFFF44336), // Kırmızı
      'description': 'Blog yazıları ve YouTube canlı yayın organizasyonları.',
      'detail': 'Topluluğumuzun Medium hesabı için özgün ve bilgilendirici blog yazıları kaleme almak.\nYouTube üzerinden gerçekleştireceğimiz canlı yayınların organizasyonunu yürütmek ve moderatörlük yapmak.'
    },
    {
      'title': 'Etkinlik & Organizasyon',
      'icon': Icons.event_available,
      'color': Color(0xFFFF9800), // Turuncu
      'description': 'Fiziksel/Online etkinlikler ve yaratıcı atölyeler.',
      'detail': 'Google Meet gibi platformlar üzerinden ilham veren online etkinlikler düzenlemek.\nYaklaşan zirvelerde aktif rol almak, teknik geziler ve yarışmalar organize etmek.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komiteleri İncele', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: true, // Geri tuşunu göster
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, ${user.fullName} 👋',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Çalışmak istediğin veya ait olduğun komiteyi seçerek kontrol paneline (Dashboard) geçiş yapabilirsin.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _committees.length,
              itemBuilder: (context, index) {
                final committee = _committees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            user: user,
                            committeeName: committee['title'],
                            committeeDetail: committee['detail'],
                            committeeColor: committee['color'],
                            committeeIcon: committee['icon'],
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: committee['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Hero(
                              tag: 'committee_${committee['title']}',
                              child: Material(
                                color: Colors.transparent,
                                child: Icon(committee['icon'], color: committee['color'], size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  committee['title'],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  committee['description'],
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
