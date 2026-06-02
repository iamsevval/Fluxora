import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/event_model.dart';
import '../models/user_model.dart'; // Kullanıcı modeli eklendi

class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late String _currentCommittee;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late String _currentDateString; // Ekrandaki gösterim için
  
  List<User> _users = []; // Tüm üyelerin listesi
  String? _selectedUser; // Seçilen üye
  
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
    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location);
    _descriptionController = TextEditingController(text: widget.event.description);
    _currentCommittee = widget.event.committee;
    _currentDateString = widget.event.date; // Veritabanındaki eski tarih metni
    _selectedUser = widget.event.assignedTo;
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await _dbHelper.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _updateCurrentDateString();
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _updateCurrentDateString();
    }
  }

  void _updateCurrentDateString() {
    List<String> parts = widget.event.date.split(', ');
    String datePart = parts.isNotEmpty ? parts[0] : '';
    String timePart = parts.length > 1 ? parts[1] : '';

    if (_selectedDate != null) {
      datePart = DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate!);
    }
    if (_selectedTime != null) {
      timePart = _selectedTime!.format(context);
    }

    setState(() {
      if (timePart.isNotEmpty) {
        _currentDateString = '$datePart, $timePart';
      } else {
        _currentDateString = datePart;
      }
    });
  }

  void _updateEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen etkinlik adını girin.')),
      );
      return;
    }

    if (title.length < 3 || title.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etkinlik / Görev adı 3-50 karakter arasında olmalıdır!')),
      );
      return;
    }

    // Yeni seçilen bir tarih varsa onun geçerlilik kontrolünü yapıyoruz
    if (_selectedDate != null && _selectedTime != null) {
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
    }

    Event updatedEvent = Event(
      id: widget.event.id, 
      title: title,
      date: _currentDateString, // Yeni veya eski tarih metni
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      committee: _currentCommittee,
      isCompleted: widget.event.isCompleted,
      assignedTo: _selectedUser,
    );

    try {
      await _dbHelper.updateEvent(updatedEvent);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme sırasında bir hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydı Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bilgileri Güncelle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)),
            ),
            const SizedBox(height: 20),

            // --- KOMİTE SEÇİCİ ---
            DropdownButtonFormField<String>(
              isExpanded: true,
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
                  _currentCommittee = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _titleController, 
              decoration: const InputDecoration(
                labelText: 'Etkinlik Adı',
                prefixIcon: Icon(Icons.title, color: Color(0xFF3949AB)),
              )
            ),
            const SizedBox(height: 20),

            // --- TARİH GÖSTERİMİ VE SEÇİCİLER ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mevcut Tarih / Saat', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(_currentDateString, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, color: Color(0xFF3949AB), size: 20),
                          label: const Text('Yeni Tarih'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time, color: Color(0xFF3949AB), size: 20),
                          label: const Text('Yeni Saat'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _locationController, 
              decoration: const InputDecoration(
                labelText: 'Konum / Platform', 
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF3949AB)),
              )
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
              )
            ),
            const SizedBox(height: 20),

            // --- GÖREVLENDİRİLEN KİŞİ SEÇİCİ ---
            DropdownButtonFormField<String>(
              isExpanded: true,
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
                onPressed: _updateEvent,
                child: const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}