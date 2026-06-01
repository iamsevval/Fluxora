import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final DbHelper _dbHelper = DbHelper();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _selectedCommittee = 'Sponsorluk & İş Geliştirme';
  
  final List<String> _committees = [
    'Sponsorluk & İş Geliştirme',
    'Dijital Medya & Tasarım',
    'Medium & YouTube',
    'Etkinlik & Organizasyon',
    'Kampüs Elçisi',
    'Kampüs Elçisi Yardımcısı'
  ];

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      String username = _usernameController.text.trim();
      
      // Kullanıcı var mı kontrol et
      bool exists = await _dbHelper.checkUserExists(username);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu kullanıcı adı zaten alınmış!')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Yeni kullanıcı oluştur
      User newUser = User(
        fullName: _fullNameController.text.trim(),
        username: username,
        password: _passwordController.text, // Gerçek uygulamada şifrelenmeli
        primaryCommittee: _selectedCommittee,
        isNewUser: 1, // Onboarding rehberini görsün
      );

      try {
        await _dbHelper.registerUser(newUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
          );
          Navigator.pop(context); // Giriş ekranına dön
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kayıt sırasında bir hata oluştu: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF3949AB),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_alt_1, size: 80, color: Color(0xFF3949AB)),
                const SizedBox(height: 30),
                const Text(
                  'Aramıza Katılın',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
                ),
                const SizedBox(height: 10),
                const Text('Topluluğun bir parçası olmak için kayıt olun.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.badge, color: Color(0xFF3949AB)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen adınızı ve soyadınızı girin';
                    }
                    final nameRegExp = RegExp(r"^[a-zA-ZğüşıöçĞÜŞİÖÇ]+(?:\s+[a-zA-ZğüşıöçĞÜŞİÖÇ]+)+$");
                    if (!nameRegExp.hasMatch(value.trim())) {
                      return 'Lütfen en az ad ve soyadınızı girin (örn: Ahmet Yılmaz)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- BİRİNCİL KOMİTE SEÇİCİ ---
                DropdownButtonFormField<String>(
                  value: _selectedCommittee,
                  decoration: const InputDecoration(
                    labelText: 'Ait Olduğunuz Komite',
                    prefixIcon: Icon(Icons.group, color: Color(0xFF3949AB)),
                  ),
                  icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF3949AB)),
                  items: _committees.map((String committee) {
                    return DropdownMenuItem<String>(
                      value: committee,
                      child: Text(committee, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCommittee = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Lütfen bir komite seçin' : null,
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF3949AB)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen kullanıcı adı girin';
                    }
                    if (value.trim().length < 3 || value.trim().length > 15) {
                      return 'Kullanıcı adı 3-15 karakter arasında olmalıdır';
                    }
                    final usernameRegExp = RegExp(r"^[a-zA-Z0-9_]+$");
                    if (!usernameRegExp.hasMatch(value.trim())) {
                      return 'Kullanıcı adı sadece harf, rakam ve alt çizgi (_) içerebilir';
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
                    final letterRegExp = RegExp(r'[a-zA-Z]');
                    final numberRegExp = RegExp(r'[0-9]');
                    if (!letterRegExp.hasMatch(value) || !numberRegExp.hasMatch(value)) {
                      return 'Şifre en az 1 harf ve 1 rakam içermelidir';
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
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kayıt Ol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
