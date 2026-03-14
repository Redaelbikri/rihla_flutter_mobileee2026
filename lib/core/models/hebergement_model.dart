class HebergementModel {
  final String id;
  final String name;
  final String? city;
  final String? address;
  final String? imageUrl;
  final double? pricePerNight;
  final String? description;
  final String? type;
  final int? roomsAvailable;
  final double? rating;
  final bool? active;

  HebergementModel({
    required this.id,
    required this.name,
    this.city,
    this.address,
    this.imageUrl,
    this.pricePerNight,
    this.description,
    this.type,
    this.roomsAvailable,
    this.rating,
    this.active,
  });

  factory HebergementModel.fromJson(Map<String, dynamic> j) => HebergementModel(
        id: (j['id'] ?? j['_id']).toString(),
        name: (j['name'] ?? j['title'] ?? j['nom'] ?? 'Stay').toString(),
        city: (j['city'] ?? j['ville'])?.toString(),
        address: (j['address'] ?? j['adresse'])?.toString(),
        imageUrl: (j['imageUrl'] ?? j['coverUrl'] ?? j['photoUrl'])?.toString(),
        description: j['description']?.toString(),
        pricePerNight: (j['pricePerNight'] is num)
            ? (j['pricePerNight'] as num).toDouble()
            : (j['prixParNuit'] is num)
                ? (j['prixParNuit'] as num).toDouble()
                : double.tryParse(
                    '${j['pricePerNight'] ?? j['prixParNuit'] ?? j['price']}'),
        type: (j['type'] ?? j['hebergementType'])?.toString(),
        roomsAvailable: (j['chambresDisponibles'] is num)
            ? (j['chambresDisponibles'] as num).toInt()
            : int.tryParse('${j['chambresDisponibles']}'),
        rating: (j['note'] is num)
            ? (j['note'] as num).toDouble()
            : double.tryParse('${j['note']}'),
        active: (j['actif'] is bool) ? j['actif'] as bool : null,
      );
}
