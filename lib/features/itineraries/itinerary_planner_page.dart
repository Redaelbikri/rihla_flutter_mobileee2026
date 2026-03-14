import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import 'itineraries_service.dart';

class ItineraryPlannerPage extends ConsumerStatefulWidget {
  const ItineraryPlannerPage({super.key});

  @override
  ConsumerState<ItineraryPlannerPage> createState() =>
      _ItineraryPlannerPageState();
}

class _ItineraryPlannerPageState extends ConsumerState<ItineraryPlannerPage> {
  final fromCity = TextEditingController();
  final toCity = TextEditingController();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  final days = TextEditingController(text: '3');
  final maxEventPrice = TextEditingController(text: '500');
  final maxNightPrice = TextEditingController(text: '800');
  String transportType = 'TRAIN';
  final limitPerDay = TextEditingController(text: '3');
  final selectedInterests = <String>{'culture', 'food'};
  bool loading = false;
  String? error;

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> generate() async {
    final from = fromCity.text.trim();
    final to = toCity.text.trim();
    if (from.isEmpty || to.isEmpty) {
      setState(() => error = 'Please provide from/to city names.');
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
            days: int.tryParse(days.text.trim()) ?? 3,
            interests: selectedInterests.toList(),
            maxEventPrice: double.tryParse(maxEventPrice.text.trim()) ?? 500,
            maxNightPrice: double.tryParse(maxNightPrice.text.trim()) ?? 800,
            transportType: transportType,
            limitPerDay: int.tryParse(limitPerDay.text.trim()) ?? 3,
          );
      if (!mounted) return;
      context.push('/itinerary/result', extra: r);
    } catch (_) {
      setState(
        () => error =
            'Itinerary generation failed. Please verify inputs and retry.',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Itinerary Planner'),
        actions: [
          TextButton(
            onPressed: () => context.push('/itineraries'),
            child: const Text('History'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          GlassCard(
            child: Column(
              children: [
                TextField(
                  controller: fromCity,
                  decoration: const InputDecoration(labelText: 'From city'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: toCity,
                  decoration: const InputDecoration(labelText: 'To city'),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start date',
                      suffixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    child: Text(dateStr),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: days,
                  decoration: const InputDecoration(labelText: 'Days'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: ['culture', 'food', 'nature', 'history', 'beach']
                        .map(
                          (v) => FilterChip(
                            label: Text(v),
                            selected: selectedInterests.contains(v),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedInterests.add(v);
                                } else {
                                  selectedInterests.remove(v);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: maxEventPrice,
                  decoration:
                      const InputDecoration(labelText: 'Max event price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: maxNightPrice,
                  decoration: const InputDecoration(labelText: 'Max night price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['TRAIN', 'BUS', 'TAXI', 'FLIGHT']
                      .map(
                        (v) => ChoiceChip(
                          label: Text(v),
                          selected: transportType == v,
                          onSelected: (_) => setState(() => transportType = v),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: limitPerDay,
                  decoration: const InputDecoration(labelText: 'Limit per day'),
                  keyboardType: TextInputType.number,
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Generate plan',
                  loading: loading,
                  icon: Icons.bolt_rounded,
                  onTap: generate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
