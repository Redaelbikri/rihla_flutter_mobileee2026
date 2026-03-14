import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '../../core/models/hebergement_model.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../hebergements/hebergements_service.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';

final _stayProvider = FutureProvider.autoDispose.family<HebergementModel, String>(
  (ref, id) => ref.read(hebergementsServiceProvider).getById(id),
);

class BookHotelPage extends ConsumerStatefulWidget {
  final String id;
  const BookHotelPage({super.key, required this.id});

  @override
  ConsumerState<BookHotelPage> createState() => _BookHotelPageState();
}

class _BookHotelPageState extends ConsumerState<BookHotelPage> {
  int _roomCount = 1;
  int _guestCount = 2;
  int _nightCount = 1;
  bool _loading = false;

  void _vibrate() => HapticFeedback.selectionClick();

  Future<void> _processBooking(HebergementModel stay, {bool payNow = false}) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(reservationsServiceProvider).createHebergement(
            hebergementId: widget.id,
            quantity: _roomCount,
          );

      if (payNow) {
        final total = (stay.pricePerNight ?? 0) * _roomCount * _nightCount;
        await ref.read(paymentsServiceProvider).payReservation(
              reservationId: res.id,
              amountMad: total.toDouble(),
            );
      }

      if (mounted) {
        _showConfirmation(payNow);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showConfirmation(bool paid) {
    showDialog(
      context: context,
      builder: (c) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Icon(Icons.check_circle, color: Color(0xFF26D0CE), size: 60),
          content: Text(
            paid ? "Your stay is booked and paid. Start packing!" : "Reservation confirmed successfully.",
            textAlign: TextAlign.center,
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Great!"))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_stayProvider(widget.id));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Book My Stay', style: GoogleFonts.philosopher(color: Colors.white)),
      ),
      body: data.when(
        data: (stay) => _buildUI(stay),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildUI(HebergementModel stay) {
    final totalPrice = (stay.pricePerNight ?? 0) * _roomCount * _nightCount;

    return Stack(
      children: [
        // Background Hero
        Positioned.fill(
          child: Image.network(
            stay.imageUrl ?? 'https://images.unsplash.com/photo-1541979017773-512371cb20bd',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stay.name,
                        style: GoogleFonts.philosopher(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      _buildCounter("Rooms", _roomCount, (v) => setState(() => _roomCount = v), Icons.bed_rounded),
                      _buildCounter("Guests", _guestCount, (v) => setState(() => _guestCount = v), Icons.people_alt_rounded),
                      _buildCounter("Nights", _nightCount, (v) => setState(() => _nightCount = v), Icons.nightlight_round),
                      
                      const Divider(height: 40, color: Colors.white24),
                      
                      // Recap Pricing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Estimated Total", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Text("$totalPrice MAD", style: GoogleFonts.notoSans(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFFD98F39))),
                            ],
                          ),
                          const Icon(Icons.info_outline, color: Colors.white54),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      PrimaryButton(
                        label: 'PAY NOW',
                        loading: _loading,
                        icon: Icons.credit_card_rounded,
                        onTap: () => _processBooking(stay, payNow: true),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _loading ? null : () => _processBooking(stay),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text('Reserve Without Paying', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, duration: 600.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(String title, int value, Function(int) onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
          Row(
            children: [
              _circleBtn(Icons.remove, () { if(value > 1) { _vibrate(); onChanged(value - 1); } }),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _circleBtn(Icons.add, () { _vibrate(); onChanged(value + 1); }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}