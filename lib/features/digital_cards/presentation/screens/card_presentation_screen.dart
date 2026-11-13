import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/theme/studio_theme.dart';
import '../../domain/vcard_builder.dart';
import '../providers/cards_providers.dart';
import '../widgets/business_card_3d_flipper.dart';
import '../widgets/card_designs.dart';
import '../widgets/stage_backdrop.dart';
import 'card_editor_screen.dart';
import 'card_print_screen.dart';
import 'email_signature_screen.dart';
import 'nfc_management_screen.dart';

/// World 1 — Brian: "The Stage"
/// Features a dark stage backdrop with overhead spotlight and dust motes,
/// 5 vector East African tribal cards, 3D sensor tilt & specular sheen,
/// tap-to-flip, hold-for-QR full-screen presentation mode, concentric NFC pulse waves,
/// and a frosted glass pull-up action drawer.
class CardPresentationScreen extends ConsumerStatefulWidget {
  final BusinessCard? card;

  const CardPresentationScreen({super.key, this.card});

  @override
  ConsumerState<CardPresentationScreen> createState() =>
      _CardPresentationScreenState();
}

class _CardPresentationScreenState
    extends ConsumerState<CardPresentationScreen> {
  final GlobalKey<BusinessCard3DFlipperState> _flipperKey =
      GlobalKey<BusinessCard3DFlipperState>();

  QrDisplayMode _qrMode = QrDisplayMode.vCard;
  BusinessCard? _currentCard;
  bool _isQrExpanded = false;
  bool _isNfcPulsing = false;

  final List<String> _designStyles = [
    'ember',
    'savannah',
    'ochre_line',
    'night_market',
    'clay',
  ];

  @override
  void initState() {
    super.initState();
    _currentCard = widget.card;
    _enableWakelock();
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  @override
  void dispose() {
    _resetScreenMode();
    super.dispose();
  }

  Future<void> _resetScreenMode() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
      await WakelockPlus.disable();
    } catch (_) {}
  }

  void _triggerNfc() {
    setState(() => _isNfcPulsing = true);
    _flipperKey.currentState?.triggerNfcPulse();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _isNfcPulsing = false);
    });
  }

  Future<void> _showHoldForQr() async {
    EtoleHaptics.medium();
    setState(() => _isQrExpanded = true);
    try {
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {}
  }

  Future<void> _dismissHoldForQr() async {
    EtoleHaptics.light();
    setState(() => _isQrExpanded = false);
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (_) {}
  }

  Future<void> _switchDesignStyle(BusinessCard card, String style) async {
    EtoleHaptics.selection();
    final db = ref.read(databaseProvider);
    await (db.update(db.businessCards)..where((t) => t.id.equals(card.id)))
        .write(BusinessCardsCompanion(designStyle: drift.Value(style)));
    setState(() {
      _currentCard = card.copyWith(designStyle: style);
    });
  }

  void _nextDesign(BusinessCard card) {
    final currentStyle = card.designStyle.toLowerCase();
    int currentIndex = _designStyles.indexOf(currentStyle);
    if (currentIndex == -1) {
      currentIndex = _designStyles.indexOf(
        currentStyle == 'ochre' ? 'ochre_line' : 'ember',
      );
    }
    final nextIndex = (currentIndex + 1) % _designStyles.length;
    _switchDesignStyle(card, _designStyles[nextIndex]);
  }

  void _previousDesign(BusinessCard card) {
    final currentStyle = card.designStyle.toLowerCase();
    int currentIndex = _designStyles.indexOf(currentStyle);
    if (currentIndex == -1) {
      currentIndex = _designStyles.indexOf(
        currentStyle == 'ochre' ? 'ochre_line' : 'ember',
      );
    }
    final prevIndex =
        (currentIndex - 1 + _designStyles.length) % _designStyles.length;
    _switchDesignStyle(card, _designStyles[prevIndex]);
  }

  void _selectQrMode(QrDisplayMode mode) {
    EtoleHaptics.selection();
    setState(() => _qrMode = mode);
    // If the card is front-facing, gently flip to back so user sees the QR update!
    if (_flipperKey.currentState?.isFront == true) {
      _flipperKey.currentState?.flipCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBrand = ref.watch(activeBrandProvider);
    final defaultCardAsync = ref.watch(defaultBrandCardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = _currentCard ?? defaultCardAsync.value;

    if (card == null || activeBrand == null) {
      return Scaffold(
        backgroundColor: isDark ? EtoleColors.darkBase : EtoleColors.lightBase,
        body: const Center(
          child: CircularProgressIndicator(color: EtoleColors.cyan),
        ),
      );
    }

    final activeStyle = card.designStyle.toLowerCase();

    final studioTheme = ref.watch(currentStudioThemeProvider);
    final matchCardToTheme = ref.watch(matchCardToThemeProvider);
    final cardAccent = matchCardToTheme ? studioTheme.primaryAccent : null;

    return Scaffold(
      backgroundColor: studioTheme.backgroundBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Stage Backdrop with spotlight cone and dust motes
          StageBackdrop(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Top Stage Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title pill (positioned with clearance for the top-left HUB pill)
                        const SizedBox(width: 82),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: studioTheme.primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'THE STAGE',
                              style: EtoleTypography.labelCaps(
                                color: studioTheme.textPrimary,
                              ).copyWith(fontSize: 11, letterSpacing: 2.2),
                            ),
                          ],
                        ),

                        // Action icons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.contactless_rounded,
                                color: studioTheme.primaryAccent,
                                size: 20,
                              ),
                              tooltip: 'NFC Pulse',
                              onPressed: _triggerNfc,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: studioTheme.textMuted,
                                size: 20,
                              ),
                              tooltip: 'Edit Card',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CardEditorScreen(card: card),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 2. The 3D Floating Business Card under the Spotlight
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: BusinessCard3DFlipper(
                        key: _flipperKey,
                        isNfcPulsing: _isNfcPulsing,
                        onLongPress: _showHoldForQr,
                        onSwipeLeft: () => _nextDesign(card),
                        onSwipeRight: () => _previousDesign(card),
                        front: BusinessCardFrontView(
                          card: card,
                          brand: activeBrand,
                          customAccentOverride: cardAccent,
                        ),
                        back: BusinessCardBackView(
                          card: card,
                          brand: activeBrand,
                          mode: _qrMode,
                          customAccentOverride: cardAccent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtle Hint: Tap to flip • Swipe to change • Hold for QR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 13,
                        color: EtoleColors.cyan.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to flip 3D • Swipe to change • Hold for full QR',
                        style: EtoleTypography.labelCaps(
                          color: isDark
                              ? EtoleColors.muted
                              : EtoleColors.lightTextMuted,
                        ).copyWith(fontSize: 9.5, letterSpacing: 1.2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 3. QR Modes Ring Directly Under The Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x35141719)
                              : const Color(0x20000000),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? EtoleColors.cream.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildQrRingChip(
                              mode: QrDisplayMode.vCard,
                              label: 'Save contact',
                              icon: Icons.person_add_alt_1_rounded,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                            _buildQrRingChip(
                              mode: QrDisplayMode.whatsApp,
                              label: 'WhatsApp me',
                              icon: Icons.chat_rounded,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                            _buildQrRingChip(
                              mode: QrDisplayMode.reelUrl,
                              label: 'Watch reel',
                              icon: Icons.play_circle_outline_rounded,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                            _buildQrRingChip(
                              mode: QrDisplayMode.customUrl,
                              label: 'Custom link',
                              icon: Icons.link_rounded,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // 4. Fast Tribal Design Switcher Pills
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _designStyles.map((style) {
                          final isSelected =
                              activeStyle == style ||
                              (style == 'ochre_line' && activeStyle == 'ochre');
                          final label = style
                              .replaceAll('_', ' ')
                              .toUpperCase();

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: GestureDetector(
                              onTap: () => _switchDesignStyle(card, style),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? EtoleColors.cyan
                                      : (isDark
                                            ? const Color(0x35141719)
                                            : const Color(0x40FFFFFF)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? EtoleColors.cyan
                                        : (isDark
                                              ? EtoleColors.cream.withValues(
                                                  alpha: 0.15,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.1,
                                                )),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontFamily: EtoleTypography.bodyFontFamily,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    letterSpacing: 1.0,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                              ? EtoleColors.cream
                                              : EtoleColors.lightTextPrimary),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Glass Pull-Up Drawer Action Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0x350A0C0D)
                                : const Color(0x40FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? EtoleColors.cream.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(
                                icon: Icons.share_rounded,
                                label: 'Share .vcf',
                                onTap: () => _shareVcf(card),
                                isDark: isDark,
                              ),
                              _buildActionButton(
                                icon: Icons.print_outlined,
                                label: 'Print PDF',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CardPrintScreen(card: card),
                                    ),
                                  );
                                },
                                isDark: isDark,
                              ),
                              _buildActionButton(
                                icon: Icons.qr_code_2_rounded,
                                label: 'Show QR',
                                onTap: _showHoldForQr,
                                isDark: isDark,
                              ),
                              _buildActionButton(
                                icon: Icons.nfc_rounded,
                                label: 'NFC Write',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          NfcManagementScreen(card: card),
                                    ),
                                  );
                                },
                                isDark: isDark,
                              ),
                              _buildActionButton(
                                icon: Icons.alternate_email_rounded,
                                label: 'Signature',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EmailSignatureScreen(card: card),
                                    ),
                                  );
                                },
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 5. Full-Screen Hold-for-QR Presentation Overlay
          if (_isQrExpanded) _buildHoldForQrOverlay(card, isDark),
        ],
      ),
    );
  }

  Widget _buildQrRingChip({
    required QrDisplayMode mode,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _qrMode == mode;

    return GestureDetector(
      onTap: () => _selectQrMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EtoleColors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EtoleColors.cyan
                : (isDark
                      ? EtoleColors.cream.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.1)),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : EtoleColors.cyan,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: EtoleTypography.bodyFontFamily,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.4,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? EtoleColors.cream
                          : EtoleColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        EtoleHaptics.light();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0x35141719) : const Color(0x20000000),
              border: Border.all(
                color: EtoleColors.cream.withValues(alpha: 0.14),
                width: 0.8,
              ),
            ),
            child: Icon(icon, size: 18, color: EtoleColors.cyan),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: EtoleTypography.bodyFontFamily,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldForQrOverlay(BusinessCard card, bool isDark) {
    final qrData = _getQrData(card);

    return GestureDetector(
      onTap: _dismissHoldForQr,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.94),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dismiss Hint
                  Text(
                    'TAP ANYWHERE TO CLOSE',
                    style: EtoleTypography.labelCaps(color: EtoleColors.muted)
                        .copyWith(fontSize: 10, letterSpacing: 2.4),
                  ),
                  const SizedBox(height: 24),

                  // High-Contrast QR Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFAF7F2,
                      ), // Crisp high-contrast cream
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EtoleColors.cyan, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: EtoleColors.cyan.withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 240,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0A0C0D),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0A0C0D),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          card.personName.toUpperCase(),
                          style: TextStyle(
                            fontFamily: EtoleTypography.displayFontFamily,
                            color: const Color(0xFF0A0C0D),
                            fontSize: 26,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          (card.personRole ??
                                  'CREATIVE DIRECTOR / CINEMATOGRAPHER')
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: EtoleTypography.bodyFontFamily,
                            color: const Color(0xFFE64A19),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+254 718 013 579',
                          style: TextStyle(
                            fontFamily: EtoleTypography.bodyFontFamily,
                            color: const Color(0xFF333333),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // QR Mode Switcher Tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQrTab(QrDisplayMode.vCard, 'VCARD'),
                      const SizedBox(width: 8),
                      _buildQrTab(QrDisplayMode.whatsApp, 'WHATSAPP'),
                      const SizedBox(width: 8),
                      _buildQrTab(QrDisplayMode.reelUrl, 'SHOWREEL'),
                      const SizedBox(width: 8),
                      _buildQrTab(QrDisplayMode.customUrl, 'WEBSITE'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrTab(QrDisplayMode mode, String label) {
    final isSelected = _qrMode == mode;

    return GestureDetector(
      onTap: () {
        EtoleHaptics.selection();
        setState(() => _qrMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EtoleColors.cyan : const Color(0x35141719),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? EtoleColors.cyan
                : EtoleColors.cream.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: EtoleTypography.bodyFontFamily,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : EtoleColors.cream,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  String _getQrData(BusinessCard card) {
    switch (_qrMode) {
      case QrDisplayMode.vCard:
        return VCardBuilder.buildVCard(card).vCardString;
      case QrDisplayMode.whatsApp:
        final phone =
            (card.whatsappNumber ?? card.primaryPhone ?? '254718013579')
                .replaceAll(RegExp(r'\D'), '');
        final msg = Uri.encodeComponent(
          card.whatsappTemplate ?? 'Hi Brian, nice meeting you!',
        );
        return 'https://wa.me/$phone?text=$msg';
      case QrDisplayMode.reelUrl:
        return card.showreelUrl ??
            card.portfolioUrl ??
            card.website ??
            'https://brianetole.com';
      case QrDisplayMode.customUrl:
        return card.customQrUrl ??
            card.bookingUrl ??
            card.website ??
            'https://brianetole.com';
    }
  }

  Future<void> _shareVcf(BusinessCard card) async {
    final buildRes = VCardBuilder.buildVCard(card);
    final tempDir = await getTemporaryDirectory();
    final fileName = '${card.personName.replaceAll(' ', '_')}_contact.vcf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buildRes.vCardString);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Contact Card: ${card.personName} (${card.cardTitle})');
  }
}
