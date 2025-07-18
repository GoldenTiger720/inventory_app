class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? accessToken;
  final String? refreshToken;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.accessToken,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? accessToken,
    String? refreshToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}