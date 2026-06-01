class StreamQuestion {
  int? id;
  String guestName;
  String questioner;
  String questionText;
  int isAsked; // 0: False, 1: True
  String priority; // 'Yüksek', 'Orta', 'Düşük'

  StreamQuestion({
    this.id,
    required this.guestName,
    required this.questioner,
    required this.questionText,
    this.isAsked = 0,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guestName': guestName,
      'questioner': questioner,
      'questionText': questionText,
      'isAsked': isAsked,
      'priority': priority,
    };
  }

  factory StreamQuestion.fromMap(Map<String, dynamic> map) {
    return StreamQuestion(
      id: map['id'],
      guestName: map['guestName'] ?? '',
      questioner: map['questioner'] ?? '',
      questionText: map['questionText'] ?? '',
      isAsked: map['isAsked'] ?? 0,
      priority: map['priority'] ?? 'Orta',
    );
  }
}
