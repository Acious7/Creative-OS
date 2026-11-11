import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/cards_providers.dart';

class EventsListScreen extends ConsumerWidget {
  final bool isSubView;

  const EventsListScreen({super.key, this.isSubView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(networkingEventsProvider);
    final activeBrand = ref.watch(activeBrandProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isSubView
          ? null
          : AppBar(
              title: const Text('Occasions & Events'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  tooltip: 'Add New Event',
                  onPressed: () =>
                      _showAddEventDialog(context, ref, activeBrand!),
                ),
              ],
            ),
      floatingActionButton: isSubView
          ? FloatingActionButton.extended(
              onPressed: () {
                if (activeBrand != null)
                  _showAddEventDialog(context, ref, activeBrand);
              },
              backgroundColor: accent,
              icon: const Icon(
                Icons.add_location_alt_outlined,
                color: Colors.white,
              ),
              label: const Text(
                'Add Occasion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.event_available_outlined,
              title: 'No Events Registered',
              description: 'Add an upcoming film festival or conference and turn on Event Mode to auto-tag leads you meet.',
              actionLabel: 'Add Event',
              onAction: () {
                if (activeBrand != null)
                  _showAddEventDialog(context, ref, activeBrand);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDesignTokens.space16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isActive = event.isEventModeActive;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDesignTokens.space12),
                child: AppCard(
                  variant: AppCardVariant.surface,
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeColor: Colors.deepOrange,
                            onChanged: (val) async {
                              final db = ref.read(databaseProvider);
                              // 1. Turn off all event modes for brand
                              await (db.update(db.networkingEvents)..where(
                                    (t) => t.brandId.equals(event.brandId),
                                  ))
                                  .write(
                                    const NetworkingEventsCompanion(
                                      isEventModeActive: drift.Value(false),
                                    ),
                                  );
                              // 2. Set this event's mode
                              if (val) {
                                await (db.update(
                                  db.networkingEvents,
                                )..where((t) => t.id.equals(event.id))).write(
                                  const NetworkingEventsCompanion(
                                    isEventModeActive: drift.Value(true),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'EVENT MODE ACTIVE (AUTO-TAGGING)',
                            style: TextStyle(
                              color: Colors.deepOrange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.format(event.startDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (event.location != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (event.notes != null && event.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            avatar: Icon(
                              Icons.category_outlined,
                              size: 14,
                              color: accent,
                            ),
                            label: Text(
                              event.eventType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              final db = ref.read(databaseProvider);
                              await (db.update(
                                db.networkingEvents,
                              )..where((t) => t.id.equals(event.id))).write(
                                const NetworkingEventsCompanion(
                                  isDeleted: drift.Value(true),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref, Brand brand) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    String eventType = 'conference';
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Networking Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Event Name *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: eventType,
                    decoration: const InputDecoration(labelText: 'Event Type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'festival',
                        child: Text('Film Festival'),
                      ),
                      DropdownMenuItem(
                        value: 'conference',
                        child: Text('Conference / Expo'),
                      ),
                      DropdownMenuItem(
                        value: 'screening',
                        child: Text('Premiere / Screening'),
                      ),
                      DropdownMenuItem(
                        value: 'networking',
                        child: Text('Networking Mixer'),
                      ),
                      DropdownMenuItem(
                        value: 'workshop',
                        child: Text('Workshop / Masterclass'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => eventType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Venue',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    final db = ref.read(databaseProvider);
                    await db
                        .into(db.networkingEvents)
                        .insert(
                          NetworkingEventsCompanion.insert(
                            brandId: brand.id,
                            name: nameController.text.trim(),
                            startDate: startDate,
                            location: drift.Value(
                              locationController.text.trim(),
                            ),
                            notes: drift.Value(notesController.text.trim()),
                            eventType: drift.Value(eventType),
                          ),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Event'),
              ),
            ],
          );
        },
      ),
    );
  }
}
