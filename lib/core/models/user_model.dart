class UserModel {
  final String? id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  UserModel({this.id, this.fullName, this.email, this.phone, this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: (j['id'] ?? j['_id'])?.toString(),
        fullName: (j['fullName'] ??
                j['name'] ??
                (j['prenom'] != null || j['nom'] != null
                    ? '${j['prenom'] ?? ''} ${j['nom'] ?? ''}'.trim()
                    : null) ??
                j['username'])
            ?.toString(),
        email: j['email']?.toString(),
        phone: (j['phone'] ?? j['tel'] ?? j['telephone'])?.toString(),
        avatarUrl:
            (j['avatarUrl'] ?? j['imageUrl'] ?? j['photoUrl'])?.toString(),
      );
}
