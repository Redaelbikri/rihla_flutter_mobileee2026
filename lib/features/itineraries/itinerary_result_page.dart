import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  // Weather
  List<_WeatherDay> _weather = const [];
  bool _loadingWeather = false;

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

      // Fetch weather for destination city
      _fetchWeather(to);
    } catch (_) {
      // Route display is best-effort only.
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  Future<void> _fetchWeather(LatLng coord) async {
    setState(() => _loadingWeather = true);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.open-meteo.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ));
      final r = await dio.get('/v1/forecast', queryParameters: {
        'latitude': coord.latitude,
        'longitude': coord.longitude,
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max,weathercode',
        'timezone': 'Africa/Casablanca',
        'forecast_days': 7,
      });
      final daily = r.data['daily'];
      if (daily == null) return;
      final dates = (daily['time'] as List?)?.cast<String>() ?? [];
      final maxT = (daily['temperature_2m_max'] as List?)?.cast<num>() ?? [];
      final minT = (daily['temperature_2m_min'] as List?)?.cast<num>() ?? [];
      final precip = (daily['precipitation_probability_max'] as List?) ?? [];
      final codes = (daily['weathercode'] as List?)?.cast<num>() ?? [];
      final days = <_WeatherDay>[];
      for (int i = 0; i < dates.length; i++) {
        days.add(_WeatherDay(
          date: dates[i],
          maxTemp: i < maxT.length ? maxT[i].toDouble() : 0,
          minTemp: i < minT.length ? minT[i].toDouble() : 0,
          precipProb: i < precip.length ? (precip[i] as num?)?.toInt() ?? 0 : 0,
          code: i < codes.length ? codes[i].toInt() : 0,
        ));
      }
      if (mounted) setState(() => _weather = days);
    } catch (_) {
      // Weather is best-effort.
    } finally {
      if (mounted) setState(() => _loadingWeather = false);
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
    final dio = Dio(BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'User-Agent': 'rihla_mobile/1.0'},
    ));
    final r = await dio.get('/search', queryParameters: {'q': city, 'format': 'json', 'limit': 1});
    final data = r.data;
    if (data is! List || data.isEmpty) return null;
    final item = data.first;
    if (item is! Map) return null;
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lng = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<List<LatLng>> _fetchRoute(LatLng from, LatLng to) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://router.project-osrm.org',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'User-Agent': 'rihla_mobile/1.0'},
    ));
    final r = await dio.get(
      '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
      queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
    );
    final data = r.data;
    if (data is! Map) return const [];
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return const [];
    final geometry = routes.first['geometry'];
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
        markers.add(Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 44,
          child: Tooltip(
            message: label,
            child: const Icon(Icons.location_on_rounded, size: 36, color: Color(0xFF0E5A6A)),
          ),
        ));
      }

      for (final route in dayRoutes) {
        if (route is! Map) continue;
        final coords = (route['coordinates'] as List?)?.cast<dynamic>() ?? const [];
        for (final c in coords) {
          if (c is! List || c.length < 2) continue;
          final lng = (c[0] as num?)?.toDouble();
          final lat = (c[1] as num?)?.toDouble();
          if (lat != null && lng != null) polylinePoints.add(LatLng(lat, lng));
        }
      }
    }

    if (_fromCityPoint != null) {
      markers.add(Marker(
        point: _fromCityPoint!,
        width: 44,
        height: 44,
        child: Tooltip(
          message: (data['fromCity'] ?? 'From').toString(),
          child: const Icon(Icons.trip_origin_rounded, size: 30, color: Color(0xFFB25520)),
        ),
      ));
    }

    final center = markers.isNotEmpty ? markers.first.point : const LatLng(33.5731, -7.5898);

    final polylines = <Polyline>[];
    if (_intercityRoute.isNotEmpty) {
      polylines.add(Polyline(points: _intercityRoute, color: const Color(0x3320535C), strokeWidth: 8));
      polylines.add(Polyline(points: _intercityRoute, color: const Color(0xFF20535C), strokeWidth: 4));
    }
    if (polylinePoints.isNotEmpty) {
      polylines.add(Polyline(points: polylinePoints, color: const Color(0xFF0E5A6A), strokeWidth: 4));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '${data['fromCity'] ?? '-'} → ${data['toCity'] ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF0C6171),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
        children: [
          // Trip summary card
          _buildSummaryCard(data, summary),
          const SizedBox(height: 12),

          // Map
          _buildMapCard(center, markers, polylines),
          const SizedBox(height: 12),

          // Weather forecast (creative feature)
          if (_loadingWeather)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (_weather.isNotEmpty)
            _buildWeatherCard(),

          if (_weather.isNotEmpty) const SizedBox(height: 12),

          // Day plans
          if (days.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 4),
              child: Text(
                'Your Day-by-Day Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0C6171)),
              ),
            ),
            ...days.asMap().entries.map((entry) => _buildDayCard(context, entry.key + 1, entry.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data, String summary) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C6171), Color(0xFF197278)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0C6171).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                '${data['startDate'] ?? '-'} → ${data['endDate'] ?? '-'}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(summary, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildMapCard(LatLng center, List<Marker> markers, List<Polyline> polylines) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: markers.isNotEmpty ? 11.5 : 5),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.rihla.mobile'),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final toCity = (widget.data['toCity'] ?? 'Destination').toString();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0C6171).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF0C6171), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weather Forecast', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Text('$toCity — next 7 days', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _weather.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final w = _weather[i];
                return Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C6171).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0C6171).withOpacity(0.15)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(w.dayLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(w.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text('${w.maxTemp.round()}°', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      Text('${w.minTemp.round()}°', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int idx, dynamic dayData) {
    final day = dayData is Map ? dayData : <String, dynamic>{};
    final events = (day['events'] as List?)?.cast<dynamic>() ?? const [];
    final transports = (day['transports'] as List?)?.cast<dynamic>() ?? const [];
    final hebergement = (day['hebergement'] is Map) ? day['hebergement'] as Map : null;
    final narrative = (day['summary'] ?? day['aiNarrative'] ?? '').toString();
    final date = (day['date'] ?? '').toString();

    final hasContent = events.isNotEmpty || transports.isNotEmpty || hebergement != null || narrative.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0C6171), Color(0xFF1A8B74)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(
                    child: Text('$idx', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day $idx', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    if (date.isNotEmpty) Text(date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          if (!hasContent)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Rest day — enjoy at your own pace 🌴', style: TextStyle(color: Colors.grey)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Narrative
                  if (narrative.isNotEmpty) ...[
                    Text(narrative, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF333333))),
                    const SizedBox(height: 14),
                  ],

                  // Activities timeline
                  ..._buildActivities(events, transports, hebergement),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActivities(List events, List transports, Map? hebergement) {
    final items = <Widget>[];

    for (int i = 0; i < events.length; i++) {
      final e = events[i] is Map ? events[i] as Map : {};
      final name = (e['nom'] ?? e['name'] ?? e['title'] ?? 'Event').toString();
      items.add(_ActivityRow(
        icon: Icons.festival_rounded,
        color: const Color(0xFFD98F39),
        label: name,
        tag: 'Event',
        isLast: i == events.length - 1 && transports.isEmpty && hebergement == null,
      ));
    }

    for (int i = 0; i < transports.length; i++) {
      final t = transports[i] is Map ? transports[i] as Map : {};
      final name = (t['nom'] ?? t['name'] ?? t['title'] ?? 'Transport').toString();
      items.add(_ActivityRow(
        icon: Icons.train_rounded,
        color: const Color(0xFF4C9DDE),
        label: name,
        tag: 'Transport',
        isLast: i == transports.length - 1 && hebergement == null,
      ));
    }

    if (hebergement != null) {
      final name = (hebergement['nom'] ?? hebergement['name'] ?? hebergement['title'] ?? 'Stay').toString();
      items.add(_ActivityRow(
        icon: Icons.hotel_rounded,
        color: const Color(0xFF0C6171),
        label: name,
        tag: 'Stay',
        isLast: true,
      ));
    }

    return items;
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String tag;
  final bool isLast;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.tag,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 2)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherDay {
  final String date;
  final double maxTemp;
  final double minTemp;
  final int precipProb;
  final int code;

  const _WeatherDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipProb,
    required this.code,
  });

  String get dayLabel {
    try {
      final d = DateTime.parse(date);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    } catch (_) {
      return date.length >= 5 ? date.substring(5) : date;
    }
  }

  String get icon {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    if (code <= 99) return '⛈️';
    return '🌤️';
  }
}
