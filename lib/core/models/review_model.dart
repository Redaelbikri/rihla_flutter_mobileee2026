class ReviewModel {
  final String id;
  final String? userName;
  final double rating;
  final String comment;
  final String? imageUrl;
  final String? createdAt;

  ReviewModel({
    required this.id,
    this.userName,
    required this.rating,
    required this.comment,
    this.imageUrl,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id: (j['id'] ?? j['_id']).toString(),
        userName: (j['userName'] ??
                j['author'] ??
                j['user']?['fullName'] ??
                j['userId'])
            ?.toString(),
        rating: (j['rating'] is num)
            ? (j['rating'] as num).toDouble()
            : double.tryParse('${j['rating']}') ?? 0,
        comment: (j['commentaire'] ?? j['comment'] ?? j['content'] ?? '')
            .toString(),
        imageUrl: (j['imageUrl'] ?? j['photoUrl'])?.toString(),
        createdAt: (j['createdAt'] ?? j['date'])?.toString(),
      );
}
