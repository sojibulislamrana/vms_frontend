/// Represents an authenticated admin user.
class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? token;
  final String? avatarUrl;
  final String? authProvider;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'Fleet Administrator',
    this.token,
    this.avatarUrl,
    this.authProvider = 'LOCAL',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'token': token,
        'avatarUrl': avatarUrl,
        'authProvider': authProvider,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        role: json['role']?.toString() ?? 'Fleet Administrator',
        token: json['token']?.toString(),
        avatarUrl: json['avatarUrl']?.toString(),
        authProvider: json['authProvider']?.toString() ?? 'LOCAL',
      );
}
