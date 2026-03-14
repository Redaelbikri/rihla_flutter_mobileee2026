class ReservationModel {
  final String id;
  final String? type;
  final String? itemId;
  final String? title;
  final String? status;
  final int? quantity;
  final double? amount;
  final String? createdAt;
  final String? imageUrl;

  ReservationModel({
    required this.id,
    this.type,
    this.itemId,
    this.title,
    this.status,
    this.quantity,
    this.amount,
    this.createdAt,
    this.imageUrl,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> j) => ReservationModel(
        id: (j['id'] ?? j['_id']).toString(),
        type: (j['type'] ??
                j['reservationType'] ??
                (j['eventId'] != null
                    ? 'EVENT'
                    : j['hebergementId'] != null
                        ? 'HEBERGEMENT'
                        : j['transportTripId'] != null
                            ? 'TRANSPORT'
                            : null))
            ?.toString(),
        itemId: (j['itemId'] ??
                j['targetId'] ??
                j['eventId'] ??
                j['tripId'] ??
                j['transportTripId'] ??
                j['hebergementId'] ??
                (j['event'] is Map ? (j['event'] as Map)['id'] : null) ??
                (j['transport'] is Map ? (j['transport'] as Map)['id'] : null) ??
                (j['hebergement'] is Map
                    ? (j['hebergement'] as Map)['id']
                    : null))
            ?.toString(),
        title: (j['title'] ??
                j['itemTitle'] ??
                j['name'] ??
                (j['eventId'] != null ? 'Event reservation' : null) ??
                (j['hebergementId'] != null ? 'Hotel reservation' : null) ??
                (j['transportTripId'] != null
                    ? 'Transport reservation'
                    : null) ??
                j['event']?['title'] ??
                j['hebergement']?['name'] ??
                j['transport']?['name'])
            ?.toString(),
        status: (j['status'] ?? j['state'])?.toString(),
        quantity: (j['quantity'] is num)
            ? (j['quantity'] as num).toInt()
            : int.tryParse(
                '${j['quantity'] ?? j['eventTickets'] ?? j['hebergementRooms'] ?? j['transportSeats'] ?? j['event']?['quantity'] ?? j['transport']?['quantity'] ?? j['hebergement']?['quantity']}',
              ),
        amount: (j['amount'] is num)
            ? (j['amount'] as num).toDouble()
            : double.tryParse('${j['amount'] ?? j['amountMad']}'),
        createdAt: (j['createdAt'] ?? j['date'])?.toString(),
        imageUrl: (j['imageUrl'] ?? j['coverUrl'])?.toString(),
      );
}
