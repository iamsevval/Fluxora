class EventDuty {
  int? id;
  String staffName;
  String dutyZone; // 'Karşılama', 'Ses Kontrol', 'Sahne Arkası', 'İkram'
  String timeSlot; 
  String status;   // 'Görevde', 'Molada'

  EventDuty({
    this.id,
    required this.staffName,
    required this.dutyZone,
    required this.timeSlot,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffName': staffName,
      'dutyZone': dutyZone,
      'timeSlot': timeSlot,
      'status': status,
    };
  }

  factory EventDuty.fromMap(Map<String, dynamic> map) {
    return EventDuty(
      id: map['id'],
      staffName: map['staffName'] ?? '',
      dutyZone: map['dutyZone'] ?? '',
      timeSlot: map['timeSlot'] ?? '',
      status: map['status'] ?? 'Görevde',
    );
  }
}
