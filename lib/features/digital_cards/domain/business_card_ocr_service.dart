import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedCardData {
  final String name;
  final String title;
  final String organization;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String rawText;
  final String imagePath;
  final List<String> unassignedLines;

  const ParsedCardData({
    this.name = '',
    this.title = '',
    this.organization = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.rawText = '',
    this.imagePath = '',
    this.unassignedLines = const [],
  });

  ParsedCardData copyWith({
    String? name,
    String? title,
    String? organization,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? rawText,
    String? imagePath,
    List<String>? unassignedLines,
  }) {
    return ParsedCardData(
      name: name ?? this.name,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      unassignedLines: unassignedLines ?? this.unassignedLines,
    );
  }
}

class BusinessCardOcrService {
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp _urlRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?([a-zA-Z0-9-]+\.)+(?:com|ke|co\.ke|org|or\.ke|net|io|africa|tv|me|info|biz|studio)(?:\/[^\s]*)?',
    caseSensitive: false,
  );

  // Phone regex matching Kenyan (+254, 07xx, 01xx) and international formats
  static final RegExp _phoneRegex = RegExp(
    r'(?:(?:\+?254[\s\-]?)?(?:0?[71][0-9]{2}[\s\-]?[0-9]{3}[\s\-]?[0-9]{3}))|(?:(?:\+|00)?[0-9]{1,4}[\s\-]?(?:\(?[0-9]{2,5}\)?[\s\-]?)?[0-9]{3,4}[\s\-]?[0-9]{3,4})',
  );

  // Common titles in media, film, production, tech & business
  static final List<String> _titleKeywords = [
    'director',
    'producer',
    'filmmaker',
    'photographer',
    'cinematographer',
    'founder',
    'co-founder',
    'ceo',
    'cfo',
    'coo',
    'cto',
    'managing director',
    'manager',
    'creative director',
    'creative',
    'executive',
    'head of',
    'editor',
    'colorist',
    'dop',
    'artist',
    'curator',
    'supervisor',
    'coordinator',
    'writer',
    'designer',
    'agent',
    'consultant',
    'officer',
    'partner',
    'associate',
    'architect',
    'engineer',
    'developer',
    'lead',
    'specialist',
  ];

  // Company and organization keywords
  static final List<String> _orgKeywords = [
    'ltd',
    'limited',
    'llc',
    'inc',
    'corp',
    'studios',
    'studio',
    'productions',
    'production',
    'films',
    'film',
    'media',
    'agency',
    'group',
    'company',
    'enterprises',
    'technologies',
    'holdings',
    'creative',
    'services',
    'ventures',
    'solutions',
    'kenya',
    'africa',
    'bank',
  ];

  // Address and physical location keywords
  static final List<String> _addressKeywords = [
    'p.o. box',
    'po box',
    'p.o box',
    'box',
    'plaza',
    'tower',
    'towers',
    'building',
    'center',
    'centre',
    'floor',
    'suite',
    'road',
    'rd',
    'street',
    'st',
    'avenue',
    'ave',
    'way',
    'drive',
    'dr',
    'lane',
    'nairobi',
    'mombasa',
    'kisumu',
    'nakuru',
    'eldoret',
    'kilimani',
    'westlands',
    'upper hill',
    'cbd',
    'kenya',
  ];

  /// Scan and parse an image of a business card using on-device ML Kit
  static Future<ParsedCardData> scanAndParseCard(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      return ParsedCardData(imagePath: imagePath);
    }

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String extractedEmail = '';
      String extractedPhone = '';
      String extractedWebsite = '';
      String extractedTitle = '';
      String extractedOrg = '';
      String extractedAddress = '';
      String extractedName = '';

      final List<String> allLines = [];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final trimmed = line.text.trim();
          if (trimmed.isNotEmpty) {
            allLines.add(trimmed);
          }
        }
      }

      final List<String> unassigned = [];

      for (final line in allLines) {
        // 1. Check for email
        final emailMatch = _emailRegex.firstMatch(line);
        if (emailMatch != null && extractedEmail.isEmpty) {
          extractedEmail = emailMatch.group(0)!;
          continue;
        }

        // 2. Check for website (must not be an email)
        final urlMatch = _urlRegex.firstMatch(line);
        if (urlMatch != null &&
            extractedWebsite.isEmpty &&
            !line.contains('@')) {
          extractedWebsite = urlMatch.group(0)!;
          continue;
        }

        // 3. Check for phone (Kenyan formats +254, 07xx, 01xx, and international)
        final phoneClean = line.replaceAll(RegExp(r'[^0-9+]'), '');
        final lower = line.toLowerCase();
        final hasPhoneKeyword =
            lower.contains('tel') ||
            lower.contains('cell') ||
            lower.contains('mob') ||
            lower.contains('call') ||
            lower.contains('phone');

        if ((hasPhoneKeyword || phoneClean.length >= 9) &&
            extractedPhone.isEmpty) {
          final phoneMatch = _phoneRegex.firstMatch(line);
          if (phoneMatch != null && phoneClean.length >= 7) {
            extractedPhone = phoneMatch.group(0)!.trim();
            continue;
          }
        }

        unassigned.add(line);
      }

      // 4. Extract Job Title from unassigned lines
      for (final line in List<String>.from(unassigned)) {
        final lower = line.toLowerCase();
        final isTitle = _titleKeywords.any((kw) => lower.contains(kw));
        if (isTitle && extractedTitle.isEmpty) {
          extractedTitle = line;
          unassigned.remove(line);
          break;
        }
      }

      // 5. Extract Company / Organization
      for (final line in List<String>.from(unassigned)) {
        final lower = line.toLowerCase();
        final isOrg = _orgKeywords.any((kw) => lower.contains(kw));
        if (isOrg && extractedOrg.isEmpty) {
          extractedOrg = line;
          unassigned.remove(line);
          break;
        }
      }

      // 6. Extract Address
      final addressParts = <String>[];
      for (final line in List<String>.from(unassigned)) {
        final lower = line.toLowerCase();
        final isAddr = _addressKeywords.any((kw) => lower.contains(kw));
        if (isAddr) {
          addressParts.add(line);
          unassigned.remove(line);
        }
      }
      if (addressParts.isNotEmpty) {
        extractedAddress = addressParts.join(', ');
      }

      // 7. Extract Name: First remaining clean line of 2 to 4 words with alphabetic characters
      for (final line in List<String>.from(unassigned)) {
        if (extractedName.isEmpty) {
          final isAlphaOnly = RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(line);
          final wordCount = line.split(RegExp(r'\s+')).length;
          if (isAlphaOnly && wordCount >= 2 && wordCount <= 4) {
            extractedName = line;
            unassigned.remove(line);
            break;
          }
        }
      }

      // If org still not found, check if first unassigned line is uppercase/title
      if (extractedOrg.isEmpty && unassigned.isNotEmpty) {
        extractedOrg = unassigned.removeAt(0);
      }

      return ParsedCardData(
        name: extractedName,
        title: extractedTitle,
        organization: extractedOrg,
        phone: extractedPhone,
        email: extractedEmail,
        website: extractedWebsite,
        address: extractedAddress,
        rawText: recognizedText.text,
        imagePath: imagePath,
        unassignedLines: unassigned,
      );
    } catch (_) {
      return ParsedCardData(imagePath: imagePath);
    } finally {
      await textRecognizer.close();
    }
  }
}
