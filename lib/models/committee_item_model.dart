class CommitteeItem {
  int? id;
  String committee;
  String type; // 'brand', 'content', 'link', 'checklist'
  String title;
  String subtitle;
  String statusColor; 
  int isDone; // 0: False, 1: True

  CommitteeItem({
    this.id,
    required this.committee,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.statusColor,
    this.isDone = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'committee': committee,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'statusColor': statusColor,
      'isDone': isDone,
    };
  }

  factory CommitteeItem.fromMap(Map<String, dynamic> map) {
    return CommitteeItem(
      id: map['id'],
      committee: map['committee'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      statusColor: map['statusColor'] ?? '0xFF9E9E9E',
      isDone: map['isDone'] ?? 0,
    );
  }
}
