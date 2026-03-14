import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

void showTransportSearch(BuildContext context) {
  showCupertinoModalBottomSheet(
    context: context,
    expand: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TransportSearchSheet(),
  );
}

class _TransportSearchSheet extends StatefulWidget {
  const _TransportSearchSheet();

  @override
  State<_TransportSearchSheet> createState() => _TransportSearchSheetState();
}

class _TransportSearchSheetState extends State<_TransportSearchSheet> {
  final fromCity = TextEditingController();
  final toCity = TextEditingController();
  DateTime travelDate = DateTime.now().add(const Duration(days: 1));
  String type = 'TRAIN';

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: travelDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => travelDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('yyyy-MM-dd').format(travelDate);
    return SafeArea(
      child: Material(
        color: Colors.white.withOpacity(0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0x22000000),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transport search',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(dateStr),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['TRAIN', 'BUS', 'CAR', 'FLIGHT']
                    .map(
                      (v) => ChoiceChip(
                        label: Text(v),
                        selected: type == v,
                        onSelected: (_) => setState(() => type = v),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final f = fromCity.text.trim();
                    final t = toCity.text.trim();
                    if (f.isEmpty || t.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill both city names.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    context.push(
                      '/transport/results?fromCity=$f&toCity=$t&date=$dateStr&type=$type',
                    );
                  },
                  icon: const Icon(Icons.search_rounded),
                  label: const Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
