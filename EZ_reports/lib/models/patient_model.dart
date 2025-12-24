class Patient {
  final String id;
  final String patientId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get name => '$firstName $lastName';

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] ?? '',
      patientId: map['patient_id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      dateOfBirth: map['date_of_birth'] != null 
          ? DateTime.parse(map['date_of_birth']) 
          : null,
      gender: map['gender'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

