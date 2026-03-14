import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/ui/glass.dart';

class ItineraryResultPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const ItineraryResultPage({super.key, required this.data});

  @override
  State<ItineraryResultPage> createState() => _ItineraryResultPageState();
}

class _ItineraryResultPageState extends State<ItineraryResultPage> {
  List<LatLng> _intercityRoute = const [];
  LatLng? _fromCityPoint;
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initIntercityRoute();
  }

  Future<void> _initIntercityRoute() async {
    if (_loadingRoute) return;
    final fromCity = (widget.data['fromCity'] ?? '').toString().trim();
    final toCity = (widget.data['toCity'] ?? '').toString().trim();
    if (fromCity.isEmpty || toCity.isEmpty) return;
    if (fromCity.toLowerCase() == toCity.toLowerCase()) return;

    setState(() => _loadingRoute = true);
    try {
      final from = _findCityMarker(fromCity) ?? await _geocodeCity(fromCity);
      final to = _findCityMarker(toCity) ?? await _geocodeCity(toCity);

      if (!mounted) return;
      setState(() => _fromCityPoint = from);

      if (from == null || to == null) return;

      final route = await _fetchRoute(from, to);
      if (!mounted) return;
      setState(() {
        _intercityRoute = route.isNotEmpty ? route : [from, to];
      });
    } catch (_) {
      // Route display is best-effort only.
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  LatLng? _findCityMarker(String city) {
    final days = (widget.data['days'] as List?)?.cast<dynamic>() ?? const [];
    for (final day in days) {
      final d = day is Map ? day : <String, dynamic>{};
      final markers = (d['markers'] as List?)?.cast<dynamic>() ?? const [];
      for (final m in markers) {
        if (m is! Map) continue;
        final label = (m['title'] ?? m['name'] ?? '').toString();
        if (label.isEmpty) continue;
        if (label.toLowerCase() != city.toLowerCase()) continue;
        final loc = (m['location'] as Map?) ?? const {};
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    }
    return null;
  }

  Future<LatLng?> _geocodeCity(String city) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://nominatim.openstreetmap.org',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'User-Agent': 'rihla_mobile/1.0'},
      ),
    );
    final r = await dio.get(
      '/search',
      queryParameters: {
        'q': city,
        'format': 'json',
        'limit': 1,
      },
    );
    final data = r.data;
    if (data is! List || data.isEmpty) return null;
    final item = data.first;
    if (item is! Map) return null;
    final latStr = item['lat']?.toString();
    final lonStr = item['lon']?.toString();
    if (latStr == null || lonStr == null) return null;
    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lonStr);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<List<LatLng>> _fetchRoute(LatLng from, LatLng to) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://router.project-osrm.org',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'User-Agent': 'rihla_mobile/1.0'},
      ),
    );
    final r = await dio.get(
      '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
      },
    );
    final data = r.data;
    if (data is! Map) return const [];
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return const [];
    final route = routes.first;
    if (route is! Map) return const [];
    final geometry = route['geometry'];
    if (geometry is! Map) return const [];
    final coords = geometry['coordinates'];
    if (coords is! List) return const [];
    final points = <LatLng>[];
    for (final c in coords) {
      if (c is! List || c.length < 2) continue;
      final lng = (c[0] as num?)?.toDouble();
      final lat = (c[1] as num?)?.toDouble();
      if (lat != null && lng != null) points.add(LatLng(lat, lng));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final summary = (data['summary'] ?? data['aiSummary'] ?? '').toString();
    final days = (data['days'] as List?)?.cast<dynamic>() ?? const [];

    final markers = <Marker>[];
    final polylinePoints = <LatLng>[];

    for (final day in days) {
      final d = day is Map ? day : <String, dynamic>{};
      final dayMarkers = (d['markers'] as List?)?.cast<dynamic>() ?? const [];
      final dayRoutes = (d['routes'] as List?)?.cast<dynamic>() ?? const [];

      for (final m in dayMarkers) {
        if (m is! Map) continue;
        final loc = (m['location'] as Map?) ?? const {};
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final label = (m['title'] ?? m['type'] ?? 'Place').toString();

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 44,
            height: 44,
            child: Tooltip(
              message: label,
              child: const Icon(
                Icons.location_on_rounded,
                size: 36,
                color: Color(0xFF0E5A6A),
              ),
            ),
          ),
        );
      }

      for (final route in dayRoutes) {
        if (route is! Map) continue;
        final coords = (route['coordinates'] as List?)?.cast<dynamic>() ?? const [];
        for (final c in coords) {
          if (c is! List || c.length < 2) continue;
          final lng = (c[0] as num?)?.toDouble();
          final lat = (c[1] as num?)?.toDouble();
          if (lat != null && lng != null) {
            polylinePoints.add(LatLng(lat, lng));
          }
        }
      }
    }

    if (_fromCityPoint != null) {
      final label = (data['fromCity'] ?? 'From').toString();
      markers.add(
        Marker(
          point: _fromCityPoint!,
          width: 44,
          height: 44,
          child: Tooltip(
            message: label,
            child: const Icon(
              Icons.trip_origin_rounded,
              size: 30,
              color: Color(0xFFB25520),
            ),
          ),
        ),
      );
    }

    final center =
        markers.isNotEmpty ? markers.first.point : const LatLng(33.5731, -7.5898);

    final polylines = <Polyline>[];
    if (_intercityRoute.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _intercityRoute,
          color: const Color(0x3320535C),
          strokeWidth: 8,
        ),
      );
      polylines.add(
        Polyline(
          points: _intercityRoute,
          color: const Color(0xFF20535C),
          strokeWidth: 4,
        ),
      );
    }
    if (polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          points: polylinePoints,
          color: const Color(0xFF0E5A6A),
          strokeWidth: 4,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Itinerary Result')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['fromCity'] ?? '-'} -> ${data['toCity'] ?? '-'}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text('${data['startDate'] ?? '-'} to ${data['endDate'] ?? '-'}'),
                const SizedBox(height: 10),
                Text(summary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(0),
            child: SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: markers.isNotEmpty ? 11.5 : 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rihla.mobile',
                    ),
                    if (polylines.isNotEmpty)
                      PolylineLayer(
                        polylines: polylines,
                      ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...days.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final d = entry.value;
            final day = d is Map ? d : <String, dynamic>{};
            final events = (day['events'] as List?)?.cast<dynamic>() ?? const [];
            final transports = (day['transports'] as List?)?.cast<dynamic>() ?? const [];
            final hebergement =
                (day['hebergement'] is Map) ? day['hebergement'] as Map : null;

            Widget itemRow(String title, List<dynamic> list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ...list.map((e) {
                    final m = e is Map ? e : <String, dynamic>{};
                    final label = (m['nom'] ?? m['name'] ?? m['title'] ?? '-').toString();
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('- $label'),
                    );
                  }),
                  const SizedBox(height: 6),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $idx ${day['date'] ?? ''}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text((day['summary'] ?? day['aiNarrative'] ?? '').toString()),
                    if (hebergement != null) ...[
                      const SizedBox(height: 8),
                      const Text('Hebergement',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        '- ${(hebergement['nom'] ?? hebergement['name'] ?? hebergement['title'] ?? '-').toString()}',
                      ),
                    ],
                    const SizedBox(height: 8),
                    itemRow('Events', events),
                    itemRow('Transports', transports),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
