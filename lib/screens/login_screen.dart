import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final DbHelper _dbHelper = DbHelper();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Color _getColorForCommittee(String? committee) {
    switch (committee) {
      case 'Kampüs Elçisi':
        return const Color(0xFF3949AB); 
      case 'Kampüs Elçisi Yardımcısı':
        return const Color(0xFF5C6BC0); 
      case 'Sponsorluk & İş Geliştirme':
        return const Color(0xFF4CAF50);
      case 'Dijital Medya & Tasarım':
        return const Color(0xFFE91E63);
      case 'Medium & YouTube':
        return const Color(0xFFF44336);
      case 'Etkinlik & Organizasyon':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF3949AB);
    }
  }

  IconData _getIconForCommittee(String? committee) {
    switch (committee) {
      case 'Kampüs Elçisi':
        return Icons.admin_panel_settings; // Elçi Rozeti
      case 'Kampüs Elçisi Yardımcısı':
        return Icons.admin_panel_settings_outlined; // Yardımcı Elçi Rozeti
      case 'Sponsorluk & İş Geliştirme':
        return Icons.handshake;
      case 'Dijital Medya & Tasarım':
        return Icons.design_services;
      case 'Medium & YouTube':
        return Icons.video_camera_front;
      case 'Etkinlik & Organizasyon':
        return Icons.event_available;
      default:
        return Icons.people;
    }
  }

  String _getDetailForCommittee(String? committee) {
    switch (committee) {
      case 'Kampüs Elçisi':
        return 'Topluluktaki tüm komite süreçlerini, duyuruları ve görev dağılımlarını tek bir merkezden koordine edin.';
      case 'Kampüs Elçisi Yardımcısı':
        return 'Kampüs elçisine yardımcı olarak topluluk koordinasyonuna, görev takibine ve duyuruların yönetilmesine katkı sağlayın.';
      case 'Sponsorluk & İş Geliştirme':
        return 'Sosyal medya üzerinden, markalar ve işletmelerle iş birlikleri kurarak topluluğumuza prestij ve değer katmak.\nEtkinlikleri daha eğlenceli ve akılda kalıcı hale getirmek için özel ödüller ve sponsorluk fırsatları yaratmak.';
      case 'Dijital Medya & Tasarım':
        return 'Sosyal medya hesaplarını yaratıcı, dinamik içeriklerle yönetmek.\nGüncel akımları takip ederek eğlenceli reels videoları çekmek, Post ve story tasarımları yapmak.';
      case 'Medium & YouTube':
        return 'Topluluğumuzun Medium hesabı için özgün ve bilgilendirici blog yazıları kaleme almak.\nYouTube üzerinden gerçekleştireceğimiz canlı yayınların organizasyonunu yürütmek ve moderatörlük yapmak.';
      case 'Etkinlik & Organizasyon':
        return 'Google Meet gibi platformlar üzerinden ilham veren online etkinlikler düzenlemek.\nYaklaşan zirvelerde aktif rol almak, teknik geziler ve yarışmalar organize etmek.';
      default:
        return 'Topluluk komitelerinde aktif çalışma paneli.';
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      User? user = await _dbHelper.loginUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (user != null) {
        if (mounted) {
          final cName = user.primaryCommittee ?? 'Sponsorluk & İş Geliştirme';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                user: user,
                committeeName: cName,
                committeeDetail: _getDetailForCommittee(cName),
                committeeColor: _getColorForCommittee(cName),
                committeeIcon: _getIconForCommittee(cName),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı adı veya şifre hatalı!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt, size: 100, color: Color(0xFF3949AB)),
                const SizedBox(height: 30),
                const Text(
                  'Hoş Geldiniz',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
                ),
                const SizedBox(height: 10),
                const Text('Devam etmek için giriş yapın', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF3949AB)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen kullanıcı adınızı girin';
                    }
                    if (value.trim().length < 3) {
                      return 'Kullanıcı adı en az 3 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF3949AB)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi girin';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3949AB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hesabınız yok mu?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text('Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3949AB))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
