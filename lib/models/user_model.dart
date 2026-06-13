class User {
  int? id;
  String fullName;
  String username;
  String password;
  String? primaryCommittee;
  int isNewUser; // 1: Yeni kayıt (onboarding), 0: Eski kayıt

  User({
    this.id,
    required this.fullName,
    required this.username,
    required this.password,
    this.primaryCommittee,
    this.isNewUser = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'password': password,
      'primaryCommittee': primaryCommittee,
      'isNewUser': isNewUser,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      primaryCommittee: map['primaryCommittee'],
      isNewUser: map['isNewUser'] ?? 1,
    );
  }
}
