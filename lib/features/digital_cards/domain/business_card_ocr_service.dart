import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedCardData {
  final String name;
  final String title;
  final String organization;
  final String phone;
  final String email;
  final String website;
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
    r'(?:https?:\/\/)?(?:www\.)?([a-zA-Z0-9-]+\.)+(?:com|ke|org|net|co|io|africa|tv|me|info|biz)(?:\/[^\s]*)?',
    caseSensitive: false,
  );

  // Phone regex matching Kenyan and international formats
  static final RegExp _phoneRegex = RegExp(
    r'(?:(?:\+|00)?[0-9]{1,4}[\s\-]?)?(?:\(?[0-9]{2,5}\)?[\s\-]?)?[0-9]{3,4}[\s\-]?[0-9]{3,4}',
  );

  // Common titles in media, film, production & business
  static final List<String> _titleKeywords = [
    'director',
    'producer',
    'filmmaker',
    'photographer',
    'cinematographer',
    'founder',
    'ceo',
    'manager',
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
  ];

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

        // 2. Check for website
        final urlMatch = _urlRegex.firstMatch(line);
        if (urlMatch != null &&
            extractedWebsite.isEmpty &&
            !line.contains('@')) {
          extractedWebsite = urlMatch.group(0)!;
          continue;
        }

        // 3. Check for phone
        final phoneClean = line.replaceAll(RegExp(r'[^0-9+]'), '');
        if ((line.toLowerCase().contains('tel') ||
                line.toLowerCase().contains('call') ||
                line.toLowerCase().contains('phone') ||
                phoneClean.length >= 9) &&
            extractedPhone.isEmpty) {
          final phoneMatch = _phoneRegex.firstMatch(line);
          if (phoneMatch != null && phoneClean.length >= 7) {
            extractedPhone = phoneMatch.group(0)!.trim();
            continue;
          }
        }

        // 4. Check for job title
        final lower = line.toLowerCase();
        final isTitle = _titleKeywords.any((kw) => lower.contains(kw));
        if (isTitle && extractedTitle.isEmpty) {
          extractedTitle = line;
          continue;
        }

        // 5. Check for company indicators (Ltd, LLC, Studios, Productions, Media, Group)
        if ((lower.contains('ltd') ||
                lower.contains('llc') ||
                lower.contains('studios') ||
                lower.contains('films') ||
                lower.contains('media') ||
                lower.contains('agency') ||
                lower.contains('production') ||
                lower.contains('group')) &&
            extractedOrg.isEmpty) {
          extractedOrg = line;
          continue;
        }

        unassigned.add(line);
      }

      // If name not identified yet, heuristic: the first clean line without symbols or numbers
      for (final line in unassigned) {
        if (extractedName.isEmpty) {
          final isAlphaOnly = RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(line);
          final wordCount = line.split(RegExp(r'\s+')).length;
          if (isAlphaOnly && wordCount >= 2 && wordCount <= 4) {
            extractedName = line;
            continue;
          }
        }

        if (extractedOrg.isEmpty && line != extractedName) {
          extractedOrg = line;
        }
      }

      return ParsedCardData(
        name: extractedName,
        title: extractedTitle,
        organization: extractedOrg,
        phone: extractedPhone,
        email: extractedEmail,
        website: extractedWebsite,
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
