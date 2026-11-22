import 'donor_profile.dart';

/// Data pengguna yang sedang login.
class AppUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'user' atau 'admin'

  /// Profil pendonor mentah dari API (null bila belum dibuat).
  /// Akan dibuatkan model sendiri di tahap profil pendonor.
  final Map<String, dynamic>? donorProfile;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.donorProfile,
  });

  bool get isAdmin => role == 'admin';

  /// Profil pendonor dalam bentuk model (null bila belum dibuat).
  DonorProfile? get donor =>
      donorProfile == null ? null : DonorProfile.fromJson(donorProfile!);

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      donorProfile: json['donor_profile'] is Map<String, dynamic>
          ? json['donor_profile'] as Map<String, dynamic>
          : null,
    );
  }
}
