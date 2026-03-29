import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/event_model.dart';
import '../../core/models/hebergement_model.dart';
import '../../core/ui/safe_network_image.dart';
import '../events/events_service.dart';
import '../hebergements/hebergements_service.dart';
import '../notifications/notifications_service.dart';
import '../profile/profile_service.dart';

final _homeLoadProvider = FutureProvider((ref) async {
  final events = await ref.read(eventsServiceProvider).list();
  final stays = await ref.read(hebergementsServiceProvider).list();
  return {
    'events': events,
    'stays': stays,
  };
});

final _userNameProvider = FutureProvider.autoDispose((ref) async {
  try {
    final u = await ref.read(profileServiceProvider).me();
    return u.fullName ?? u.email ?? '';
  } catch (_) {
    return '';
  }
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _destinationCtrl = TextEditingController();
  final _datesCtrl = TextEditingController();
  final _peopleCtrl = TextEditingController(text: '2 travelers');

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _datesCtrl.dispose();
    _peopleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_homeLoadProvider);
    final userName = ref.watch(_userNameProvider).value ?? '';
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        _HeroBanner(userName: _firstName(userName), unread: unread)
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.05, end: 0),
        const SizedBox(height: 14),
        _SearchPanel(
          destinationCtrl: _destinationCtrl,
          datesCtrl: _datesCtrl,
          peopleCtrl: _peopleCtrl,
          onPickDates: () async {
            final now = DateTime.now();
            final range = await showDateRangePicker(
              context: context,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              initialDateRange: DateTimeRange(start: now, end: now.add(const Duration(days: 3))),
            );
            if (range != null) {
              setState(() {
                _datesCtrl.text = '${range.start.month}/${range.start.day} - ${range.end.month}/${range.end.day}';
              });
            }
          },
          onSearch: () => context.go('/app?tab=1'),
        ).animate().fadeIn(delay: 80.ms, duration: 280.ms),
        const SizedBox(height: 20),
        const _Header(title: 'Featured Destinations'),
        const SizedBox(height: 10),
        data.when(
          data: (m) => _FeaturedDestinations(
            events: (m['events'] as List<EventModel>).take(5).toList(),
            onTap: (id) => context.push('/event/$id'),
          ),
          loading: () => const _LoadingStrip(),
          error: (e, _) => _ErrorBox(message: e.toString()),
        ),
        const SizedBox(height: 20),
        const _Header(title: 'Categories'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                icon: Icons.hotel_rounded,
                label: 'Hotels',
                color: const Color(0xFF2D8BFF),
                onTap: () => context.go('/app?tab=1'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryCard(
                icon: Icons.flight_rounded,
                label: 'Flights',
                color: const Color(0xFF22B8CF),
                onTap: () => context.go('/app?tab=1'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryCard(
                icon: Icons.map_rounded,
                label: 'Trips',
                color: const Color(0xFF4A7FF7),
                onTap: () => context.go('/app?tab=1'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _Header(title: 'Recommended For You'),
        const SizedBox(height: 10),
        data.when(
          data: (m) => _RecommendedList(
            stays: (m['stays'] as List<HebergementModel>).take(5).toList(),
            onTap: (id) => context.push('/stay/$id'),
          ),
          loading: () => const _LoadingList(),
          error: (e, _) => _ErrorBox(message: e.toString()),
        ),
      ],
    );
  }

  String _firstName(String fullName) {
    if (fullName.isEmpty) return 'Traveler';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }
}

class _HeroBanner extends StatelessWidget {
  final String userName;
  final int unread;

  const _HeroBanner({required this.userName, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B74E4), Color(0xFF3BA2FF), Color(0xFF77D3F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B74E4).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $userName',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Where do you want to go next?',
                  style: TextStyle(color: Colors.white, fontSize: 24, height: 1.2, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final TextEditingController destinationCtrl;
  final TextEditingController datesCtrl;
  final TextEditingController peopleCtrl;
  final VoidCallback onPickDates;
  final VoidCallback onSearch;

  const _SearchPanel({
    required this.destinationCtrl,
    required this.datesCtrl,
    required this.peopleCtrl,
    required this.onPickDates,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: destinationCtrl,
            decoration: const InputDecoration(
              hintText: 'Destination',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: datesCtrl,
                  readOnly: true,
                  onTap: onPickDates,
                  decoration: const InputDecoration(
                    hintText: 'Dates',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: peopleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'People',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Search Trips'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedDestinations extends StatelessWidget {
  final List<EventModel> events;
  final ValueChanged<String> onTap;

  const _FeaturedDestinations({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final e = events[i];
          return GestureDetector(
            onTap: () => onTap(e.id),
            child: Container(
              width: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(imageUrl: e.imageUrl, fit: BoxFit.cover),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Color(0xB3000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.city ?? 'Morocco',
                            style: const TextStyle(color: Color(0xFFCCE3FF), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecommendedList extends StatelessWidget {
  final List<HebergementModel> stays;
  final ValueChanged<String> onTap;

  const _RecommendedList({required this.stays, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stays.map((stay) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onTap(stay.id),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                    child: SizedBox(
                      width: 98,
                      height: 98,
                      child: SafeNetworkImage(imageUrl: stay.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stay.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stay.city ?? '-',
                          style: const TextStyle(color: Color(0xFF6A7F9C), fontSize: 13),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${(stay.pricePerNight ?? 0).toStringAsFixed(0)} MAD / night',
                          style: const TextStyle(
                            color: Color(0xFF1B74E4),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.chevron_right_rounded, color: Color(0xFF8AA0BC)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: widget.color, size: 24),
              const SizedBox(height: 6),
              Text(widget.label, style: TextStyle(fontWeight: FontWeight.w700, color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF173B63)));
  }
}

class _LoadingStrip extends StatelessWidget {
  const _LoadingStrip();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFB3261E))),
    );
  }
}


