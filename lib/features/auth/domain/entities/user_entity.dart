/// KLE HOMECARE — User Domain Entity
/// Pure Dart class — no JSON, no framework dependencies.
class UserEntity {
  final String  id;
  final String  fullName;
  final String  email;
  final String  role;
  final String? category;
  final bool    isAvailable;

  // ── Extended profile fields (populated from /patient/profile) ─────────────
  final String? phone;
  final String? address;
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.category,
    this.isAvailable = true,
    this.phone,
    this.address,
    this.area,
    this.city,
    this.state,
    this.pincode,
  });

  bool get isPatient => role == 'patient';
  bool get isAdmin   => role == 'admin';
  bool get isNurse   => role == 'nurse';

  UserEntity copyWith({
    String? category,
    bool?   isAvailable,
    String? phone,
    String? address,
    String? area,
    String? city,
    String? state,
    String? pincode,
  }) {
    return UserEntity(
      id:          id,
      fullName:    fullName,
      email:       email,
      role:        role,
      category:    category    ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      phone:       phone       ?? this.phone,
      address:     address     ?? this.address,
      area:        area        ?? this.area,
      city:        city        ?? this.city,
      state:       state       ?? this.state,
      pincode:     pincode     ?? this.pincode,
    );
  }
}
