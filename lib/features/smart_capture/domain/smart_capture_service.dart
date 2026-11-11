class ParsedBusinessCard {
  final String name;
  final String? title;
  final String? organization;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;

  ParsedBusinessCard({
    required this.name,
    this.title,
    this.organization,
    this.email,
    this.phone,
    this.website,
    this.address,
  });
}

class SmartCaptureService {
  /// Robust on-device text parser for physical business cards
  static ParsedBusinessCard parseBusinessCard(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String name = '';
    String? title;
    String? organization;
    String? email;
    String? phone;
    String? website;
    String? address;

    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );
    final phoneRegex = RegExp(r'(?:\+?254|0|\+1|\+44)[0-9\s\-()]{7,}');
    final urlRegex = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?([a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s]*)?)',
    );

    final titleKeywords = [
      'director',
      'producer',
      'cinematographer',
      'dop',
      'photographer',
      'filmmaker',
      'editor',
      'colorist',
      'sound',
      'engineer',
      'lead',
      'manager',
      'founder',
      'ceo',
      'partner',
      'creative',
      'curator',
      'artist',
      'writer',
      'designer',
      'consultant',
    ];

    final orgKeywords = [
      'ltd',
      'limited',
      'inc',
      'corp',
      'agency',
      'studio',
      'studios',
      'productions',
      'films',
      'media',
      'group',
      'company',
      'associates',
      'llc',
      'foundation',
      'trust',
    ];

    for (final line in lines) {
      final lineLower = line.toLowerCase();

      // Check email
      if (email == null && emailRegex.hasMatch(line)) {
        email = emailRegex.stringMatch(line);
        continue;
      }

      // Check website (avoid matching email domains)
      if (website == null && urlRegex.hasMatch(line) && !line.contains('@')) {
        website = urlRegex.stringMatch(line);
        continue;
      }

      // Check phone
      if (phone == null && phoneRegex.hasMatch(line)) {
        phone = phoneRegex.stringMatch(line);
        continue;
      }

      // Check title
      if (title == null && titleKeywords.any((k) => lineLower.contains(k))) {
        title = line;
        continue;
      }

      // Check organization
      if (organization == null &&
          orgKeywords.any((k) => lineLower.contains(k))) {
        organization = line;
        continue;
      }
    }

    // Name detection: first candidate line that isn't title, org, email, phone, or website
    for (final line in lines) {
      if (line == email ||
          line == phone ||
          line == website ||
          line == title ||
          line == organization) {
        continue;
      }
      if (line.length >= 2 &&
          line.length <= 40 &&
          !line.contains('http') &&
          !line.contains('.com')) {
        name = line;
        break;
      }
    }

    if (name.isEmpty) {
      name = lines.isNotEmpty ? lines.first : 'Extracted Contact';
    }

    return ParsedBusinessCard(
      name: name,
      title: title,
      organization: organization,
      email: email,
      phone: phone,
      website: website,
      address: address,
    );
  }
}
