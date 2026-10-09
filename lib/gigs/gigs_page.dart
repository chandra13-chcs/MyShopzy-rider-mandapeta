import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class GigsPage extends StatefulWidget {
  const GigsPage({super.key});

  @override
  State<GigsPage> createState() => _GigsPageState();
}

class _GigsPageState extends State<GigsPage> {
  static const List<_GigSlot> _gigSlots = [
    _GigSlot(label: '7:00–10:00', status: 'Available'),
    _GigSlot(label: '10:00–12:00', status: 'Available'),
    _GigSlot(label: '12:00–3:00', status: 'Available'),
    _GigSlot(label: '3:00–7:00', status: 'Available'),
    _GigSlot(label: '7:00–11:00', status: 'Available'),
  ];

  final Set<int> _bookedSlotIndices = {};

  void _bookGig(int index) {
    final slot = _gigSlots[index];
    if (slot.status != 'Available' || _bookedSlotIndices.contains(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This gig is no longer available.')),
      );
      return;
    }

    setState(() => _bookedSlotIndices.add(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gig booked for ${slot.label}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookedCount = _bookedSlotIndices.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Gigs')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bookedCount == 0 ? 'Book a gig slot' : 'Your gigs',
                          style: AppTheme.cardTitle,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          bookedCount == 0 ? 'Open slots' : '$bookedCount booked',
                          style: const TextStyle(
                            color: AppTheme.brand,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_gigSlots.length, (index) {
                    final slot = _gigSlots[index];
                    final isBooked = _bookedSlotIndices.contains(index);
                    final isAvailable = slot.status == 'Available';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(slot.label, style: AppTheme.cardTitle),
                                const SizedBox(height: 4),
                                Text(
                                  isBooked ? 'Booked for this slot' : slot.status,
                                  style: AppTheme.secondaryTextStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            key: ValueKey('gig-book-$index'),
                            onPressed: isAvailable && !isBooked
                                ? () => _bookGig(index)
                                : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(isBooked ? 'Booked' : 'Book gig'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GigSlot {
  const _GigSlot({required this.label, required this.status});

  final String label;
  final String status;
}