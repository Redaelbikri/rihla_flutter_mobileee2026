class TripModel {
  final String id;
  final String? imageUrl;
  final String? fromCity;
  final String? toCity;
  final String? type;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final String? date;
  final double? price;
  final String? currency;
  final int? capacity;
  final int? availableSeats;
  final String? providerName;

  const TripModel({
    required this.id,
    this.imageUrl,
    this.fromCity,
    this.toCity,
    this.type,
    this.departureAt,
    this.arrivalAt,
    this.date,
    this.price,
    this.currency,
    this.capacity,
    this.availableSeats,
    this.providerName,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    DateTime? _parseDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    }

    final departureAt =
        _parseDate(json['departureAt'] ?? json['departureDate']);
    final arrivalAt = _parseDate(json['arrivalAt'] ?? json['arrivalDate']);

    return TripModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['image'] ?? '')
              .toString()
              .isEmpty
          ? null
          : (json['imageUrl'] ?? json['image_url'] ?? json['image']).toString(),
      fromCity: (json['fromCity'] ?? json['from'] ?? json['departureCity'])
          ?.toString(),
      toCity: (json['toCity'] ?? json['to'] ?? json['arrivalCity'])?.toString(),
      type: (json['type'] ?? json['transportType'])?.toString(),
      departureAt: departureAt,
      arrivalAt: arrivalAt,
      date: (json['date'] ??
              json['departureDate'] ??
              json['departureAt'] ??
              departureAt?.toIso8601String())
          ?.toString(),
      price: _toDouble(json['price'] ?? json['amount']),
      currency: json['currency']?.toString(),
      capacity: (json['capacity'] is num)
          ? (json['capacity'] as num).toInt()
          : int.tryParse('${json['capacity']}'),
      availableSeats: (json['availableSeats'] is num)
          ? (json['availableSeats'] as num).toInt()
          : int.tryParse('${json['availableSeats']}'),
      providerName: json['providerName']?.toString(),
    );
  }
}
