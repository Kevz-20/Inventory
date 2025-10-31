class User {
  final int? id;
  final String name;
  final String email;
  final int isSynced;

  User({this.id, required this.name, required this.email, this.isSynced = 0});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'isSynced': isSynced,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    isSynced: map['isSynced'],
  );
}
