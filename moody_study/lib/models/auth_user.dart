class AuthUser {
  final String token;
  final String? name;
  final String? username;
  final String? email;

  const AuthUser({
    required this.token,
    this.name,
    this.username,
    this.email,
  });
}
