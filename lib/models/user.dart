/// Represents an authenticated admin user.
class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'Admin',
  });
}

