import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'itineraries_service.dart';

class ItineraryPlannerPage extends ConsumerStatefulWidget {
  const ItineraryPlannerPage({super.key});

  @override
  ConsumerState<ItineraryPlannerPage> createState() =>
      _ItineraryPlannerPageState();
}

class _ItineraryPlannerPageState extends ConsumerState<ItineraryPlannerPage>
    with SingleTickerProviderStateMixin {
  final fromCity = TextEditingController();
  final toCity = TextEditingController();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  int tripDays = 3;
  double maxEventPrice = 500;
  double maxNightPrice = 800;
  String transportType = 'TRAIN';
  int limitPerDay = 3;
  final selectedInterests = <String>{'culture', 'food'};
  bool loading = false;
  String? error;

  late AnimationController _swapController;

  static const _interests = [
    ('culture', Icons.museum_rounded, Color(0xFF7C4DFF)),
    ('food', Icons.restaurant_rounded, Color(0xFFE53935)),
    ('nature', Icons.forest_rounded, Color(0xFF43A047)),
    ('history', Icons.account_balance_rounded, Color(0xFFBF8B2E)),
    ('beach', Icons.beach_access_rounded, Color(0xFF0288D1)),
  ];

  static const _transports = [
    ('TRAIN', Icons.train_rounded),
    ('BUS', Icons.directions_bus_rounded),
    ('CAR', Icons.directions_car_rounded),
    ('FLIGHT', Icons.flight_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _swapController.dispose();
    fromCity.dispose();
    toCity.dispose();
    super.dispose();
  }

  void _swapCities() {
    HapticFeedback.selectionClick();
    _swapController.forward(from: 0);
    final tmp = fromCity.text;
    fromCity.text = toCity.text;
    toCity.text = tmp;
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> generate() async {
    final from = fromCity.text.trim();
    final to = toCity.text.trim();
    if (from.isEmpty || to.isEmpty) {
      setState(() => error = 'Please enter both origin and destination cities.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await ref.read(itinerariesServiceProvider).generate(
            fromCity: from,
            toCity: to,
            startDate: selectedDate,
            days: tripDays,
            interests: selectedInterests.toList(),
            maxEventPrice: maxEventPrice,
            maxNightPrice: maxNightPrice,
            transportType: transportType,
            limitPerDay: limitPerDay,
          );
      if (!mounted) return;
      context.push('/itinerary/result', extra: r);
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0E3D45),
                      Color(0xFF1A5E6A),
                      Color(0xFFBF8B2E),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Itinerary Planner',
                                    style: t.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Your perfect Morocco trip, built by AI',
                                    style: t.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.78),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('AI Itinerary'),
            ),
            actions: [
              TextButton(
                onPressed: () => context.push('/itineraries'),
                child: const Text('History',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Route Section ───────────────────────────────────
                  _SectionHeader(
                    icon: Icons.route_rounded,
                    label: 'Route',
                    color: scheme.primary,
                  ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  _RouteInputCard(
                    fromCity: fromCity,
                    toCity: toCity,
                    onSwap: _swapCities,
                    swapController: _swapController,
                  ).animate().fadeIn(delay: 60.ms, duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // ─── Dates Section ───────────────────────────────────
                  _SectionHeader(
                    icon: Icons.calendar_month_rounded,
                    label: 'Dates',
                    color: const Color(0xFFBF8B2E),
                  ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _DateCard(
                          date: selectedDate,
                          onTap: pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DaysCard(
                          days: tripDays,
                          onChanged: (v) => setState(() => tripDays = v),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // ─── Transport Type ───────────────────────────────────
                  _SectionHeader(
                    icon: Icons.commute_rounded,
                    label: 'Transport',
                    color: const Color(0xFF1565C0),
                  ).animate().fadeIn(delay: 120.ms, duration: 350.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  _TransportSelector(
                    selected: transportType,
                    options: _transports,
                    onSelect: (v) => setState(() => transportType = v),
                  ).animate().fadeIn(delay: 140.ms, duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // ─── Interests ────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.interests_rounded,
                    label: 'Interests',
                    color: const Color(0xFF7C4DFF),
                  ).animate().fadeIn(delay: 160.ms, duration: 350.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interests.map((item) {
                      final (label, icon, color) = item;
                      final sel = selectedInterests.contains(label);
                      return AnimatedContainer(
                        duration: 200.ms,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (sel) {
                                selectedInterests.remove(label);
                              } else {
                                selectedInterests.add(label);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? color.withOpacity(0.15)
                                  : scheme.surfaceContainerHighest
                                      .withOpacity(0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: sel
                                    ? color.withOpacity(0.6)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 16,
                                    color: sel
                                        ? color
                                        : scheme.onSurface.withOpacity(0.5)),
                                const SizedBox(width: 6),
                                Text(
                                  label[0].toUpperCase() + label.substring(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: sel
                                        ? color
                                        : scheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 180.ms, duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // ─── Budget ───────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Budget',
                    color: const Color(0xFF2E7D32),
                  ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: scheme.outlineVariant.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _BudgetSlider(
                          label: 'Max event price',
                          icon: Icons.festival_rounded,
                          value: maxEventPrice,
                          min: 50,
                          max: 2000,
                          suffix: 'MAD',
                          color: const Color(0xFF1A5E6A),
                          onChanged: (v) => setState(() => maxEventPrice = v),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _BudgetSlider(
                          label: 'Max night price',
                          icon: Icons.hotel_rounded,
                          value: maxNightPrice,
                          min: 100,
                          max: 3000,
                          suffix: 'MAD/night',
                          color: const Color(0xFFBF8B2E),
                          onChanged: (v) => setState(() => maxNightPrice = v),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_view_day_rounded,
                                size: 18, color: Color(0xFF7C4DFF)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Activities per day',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color:
                                            scheme.onSurface.withOpacity(0.75),
                                      )),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                        5,
                                        (i) => GestureDetector(
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                setState(
                                                    () => limitPerDay = i + 1);
                                              },
                                              child: AnimatedContainer(
                                                duration: 150.ms,
                                                width: 36,
                                                height: 36,
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                decoration: BoxDecoration(
                                                  color: limitPerDay == i + 1
                                                      ? const Color(0xFF7C4DFF)
                                                      : const Color(0xFF7C4DFF)
                                                          .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${i + 1}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: limitPerDay ==
                                                              i + 1
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF7C4DFF),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 220.ms, duration: 400.ms).slideY(begin: 0.1),

                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ─── Generate button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: AnimatedContainer(
                      duration: 200.ms,
                      child: ElevatedButton(
                        onPressed: loading ? null : generate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5E6A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: loading ? 0 : 4,
                          shadowColor:
                              const Color(0xFF1A5E6A).withOpacity(0.4),
                        ),
                        child: loading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Building your plan...',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text('Generate Itinerary',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16)),
                                ],
                              ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 280.ms, duration: 400.ms).slideY(begin: 0.15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Route Input Card ──────────────────────────────────────────────────────────
class _RouteInputCard extends StatelessWidget {
  final TextEditingController fromCity;
  final TextEditingController toCity;
  final VoidCallback onSwap;
  final AnimationController swapController;

  const _RouteInputCard({
    required this.fromCity,
    required this.toCity,
    required this.onSwap,
    required this.swapController,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: fromCity,
                    decoration: InputDecoration(
                      labelText: 'From',
                      prefixIcon: const Icon(Icons.flight_takeoff_rounded,
                          size: 18),
                      prefixIconColor:
                          scheme.primary.withOpacity(0.7),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: scheme.outlineVariant.withOpacity(0.4)),
                  TextField(
                    controller: toCity,
                    decoration: InputDecoration(
                      labelText: 'To',
                      prefixIcon: const Icon(Icons.flight_land_rounded,
                          size: 18),
                      prefixIconColor:
                          const Color(0xFFBF8B2E).withOpacity(0.7),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: scheme.outlineVariant.withOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedBuilder(
              animation: swapController,
              builder: (context, _) => Transform.rotate(
                angle: swapController.value * 3.14159,
                child: IconButton(
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_vert_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Card ─────────────────────────────────────────────────────────────────
class _DateCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateCard({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFBF8B2E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  size: 18, color: Color(0xFFBF8B2E)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start date',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded,
                size: 16, color: scheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ─── Days Card ─────────────────────────────────────────────────────────────────
class _DaysCard extends StatelessWidget {
  final int days;
  final void Function(int) onChanged;
  const _DaysCard({required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Days',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 4),
          Text('$days',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 26)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallCircleBtn(
                icon: Icons.remove,
                onTap: () {
                  if (days > 1) onChanged(days - 1);
                },
              ),
              const SizedBox(width: 8),
              _SmallCircleBtn(
                icon: Icons.add,
                onTap: () {
                  if (days < 14) onChanged(days + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallCircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: scheme.onPrimaryContainer),
      ),
    );
  }
}

// ─── Transport Selector ────────────────────────────────────────────────────────
class _TransportSelector extends StatelessWidget {
  final String selected;
  final List<(String, IconData)> options;
  final void Function(String) onSelect;
  const _TransportSelector(
      {required this.selected,
      required this.options,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: options.map((item) {
        final (label, icon) = item;
        final sel = selected == label;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(label);
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF1565C0).withOpacity(0.12)
                    : scheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel
                      ? const Color(0xFF1565C0).withOpacity(0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: sel
                        ? const Color(0xFF1565C0)
                        : scheme.onSurface.withOpacity(0.45),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: sel
                          ? const Color(0xFF1565C0)
                          : scheme.onSurface.withOpacity(0.45),
                    ),
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

// ─── Budget Slider ─────────────────────────────────────────────────────────────
class _BudgetSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final Color color;
  final void Function(double) onChanged;

  const _BudgetSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: scheme.onSurface.withOpacity(0.75),
                  )),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${value.toStringAsFixed(0)} $suffix',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: color),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            overlayColor: color.withOpacity(0.12),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 50).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
