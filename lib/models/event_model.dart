class Event {
  int? id;
  String title;
  String date;
  String location;
  String description;
  String committee; 
  int isCompleted; // 0: False, 1: True
  String? assignedTo; // Görevin atandığı kişi

  Event({
    this.id, 
    required this.title, 
    required this.date, 
    required this.location, 
    required this.description,
    required this.committee, 
    this.isCompleted = 0,
    this.assignedTo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'description': description,
      'committee': committee, 
      'isCompleted': isCompleted,
      'assignedTo': assignedTo,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
      committee: map['committee'], 
      isCompleted: map['isCompleted'] ?? 0,
      assignedTo: map['assignedTo'],
    );
  }
}