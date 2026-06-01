class Announcement {
  int? id;
  String title;
  String content;
  String date;
  String targetCommittee; // 'Tüm Komiteler' veya belirli bir komite adı
  int isCompleted; // 0: tamamlanmadı, 1: tamamlandı / okundu

  Announcement({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.targetCommittee,
    this.isCompleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'targetCommittee': targetCommittee,
      'isCompleted': isCompleted,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] ?? '',
      targetCommittee: map['targetCommittee'] ?? 'Tüm Komiteler',
      isCompleted: map['isCompleted'] ?? 0,
    );
  }
}
