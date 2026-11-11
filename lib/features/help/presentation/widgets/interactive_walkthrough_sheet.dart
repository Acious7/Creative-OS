import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';

class WalkthroughSlide {
  final String chapter;
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final List<String> keyFeatures;
  final String powerShortcut;

  const WalkthroughSlide({
    required this.chapter,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.keyFeatures,
    required this.powerShortcut,
  });
}

class InteractiveWalkthroughSheet extends StatefulWidget {
  final int initialSlide;

  const InteractiveWalkthroughSheet({super.key, this.initialSlide = 0});

  static Future<void> show(BuildContext context, {int initialSlide = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InteractiveWalkthroughSheet(initialSlide: initialSlide),
    );
  }

  @override
  State<InteractiveWalkthroughSheet> createState() =>
      _InteractiveWalkthroughSheetState();
}

class _InteractiveWalkthroughSheetState
    extends State<InteractiveWalkthroughSheet> {
  late PageController _pageController;
  late int _currentPage;

  static const List<WalkthroughSlide> _slides = [
    WalkthroughSlide(
      chapter: 'CHAPTER 01 / 10 • STUDIO CANVAS',
      title: 'The Studio Hub & 6 Doorways',
      subtitle:
          'Your velvet obsidian command center navigating 6 integrated worlds.',
      accentColor: Color(0xFF38B6DB),
      icon: Icons.dashboard_customize_outlined,
      keyFeatures: [
        'Velvet obsidian studio canvas (#080B0F) with ambient key lighting and no visual clutter.',
        '6 Doorway Cards: Production, Network & CRM, Docs & Finance, Meetings, Stage & Card, Settings.',
        'High-contrast official branding: white typography, Bauhaus emblems, and live telemetry.',
        'Live Production Slate banner showcasing current project milestones and shoot schedules.',
      ],
      powerShortcut: 'From anywhere inside any world, tap the floating glass "< HUB" pill to instantly return home.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 02 / 10 • AI SUPERPOWERS',
      title: 'AI Pocket Chief of Staff',
      subtitle: 'Speak or dictate natural language notes to create CRM deals, contacts, and quotes.',
      accentColor: Color(0xFF38B6DB),
      icon: Icons.mic_rounded,
      keyFeatures: [
        'Tap "CHIEF OF STAFF" on the Hub to dictate while driving, walking on set, or between meetings.',
        'Natural speech parser extracts Contact Name, Organization, KES Deal Value, and Action Promise.',
        'Auto-classifies into production categories (Directing, Commercial, Documentary, Color Grading).',
        '1-Tap "Save & Draft Quote": Commits lead to database and pre-fills an official quotation instantly.',
      ],
      powerShortcut: 'Tap any of the quick preset chips (e.g. "Pitch Safaricom") for instant 1-tap testing.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 03 / 10 • CASHFLOW & TAXES',
      title: 'CEO Morning Radar & KRA Escrow',
      subtitle: 'A 30-second daily briefing of cashflow, aging debtors, and tax reserves.',
      accentColor: Color(0xFFF59E0B),
      icon: Icons.wb_sunny_rounded,
      keyFeatures: [
        'Verified Inflow: Live tracking of cleared KES revenue collected this month.',
        'Debtors Radar: Highlights unpaid and overdue invoices with days outstanding.',
        'KRA Tax Escrow Engine: Calculates 5% Withholding Tax (WHT) retained by clients and 16% VAT portion.',
        'Net Studio Margin: Tells you your true operating cashflow so tax season never surprises you.',
      ],
      powerShortcut: 'Tap "Chase" on any debtor to dispatch a customized payment reminder directly to WhatsApp.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 04 / 10 • CLIENT RELATIONS',
      title: 'Deals & Commercial Pipeline',
      subtitle: 'Track revenue opportunities from initial inquiry to signed commercial contract.',
      accentColor: Color(0xFFF59E0B),
      icon: Icons.hub_outlined,
      keyFeatures: [
        'Freelance Deal Stages: Inquiry / Lead ➔ Pitched / Proposal ➔ Negotiation ➔ Won / Active.',
        'Prominent Deal Value Chips: Displays estimated project budgets in Kenya Shillings (e.g. KES 850k).',
        'VIP Rolodex: Filter between ⭐ VIPs, 💼 Billable Clients, and 🏢 Agency Partners.',
        '1-Tap Stage Advancement: Move deals through your pipeline with a single tap as negotiations progress.',
      ],
      powerShortcut: 'Tap "Edit Deal" to customize project titles, budget valuations, and service offerings.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 05 / 10 • SPEED CLOSING',
      title: 'Smart 1-Tap WhatsApp Pitch Engine',
      subtitle: 'Personalized freelance pitching templates dispatched directly to client WhatsApp chats.',
      accentColor: Color(0xFF25D366),
      icon: Icons.send_rounded,
      keyFeatures: [
        'Post-Event Follow-up: References the festival, set, or mixer where you met and shares your reel.',
        'Rate Card & Commercial Proposal Pitch: Outlines 4K cinema directing and package deliverables.',
        'Quotation Check-In: Follows up on drafted quotations without feeling aggressive.',
        'VIP Network Nurture: Casual relationship touchpoint for agency executives and producers.',
      ],
      powerShortcut: 'Tap "Copy" to paste customized pitch templates into LinkedIn, Instagram DM, or Email.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 06 / 10 • COMMERCIAL BILLING',
      title: 'Docs & Financial Engine',
      subtitle: 'Executive quotations, tax invoices, production contracts, and payment receipts.',
      accentColor: Color(0xFF007A3D),
      icon: Icons.receipt_long_rounded,
      keyFeatures: [
        'Signature Quotation Breakdown: Cerulean Cyan card with asymmetric corners and KES prices.',
        '1-Tap Quick Creator: Instant creation of Quotes, Invoices, Contracts, or Receipts.',
        'Items Library: Pre-load your cinematography gear, day rates, and post-production rate cards.',
        'PDF Export & Dispatch: Generates print-ready PDFs dispatched via Gmail or WhatsApp.',
      ],
      powerShortcut: 'Filter documents with 1 tap using the top capsule selector (Quotes, Invoices, Contracts, Receipts).',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 07 / 10 • PRODUCTION SET',
      title: 'Production Slate & Crew Day Rates',
      subtitle: 'Manage active film projects, create professional call sheets, and book cinema crew.',
      accentColor: Color(0xFF00838F),
      icon: Icons.movie_creation_outlined,
      keyFeatures: [
        'Milestone Slate: Tracks shoot dates, script versions, delivery deadlines, and project statuses.',
        'Standard Call Sheet Generator: Generates industry-standard call sheets with weather, crew, and times.',
        'Crew Day-Rate Roster: Store your trusted DoPs, 1st ACs, Gaffers, Sound Mixers, and Drone Pilots.',
        'Negotiated Day Rates: Keep track of day rates (KES/day) with 1-tap WhatsApp availability check.',
      ],
      powerShortcut: 'Tap "Book" on any crew member to auto-generate a shoot availability inquiry on WhatsApp.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 08 / 10 • AUDIO INTELLIGENCE',
      title: 'Meetings & Speech Test Lab',
      subtitle: 'Log creative briefs, track promises made, and test on-device speech transcription.',
      accentColor: Color(0xFF2563EB),
      icon: Icons.forum_outlined,
      keyFeatures: [
        'Creative Brief Creator: Log client alignments, treatment reviews, and shoot scope discussions.',
        'Decision Logs: Records agreements made during meetings so clients cannot backtrack on scope.',
        'Speech Test Lab: Integrated on-device Whisper models (Tiny, Base, Small) for voice notes.',
        'Works 100% Offline: Transcribe voice briefs without uploading sensitive client audio to the cloud.',
      ],
      powerShortcut: 'Tap "Open Lab" in the Meetings hub to record and test speech recognition accuracy in real time.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 09 / 10 • DIGITAL STAGE',
      title: 'NFC & QR Card Broadcast',
      subtitle: 'Your virtual business card with live 3D sensor tilt, specular sheen, and NFC tap.',
      accentColor: Color(0xFFDC2626),
      icon: Icons.badge_outlined,
      keyFeatures: [
        '3D Interactive Sensor Tilt: Card reacts in 3D to device gyro tilt with dynamic tribal sheens.',
        'NFC Broadcast: Tap your phone against another device to wirelessly beam your digital business card.',
        'Instant vCard QR Code: Hold for full-screen high-brightness QR code scanning.',
        'Digital Portfolio Links: Direct links to your showreel, Vimeo, Instagram, and WhatsApp.',
      ],
      powerShortcut: 'Hold down anywhere on your business card to trigger full-screen presentation mode.',
    ),
    WalkthroughSlide(
      chapter: 'CHAPTER 10 / 10 • SECURE VAULT',
      title: 'Settings, Vault & Offline Backup',
      subtitle: 'AES-256 local encryption, biometric fingerprint lock, and 1-tap offline archives.',
      accentColor: Color(0xFF4F46E5),
      icon: Icons.shield_outlined,
      keyFeatures: [
        '100% Local Privacy: Your database, financial invoices, and contacts live on your phone, not in cloud servers.',
        'Biometric App Lock: Protect your commercial rates and contacts with fingerprint authentication.',
        'M-Pesa & Payment Profiles: Set up Paybill, Till, Equity, and KCB accounts for automatic invoice printing.',
        'Encrypted .etole Archive: Export or restore your entire studio vault in seconds with 1 tap.',
      ],
      powerShortcut: 'In Settings, tap the version number 5 times to unlock the hidden Studio Design System Gallery.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialSlide;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _slides[_currentPage];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: const Color(0xFB0A0D11),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
              top: BorderSide(
                color: current.accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Pill Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: current.accentColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: current.accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'STUDIO FIELD MANUAL',
                            style: TextStyle(
                              color: current.accentColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: EtoleColors.creamMuted,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Carousel PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (idx) {
                    EtoleHaptics.selection();
                    setState(() => _currentPage = idx);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chapter Tag
                          Text(
                            slide.chapter,
                            style: TextStyle(
                              color: slide.accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Title & Subtitle
                          Text(
                            slide.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Hero Visual Badge
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  slide.accentColor.withValues(alpha: 0.22),
                                  const Color(0xFF13171B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              border: Border.all(
                                color: slide.accentColor.withValues(alpha: 0.4),
                                width: 1.1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: slide.accentColor.withValues(
                                      alpha: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: slide.accentColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'EXECUTIVE SUPERPOWER',
                                        style: TextStyle(
                                          color: slide.accentColor,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Engineered for Film & Creative Moguls',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Key Features
                          const Text(
                            'HOW TO USE THIS MODULE',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          ...slide.keyFeatures.map((feat) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: slide.accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      feat,
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 12.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),

                          // Power Shortcut Capsule
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14171B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'MOGUL POWER SHORTCUT',
                                        style: TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        slide.powerShortcut,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation & Dots
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    if (_currentPage > 0)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text(
                          'Previous',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      const SizedBox(width: 80),

                    // Dot indicators
                    Row(
                      children: List.generate(_slides.length, (i) {
                        final isSel = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: isSel ? 16 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSel
                                ? current.accentColor
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    // Next / Finish Button
                    if (_currentPage < _slides.length - 1)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: current.accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        label: const Text(
                          'Next',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A3D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Got It!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
