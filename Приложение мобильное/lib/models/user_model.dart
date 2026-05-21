class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String password;
  final String? avatarPath;
  final DateTime registrationDate;
  bool isPhoneHidden;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    required this.password,
    this.avatarPath,
    required this.registrationDate,
    this.isPhoneHidden = false,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      phoneNumber: map['phone_number'],
      email: map['email'],
      password: map['password'],
      avatarPath: map['avatar_path'],
      registrationDate: DateTime.parse(map['registration_date']),
      isPhoneHidden: map['is_phone_hidden'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'email': email,
      'password': password,
      'avatar_path': avatarPath,
      'registration_date': registrationDate.toIso8601String(),
      'is_phone_hidden': isPhoneHidden ? 1 : 0,
    };
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? password,
    String? avatarPath,
    DateTime? registrationDate,
    bool? isPhoneHidden,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarPath: avatarPath ?? this.avatarPath,
      registrationDate: registrationDate ?? this.registrationDate,
      isPhoneHidden: isPhoneHidden ?? this.isPhoneHidden,
    );
  }
}