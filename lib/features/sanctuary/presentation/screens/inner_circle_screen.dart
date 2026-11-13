import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/sanctuary_models.dart';
import '../../domain/sanctuary_storage_service.dart';

class InnerCircleScreen extends ConsumerStatefulWidget {
  const InnerCircleScreen({super.key});

  @override
  ConsumerState<InnerCircleScreen> createState() => _InnerCircleScreenState();
}

class _InnerCircleScreenState extends ConsumerState<InnerCircleScreen> {
  List<NetworkingLead> _leads = [];
  Map<int, InnerCircleMetadata> _metaMap = {};
  bool _isLoading = true;
  bool _onlyInnerCircle = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final leads = await (db.select(db.networkingLeads)).get();
    final meta = await SanctuaryStorageService.loadInnerCircleMap();

    setState(() {
      _leads = leads;
      _metaMap = meta;
      _isLoading = false;
    });
  }

  Future<void> _editPersonDossier(NetworkingLead lead, InnerCircleMetadata? currentMeta) async {
    final meta = currentMeta ??
        InnerCircleMetadata(
          personId: lead.id,
          isInnerCircle: true,
          cadenceDays: 30,
          lastContactDate: DateTime.now(),
        );

    final interestsCtrl = TextEditingController(text: meta.personalInterests);
    final milestoneCtrl = TextEditingController(text: meta.upcomingMilestone ?? '');
    final giftCtrl = TextEditingController();
    final giftList = List<String>.from(meta.giftIdeas);
    final loreList = List<SharedLoreItem>.from(meta.sharedLore);
    final loreStoryCtrl = TextEditingController();
    bool isInner = meta.isInnerCircle;
    int cadence = meta.cadenceDays;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lead.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lead.organization ?? 'Personal Connection',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Inner Circle Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Inner Circle Sanctuary', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Track meaningful friendship & relationship warmth', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      value: isInner,
                      activeColor: const Color(0xFFFF7A00),
                      onChanged: (val) => setSheetState(() => isInner = val),
                    ),

                    if (isInner) ...[
                      const SizedBox(height: 12),
                      const Text('Check-in Cadence', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [14, 30, 60, 90].map((days) {
                          final isSel = cadence == days;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('$days Days'),
                              selected: isSel,
                              onSelected: (_) => setSheetState(() => cadence = days),
                              selectedColor: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                              backgroundColor: const Color(0xFF181D24),
                              labelStyle: TextStyle(
                                color: isSel ? const Color(0xFFFF7A00) : const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Upcoming Milestone
                      TextField(
                        controller: milestoneCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'Quiet Milestone (Birthday / Life Event)',
                          hintText: 'e.g. Birthday: 24th Nov • Book Launch: August',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          filled: true,
                          fillColor: const Color(0xFF181D24),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Personal Interests / Tastes
                      TextField(
                        controller: interestsCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'Personal Tastes & Details',
                          hintText: 'e.g. Loves Chimamanda books, size 42, cortado coffee...',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          filled: true,
                          fillColor: const Color(0xFF181D24),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Shared Lore & Memory Ledger
                      const Text('Shared Lore & Memory Ledger', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: loreStoryCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Shared memory / story...',
                                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFF181D24),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.bookmark_add_rounded, color: Color(0xFFFF7A00)),
                            onPressed: () {
                              final story = loreStoryCtrl.text.trim();
                              if (story.isNotEmpty) {
                                setSheetState(() {
                                  loreList.add(SharedLoreItem(dateText: '${DateTime.now().year}', story: story));
                                  loreStoryCtrl.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (loreList.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...loreList.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.history_edu_rounded, size: 14, color: Color(0xFFFF7A00)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${item.story} (${item.dateText})',
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white38),
                                onPressed: () => setSheetState(() => loreList.remove(item)),
                              ),
                            ],
                          ),
                        )),
                      ],
                      const SizedBox(height: 14),

                      // Gift Ideas
                      const Text('Gift Ideas & Wishlist', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: giftCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Add a gift idea...',
                                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFF181D24),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFF7A00)),
                            onPressed: () {
                              final text = giftCtrl.text.trim();
                              if (text.isNotEmpty) {
                                setSheetState(() {
                                  giftList.add(text);
                                  giftCtrl.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: giftList.map((g) {
                          return Chip(
                            label: Text(g, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: const Color(0xFF222832),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white54),
                            onDeleted: () => setSheetState(() => giftList.remove(g)),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final updated = InnerCircleMetadata(
                            personId: lead.id,
                            isInnerCircle: isInner,
                            cadenceDays: cadence,
                            lastContactDate: DateTime.now(), // reset check-in clock
                            personalInterests: interestsCtrl.text.trim(),
                            giftIdeas: giftList,
                            upcomingMilestone: milestoneCtrl.text.trim().isEmpty ? null : milestoneCtrl.text.trim(),
                            sharedLore: loreList,
                          );
                          await SanctuaryStorageService.saveInnerCircleMetadata(updated);
                          Navigator.pop(ctx);
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Inner Circle Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sayHello(NetworkingLead lead) async {
    final phone = lead.whatsapp ?? lead.phone;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}?text=${Uri.encodeComponent('Hi ${lead.name}, was just thinking of you! Hope you have a wonderful week.')}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final accent = studioTheme.primaryAccent;

    final displayedLeads = _onlyInnerCircle
        ? _leads.where((l) => _metaMap[l.id]?.isInnerCircle == true).toList()
        : _leads;

    final milestoneItems = <({String name, String milestone})>[];
    for (final lead in _leads) {
      final meta = _metaMap[lead.id];
      if (meta != null && meta.isInnerCircle && meta.upcomingMilestone != null && meta.upcomingMilestone!.isNotEmpty) {
        milestoneItems.add((name: lead.name, milestone: meta.upcomingMilestone!));
      }
    }

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'INNER CIRCLE',
          style: EtoleTypography.labelCaps(color: accent).copyWith(
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quiet Milestone Horizon Banner
            if (milestoneItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1710),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_twilight_rounded, color: Color(0xFFFF7A00), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quiet Milestone Horizon',
                            style: TextStyle(
                              color: Color(0xFFFF7A00),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            milestoneItems.map((m) => '${m.name}: ${m.milestone}').join('  •  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFFED7AA), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Filter Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Inner Circle Sanctuary'),
                    selected: _onlyInnerCircle,
                    onSelected: (_) => setState(() => _onlyInnerCircle = true),
                    selectedColor: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF14181E),
                    labelStyle: TextStyle(
                      color: _onlyInnerCircle ? const Color(0xFFFF7A00) : const Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: _onlyInnerCircle ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('All Contacts'),
                    selected: !_onlyInnerCircle,
                    onSelected: (_) => setState(() => _onlyInnerCircle = false),
                    selectedColor: accent.withValues(alpha: 0.25),
                    backgroundColor: const Color(0xFF14181E),
                    labelStyle: TextStyle(
                      color: !_onlyInnerCircle ? accent : const Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: !_onlyInnerCircle ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Leads List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedLeads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_border_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                'No inner circle contacts yet.\nTap any contact in "All Contacts" to add them to your Sanctuary.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: displayedLeads.length,
                          itemBuilder: (ctx, idx) {
                            final lead = displayedLeads[idx];
                            final meta = _metaMap[lead.id];
                            final isInner = meta?.isInnerCircle ?? false;
                            final warmth = meta?.warmthRatio ?? 1.0;
                            final daysSince = meta?.daysSinceLastContact ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12161D),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isInner
                                      ? const Color(0xFFFF7A00).withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (isInner ? const Color(0xFFFF7A00) : Colors.white24)
                                              .withValues(alpha: 0.16),
                                        ),
                                        child: Center(
                                          child: Text(
                                            lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: isInner ? const Color(0xFFFF7A00) : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lead.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              lead.organization ?? 'Personal Connection',
                                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 18),
                                        onPressed: () => _editPersonDossier(lead, meta),
                                      ),
                                      if (lead.phone != null || lead.whatsapp != null)
                                        IconButton(
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 18),
                                          onPressed: () => _sayHello(lead),
                                          tooltip: 'Say Hello (No Pitch)',
                                        ),
                                    ],
                                  ),

                                  if (isInner) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 14,
                                          color: warmth > 0.4 ? const Color(0xFFFF7A00) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$daysSince days since last connect (${meta?.cadenceDays}d cadence)',
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: warmth,
                                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          warmth > 0.5 ? const Color(0xFFFF7A00) : const Color(0xFFE53E3E),
                                        ),
                                        minHeight: 3,
                                      ),
                                    ),
                                    if (meta?.personalInterests.isNotEmpty == true) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tastes: ${meta!.personalInterests}',
                                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                                      ),
                                    ],
                                    if (meta?.upcomingMilestone != null && meta!.upcomingMilestone!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.cake_rounded, size: 13, color: Color(0xFFFFB800)),
                                          const SizedBox(width: 5),
                                          Text(
                                            meta!.upcomingMilestone!,
                                            style: const TextStyle(color: Color(0xFFFFB800), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (meta?.sharedLore.isNotEmpty == true) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.history_edu_rounded, size: 13, color: Color(0xFFFF7A00)),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Lore: "${meta!.sharedLore.last.story}" (${meta.sharedLore.last.dateText})',
                                              style: const TextStyle(color: Color(0xFFFED7AA), fontSize: 11, fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
