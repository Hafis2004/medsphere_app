class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
  });

  final String id;
  final String name;
  final String email;
  final String specialty;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialty': specialty,
    };
  }
}
