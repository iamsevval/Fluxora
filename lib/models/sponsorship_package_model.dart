class SponsorshipPackage {
  int? id;
  String packageName;
  double budgetLimit;
  int socialMediaPosts; 
  int logoBanner;       // 0: False, 1: True
  int standArea;        // 0: False, 1: True
  double totalPrice;

  SponsorshipPackage({
    this.id,
    required this.packageName,
    required this.budgetLimit,
    required this.socialMediaPosts,
    required this.logoBanner,
    required this.standArea,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'budgetLimit': budgetLimit,
      'socialMediaPosts': socialMediaPosts,
      'logoBanner': logoBanner,
      'standArea': standArea,
      'totalPrice': totalPrice,
    };
  }

  factory SponsorshipPackage.fromMap(Map<String, dynamic> map) {
    return SponsorshipPackage(
      id: map['id'],
      packageName: map['packageName'] ?? '',
      budgetLimit: (map['budgetLimit'] as num?)?.toDouble() ?? 0.0,
      socialMediaPosts: map['socialMediaPosts'] ?? 0,
      logoBanner: map['logoBanner'] ?? 0,
      standArea: map['standArea'] ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
