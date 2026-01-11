class GymBranch {
  final int? id;
  final String name;
  final String address;
  final String? city;
  final String? phone;
  final String? email;
  final double latitude;
  final double longitude;
  final String? openingTime;
  final String? closingTime;
  final String? facilities;
  final bool isActive;
  final DateTime createdAt;

  GymBranch({
    this.id,
    required this.name,
    required this.address,
    this.city,
    this.phone,
    this.email,
    required this.latitude,
    required this.longitude,
    this.openingTime,
    this.closingTime,
    this.facilities,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'facilities': facilities,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GymBranch.fromMap(Map<String, dynamic> map) {
    return GymBranch(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
      city: map['city'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      openingTime: map['opening_time'] as String?,
      closingTime: map['closing_time'] as String?,
      facilities: map['facilities'] as String?,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'GymBranch{id: $id, name: $name, address: $address, city: $city}';
  }
}

