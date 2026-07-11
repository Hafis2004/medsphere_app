class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.phone,
  });

  final String id;
  final String name;
  final int age;
  final String phone;

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'phone': phone,
    };
  }
}
