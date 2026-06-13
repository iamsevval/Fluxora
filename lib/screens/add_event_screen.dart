import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../database/db_helper.dart';
import '../models/event_model.dart';
import '../models/user_model.dart'; 

class AddEventScreen extends StatefulWidget {
  final String selectedCommittee; // Anasayfadan gelen seçili komite

  const AddEventScreen({super.key, required this.selectedCommittee});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _currentCommittee;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  List<User> _users = []; 
  String? _selectedUser; 

  final DbHelper _dbHelper = DbHelper();
  final List<String> _committees = [
    'Sponsorluk & İş Geliştirme',
    'Dijital Medya & Tasarım',
    'Medium & YouTube',
    'Etkinlik & Organizasyon'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedCommittee == 'Kampüs Elçisi' || widget.selectedCommittee == 'Kampüs Elçisi Yardımcısı') {
      _currentCommittee = 'Sponsorluk & İş Geliştirme';
    } else {
      _currentCommittee = widget.selectedCommittee;
    }
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await _dbHelper.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  // --- TAKVİM SEÇİCİ ---
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- SAAT SEÇİCİ ---
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen etkinlik adını, tarihini ve saatini seçin.')),
      );
      return;
    }

    if (title.length < 3 || title.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etkinlik / Görev adı 3-50 karakter arasında olmalıdır!')),
      );
      return;
    }

    // Geçmiş tarih ve saat kontrolü
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçmiş bir tarih ve saat seçemezsiniz!')),
      );
      return;
    }

    // Tarih ve saati birleştirip metne çeviriyoruz 
    final formattedDate = DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate!);
    final formattedTime = _selectedTime!.format(context);
    final finalDateTimeString = '$formattedDate, $formattedTime';

    // Çakışma Kontrolü (Aynı komitede aynı isim ve aynı saatte etkinlik olmasın)
    final existing = await _dbHelper.getEventsByCommittee(_currentCommittee!);
    final isDuplicate = existing.any((e) => e.title.toLowerCase() == title.toLowerCase() && e.date == finalDateTimeString);
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu komitede aynı isimde ve aynı saatte bir etkinlik zaten mevcut!')),
      );
      return;
    }

    Event newEvent = Event(
      title: title,
      date: finalDateTimeString,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      committee: _currentCommittee!,
      assignedTo: _selectedUser,
    );

    try {
      await _dbHelper.insertEvent(newEvent);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt sırasında bir hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Kayıt Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Etkinlik Detayları',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
            ),
            const SizedBox(height: 20),

            // --- KOMİTE SEÇİCİ (Açılır Menü) ---
            DropdownButtonFormField<String>(
              value: _currentCommittee,
              decoration: const InputDecoration(
                labelText: 'İlgili Komite',
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
                  _currentCommittee = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Etkinlik / Görev Adı',
                prefixIcon: Icon(Icons.title, color: Color(0xFF3949AB)),
              ),
            ),
            const SizedBox(height: 20),

            // --- TARİH VE SAAT SEÇİCİ BUTONLARI ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, color: Color(0xFF3949AB)),
                    label: Text(_selectedDate == null 
                        ? 'Tarih Seç' 
                        : DateFormat('dd MMM yyyy').format(_selectedDate!)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, color: Color(0xFF3949AB)),
                    label: Text(_selectedTime == null 
                        ? 'Saat Seç' 
                        : _selectedTime!.format(context)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Konum / Platform', 
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF3949AB)),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Açıklama', 
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60.0), 
                  child: Icon(Icons.description, color: Color(0xFF3949AB)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- GÖREVLENDİRİLEN KİŞİ SEÇİCİ ---
            DropdownButtonFormField<String>(
              value: _selectedUser,
              decoration: const InputDecoration(
                labelText: 'Görevi Atayacağın Kişi (Opsiyonel)',
                prefixIcon: Icon(Icons.person_pin, color: Color(0xFF3949AB)),
              ),
              icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF3949AB)),
              items: _users.map((User u) {
                return DropdownMenuItem<String>(
                  value: u.fullName,
                  child: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUser = newValue;
                });
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
                  shadowColor: const Color(0xFF3949AB).withOpacity(0.5),
                ),
                onPressed: _saveEvent,
                child: const Text('Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}