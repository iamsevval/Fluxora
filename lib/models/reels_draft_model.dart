class ReelsDraft {
  int? id;
  String concept;
  int duration; // saniye
  int isTrendingMusic; // 0: False, 1: True
  String hookStrength; // 'Düşük', 'Orta', 'Yüksek'
  int calculatedViralScore; // 0 - 100
  String recommendations;

  ReelsDraft({
    this.id,
    required this.concept,
    required this.duration,
    required this.isTrendingMusic,
    required this.hookStrength,
    required this.calculatedViralScore,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concept': concept,
      'duration': duration,
      'isTrendingMusic': isTrendingMusic,
      'hookStrength': hookStrength,
      'calculatedViralScore': calculatedViralScore,
      'recommendations': recommendations,
    };
  }

  factory ReelsDraft.fromMap(Map<String, dynamic> map) {
    return ReelsDraft(
      id: map['id'],
      concept: map['concept'] ?? '',
      duration: map['duration'] ?? 15,
      isTrendingMusic: map['isTrendingMusic'] ?? 0,
      hookStrength: map['hookStrength'] ?? 'Orta',
      calculatedViralScore: map['calculatedViralScore'] ?? 0,
      recommendations: map['recommendations'] ?? '',
    );
  }
}
