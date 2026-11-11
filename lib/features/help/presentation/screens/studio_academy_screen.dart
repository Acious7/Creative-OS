import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../widgets/interactive_walkthrough_sheet.dart';

class StudioAcademyScreen extends StatefulWidget {
  const StudioAcademyScreen({super.key});

  @override
  State<StudioAcademyScreen> createState() => _StudioAcademyScreenState();
}

class _StudioAcademyScreenState extends State<StudioAcademyScreen> {
  int _selectedTab = 0; // 0: Feature Guides, 1: Sitemap & Shortcuts, 2: Mogul Playbooks, 3: FAQ

  final List<String> _tabs = [
    'Feature Guides',
    'Sitemap & Shortcuts',
    'Mogul Playbooks',
    'FAQ & Vault Help',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STUDIO ACADEMY & MANUAL',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.2,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Interactive Guides, Sitemap & Playbooks',
                          style: TextStyle(
                            color: Color(0xFF38B6DB),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick Launch Tour Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38B6DB),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => InteractiveWalkthroughSheet.show(context),
                    icon: const Icon(Icons.auto_stories_rounded, size: 14),
                    label: const Text(
                      'Tour',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Interactive Tour Hero Launcher Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2631), Color(0xFF10151C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: const Color(0xFF38B6DB).withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38B6DB).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF38B6DB).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF38B6DB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '10-CHAPTER FIELD MANUAL',
                            style: TextStyle(
                              color: Color(0xFF38B6DB),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Interactive Guided Studio Tour',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Learn every feature, shortcut, and workflow.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38B6DB),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () =>
                          InteractiveWalkthroughSheet.show(context),
                      child: const Text(
                        'Start Tour',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 3. Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final isSel = _selectedTab == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          EtoleHaptics.light();
                          setState(() => _selectedTab = i);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF38B6DB)
                                      .withValues(alpha: 0.22)
                                : const Color(0xFF13171B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF38B6DB)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSel ? 1.2 : 0.8,
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                              fontSize: 11.5,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 4. Tab Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  if (_selectedTab == 0) _buildFeatureGuidesTab(),
                  if (_selectedTab == 1) _buildSitemapTab(),
                  if (_selectedTab == 2) _buildPlaybooksTab(),
                  if (_selectedTab == 3) _buildFaqTab(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 0: FEATURE GUIDES ---
  Widget _buildFeatureGuidesTab() {
    final modules = [
      {
        'title': 'AI Pocket Chief of Staff',
        'badge': 'NATURAL VOICE / TEXT',
        'color': const Color(0xFF38B6DB),
        'icon': Icons.mic_rounded,
        'desc': 'Dictate natural language voice notes or text anywhere. Automatically extracts Contact Name, Organization, Deal Value in KES, and Promises with deadlines. Generates pre-filled quotations in 1 tap.',
        'slideIndex': 1,
      },
      {
        'title': 'CEO Morning Radar & KRA Escrow',
        'badge': 'CASHFLOW & TAX',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.wb_sunny_rounded,
        'desc': '30-second executive briefing showing verified inflow, aging debtors, and automatic KRA Tax Escrow calculation (5% Withholding Tax + 16% VAT portion). Includes 1-tap WhatsApp payment chaser.',
        'slideIndex': 2,
      },
      {
        'title': 'Deals & Commercial CRM Pipeline',
        'badge': 'REVENUE PIPELINE',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.hub_outlined,
        'desc': 'Organizes commercial opportunities into 5 freelance stages: Inquiry, Pitched, Negotiation, Won, and Archived. Features KES valuation chips and 1-tap stage advancement.',
        'slideIndex': 3,
      },
      {
        'title': 'Smart 1-Tap WhatsApp Pitch Engine',
        'badge': 'SPEED CLOSING',
        'color': const Color(0xFF25D366),
        'icon': Icons.send_rounded,
        'desc': 'Dispatches personalized freelance pitch templates directly to client WhatsApp chats (Post-Event Follow-up, Rate Card Pitch, Quotation Alignment, VIP Check-in).',
        'slideIndex': 4,
      },
      {
        'title': 'Docs & Commercial Finance',
        'badge': 'BILLING & QUOTES',
        'color': const Color(0xFF007A3D),
        'icon': Icons.receipt_long_rounded,
        'desc': 'Draft official Quotations, Tax Invoices, Production Contracts, and Payment Receipts. Pre-loads items library and exports print-ready PDFs dispatched via Gmail or WhatsApp.',
        'slideIndex': 5,
      },
      {
        'title': 'Production Slate & Crew Day Rates',
        'badge': 'PRODUCTION SET',
        'color': const Color(0xFF00838F),
        'icon': Icons.movie_creation_outlined,
        'desc': 'Manage cinema projects, standard call sheets, gear checklists, and a dedicated Crew Roster with negotiated day rates (KES/day) and 1-tap WhatsApp shoot booking.',
        'slideIndex': 6,
      },
      {
        'title': 'Meetings & Speech Transcription Lab',
        'badge': 'MEETING MEMORY',
        'color': const Color(0xFF2563EB),
        'icon': Icons.forum_outlined,
        'desc': 'Stream creative briefs, decision logs, and client alignment records from database. Includes on-device Whisper speech recognition test lab running 100% offline.',
        'slideIndex': 7,
      },
      {
        'title': 'Digital Stage & NFC / QR Broadcast',
        'badge': 'DIGITAL IDENTITY',
        'color': const Color(0xFFDC2626),
        'icon': Icons.badge_outlined,
        'desc': 'Virtual business card with real-time 3D sensor tilt, specular tribal sheen, wireless NFC pulse beaming, and high-brightness QR presentation mode.',
        'slideIndex': 8,
      },
      {
        'title': 'Settings & Offline AES-256 Vault',
        'badge': 'SECURITY & SYSTEM',
        'color': const Color(0xFF4F46E5),
        'icon': Icons.shield_outlined,
        'desc': '100% offline local privacy with SQLite AES-256 encryption, fingerprint app lock, M-Pesa Till & Bank profiles, and 1-tap encrypted .etole archive export/restore.',
        'slideIndex': 9,
      },
      {
        'title': 'Studio Watchdogs & Custom Automation Recipes',
        'badge': 'IFTTT & WATCHDOGS',
        'color': const Color(0xFF00E5FF),
        'icon': Icons.bolt_rounded,
        'desc': '9 native background watchdogs (overdue chasers, stale deals, VIP reconnect, gear reconcile) plus visual Custom Recipe Builder for WHEN ➔ AND IF ➔ THEN autonomous pipelines.',
        'slideIndex': 9,
      },
    ];

    return Column(
      children: modules.map((mod) {
        final color = mod['color'] as Color;
        final slideIdx = mod['slideIndex'] as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF14171B),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.28),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      mod['badge'] as String,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: const Size(0, 26),
                      foregroundColor: color,
                    ),
                    onPressed: () => InteractiveWalkthroughSheet.show(
                      context,
                      initialSlide: slideIdx,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                    label: const Text(
                      'Read Tour',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(mod['icon'] as IconData, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    mod['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                mod['desc'] as String,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- TAB 1: SITEMAP & SHORTCUTS ---
  Widget _buildSitemapTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSitemapCard(
          title: 'THE STUDIO HUB (ROOT)',
          icon: Icons.home_rounded,
          color: const Color(0xFF38B6DB),
          items: [
            '• Header Card: Official logo, Nairobi Kenya location, PRESENT CARD shortcut.',
            '• Chief of Staff Capsule: Tap to dictate note or auto-draft quotation.',
            '• Morning Radar Capsule: Tap to review Cashflow, Debtors & KRA tax escrow.',
            '• Current Production Slate: Live dynamic card showing active film project.',
            '• 6 Studio Doorways: Production, Network & CRM, Docs, Meetings, Stage, Settings.',
          ],
        ),
        const SizedBox(height: 10),
        _buildSitemapCard(
          title: 'DOORWAY 1: PRODUCTION SLATE',
          icon: Icons.movie_creation_outlined,
          color: const Color(0xFF00838F),
          items: [
            '• Tab 0 (Projects): Active shoots, scripts, deliverables, milestones.',
            '• Tab 1 (Call Sheets): Industry-standard call sheets with call times & PDF export.',
            '• Tab 2 (Crew Roster): DoPs, 1st ACs, Gaffers with day rates & WhatsApp booking.',
            '• Tab 3 (Gear Locker): Camera, Lens, Drone, Lighting inventory with packed toggles.',
          ],
        ),
        const SizedBox(height: 10),
        _buildSitemapCard(
          title: 'DOORWAY 2: NETWORK & CRM',
          icon: Icons.hub_outlined,
          color: const Color(0xFFF59E0B),
          items: [
            '• Tab 0 (Deals & Pipeline): Inquiry ➔ Pitched ➔ Negotiation ➔ Won stages.',
            '• Tab 1 (VIP Rolodex): VIPs ⭐, Clients 💼, and Agency rolodex.',
            '• Tab 2 (Occasions): Film sets, festivals, creative mixers & people met.',
            '• Tab 3 (Radar & Pitch): Follow-up queue with 1-tap WhatsApp pitching.',
          ],
        ),
        const SizedBox(height: 10),
        _buildSitemapCard(
          title: 'DOORWAY 3: DOCS & FINANCE',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF007A3D),
          items: [
            '• Telemetry Strip: Billed, Collected revenue, and Pitched quotes in KES.',
            '• Quick Create Bar: Quotation, Invoice, Contract, and Payment Receipt.',
            '• Filter Pills: Instant filter by document type.',
            '• Unified Search: Search by doc number, client, item name, or amount.',
          ],
        ),
        const SizedBox(height: 14),

        // Secret Gestures & Shortcuts
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF14171B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'EXECUTIVE GESTURE SHORTCUTS',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '• Return Home: Tap the floating glass "< HUB" pill from any world to go back instantly.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                '• Full-Screen QR: Hold down anywhere on your 3D Digital Card to trigger maximum brightness presentation mode.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                '• NFC Wireless Beam: Tap the phone against another Android device to beam contact info.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                '• Secret Design Gallery: Go to Settings ➔ About, and tap the version number 5 times.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSitemapCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF14171B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                it,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: MOGUL PLAYBOOKS ---
  Widget _buildPlaybooksTab() {
    final playbooks = [
      {
        'num': 'PLAYBOOK 01',
        'title': 'How to Pitch & Close a KES 500k+ Commercial in 10 Minutes',
        'steps': [
          '1. Capture: On the Hub, tap "CHIEF OF STAFF" and dictate: "Met [Client] from [Brand]. Wants 4K commercial directing, budget KES 650k. Send quote by Friday."',
          '2. Auto-Quote: Tap "Save & Draft Quote". The app sets up the deal, client profile, and opens the quotation editor.',
          '3. Line Items: Add pre-loaded camera gear, day rate, and editing packages from Items Library.',
          '4. Pitch Dispatch: Open client profile ➔ Tap "SMART PITCH" ➔ Choose "Commercial Rate Card & Proposal Pitch" ➔ Send via WhatsApp.',
        ],
      },
      {
        'num': 'PLAYBOOK 02',
        'title': 'Managing KRA Withholding Tax (5%) & VAT Escrow',
        'steps': [
          '1. Invoicing: Always bill with your official KRA PIN and clear WHT instructions.',
          '2. WHT Deduction: When the corporate client pays, they will retain 5% WHT and give you a KRA WHT certificate.',
          '3. VAT Escrow: Open "CEO MORNING RADAR" every Friday. Check the "VAT Escrow (16%)" figure.',
          '4. Net Studio Margin: Transfer the VAT portion to a separate tax escrow bank account so you never spend tax money as profit.',
        ],
      },
      {
        'num': 'PLAYBOOK 03',
        'title': 'Booking a Cinema Crew in 5 Minutes for an Urgent Shoot',
        'steps': [
          '1. Open "Production Slate" ➔ Switch to the "Crew Roster" tab.',
          '2. Filter by department (Camera, Lighting, Sound, Drone, Post).',
          '3. Review negotiated day rates (e.g. DoP KES 45k, Gaffer KES 30k).',
          '4. Tap "Book" next to each crew member to dispatch an instant availability inquiry with shoot dates via WhatsApp.',
        ],
      },
      {
        'num': 'PLAYBOOK 04',
        'title': 'Polite Debtor Recovery: Chasing Overdue Balances',
        'steps': [
          '1. Open "CEO Morning Radar" on the Hub.',
          '2. Look at "Aging Debtors" list. Any invoice unpaid past due date will appear in red.',
          '3. Tap "Chase". Choose from "Friendly Check-in", "Milestone Due Notice", or "Official Finance Notice".',
          '4. Tap "Chase via WhatsApp" to send the customized message without having to draft awkward follow-up emails.',
        ],
      },
    ];

    return Column(
      children: playbooks.map((pb) {
        final steps = pb['steps'] as List<String>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF14171B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pb['num'] as String,
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pb['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...steps.map(
                (st) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    st,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- TAB 3: FAQ & FIELD SUPPORT ---
  Widget _buildFaqTab() {
    final faqs = [
      {
        'q': 'Does the app work without internet?',
        'a': 'Yes, 100%. All documents, contacts, call sheets, meetings, and quotes are stored locally in an encrypted SQLite database on your device. Speech recognition runs via local on-device Whisper models.',
      },
      {
        'q': 'Where are my exported PDF documents saved?',
        'a': 'Exported quotations and invoices are generated in high-resolution PDF format and can be saved directly to your device Downloads folder or dispatched via WhatsApp / Gmail.',
      },
      {
        'q': 'How do I backup my data?',
        'a': 'Go to Settings ➔ Backup. Tap "Export Backup" to generate an encrypted .etole archive file that you can save to Google Drive, Telegram, or an external SSD.',
      },
      {
        'q': 'How does NFC contact sharing work?',
        'a': 'Open "Stage & Card" from the Hub. Ensure NFC is enabled in Android system settings. Tap the back of your phone against another NFC-capable smartphone to trigger your digital business card.',
      },
    ];

    return Column(
      children: faqs.map((faq) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF14171B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq['q']!,
                style: const TextStyle(
                  color: Color(0xFF38B6DB),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                faq['a']!,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
