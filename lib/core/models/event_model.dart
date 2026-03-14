class EventModel {
  final String id;
  final String title;
  final String? city;
  final String? category;
  final String? imageUrl;
  final String? description;
  final double? price;
  final DateTime? dateEvent;
  final String? dateEventRaw;
  final int? placesDisponibles;

  EventModel({
    required this.id,
    required this.title,
    this.city,
    this.category,
    this.imageUrl,
    this.description,
    this.price,
    this.dateEvent,
    this.dateEventRaw,
    this.placesDisponibles,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) {
    final rawDate = j['dateEvent'] ?? j['startDate'] ?? j['dateStart'];
    DateTime? parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return EventModel(
      id: (j['id'] ?? j['_id']).toString(),
      title: (j['title'] ?? j['name'] ?? j['nom'] ?? 'Event').toString(),
      city: (j['city'] ?? j['ville'] ?? j['lieu'])?.toString(),
      category: (j['category'] ?? j['categorie'])?.toString(),
      imageUrl: (j['imageUrl'] ?? j['coverUrl'] ?? j['photoUrl'])?.toString(),
      description: j['description']?.toString(),
      price: (j['price'] is num)
          ? (j['price'] as num).toDouble()
          : (j['prix'] is num)
              ? (j['prix'] as num).toDouble()
              : double.tryParse('${j['price'] ?? j['prix']}'),
      dateEvent: parsedDate,
      dateEventRaw: rawDate?.toString(),
      placesDisponibles: (j['placesDisponibles'] is num)
          ? (j['placesDisponibles'] as num).toInt()
          : int.tryParse('${j['placesDisponibles']}'),
    );
  }
}
