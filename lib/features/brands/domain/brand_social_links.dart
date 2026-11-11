import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BrandSocialLinks {
  final String? instagram;
  final String? linkedin;
  final String? whatsapp;

  const BrandSocialLinks({
    this.instagram,
    this.linkedin,
    this.whatsapp,
  });

  static const String defaultInstagram = 'instagram.com/brianetole';
  static const String defaultLinkedin = 'linkedin.com/in/brianetole';
  static const String defaultWhatsapp = '+254 718 013 579';

  static const BrandSocialLinks defaultLinks = BrandSocialLinks(
    instagram: defaultInstagram,
    linkedin: defaultLinkedin,
    whatsapp: defaultWhatsapp,
  );

  bool get isEmpty =>
      (instagram == null || instagram!.trim().isEmpty) &&
      (linkedin == null || linkedin!.trim().isEmpty) &&
      (whatsapp == null || whatsapp!.trim().isEmpty);
}

class BrandSocialLinksRepository {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );

  static const _keyInstagram = 'brand_social_instagram';
  static const _keyLinkedin = 'brand_social_linkedin';
  static const _keyWhatsapp = 'brand_social_whatsapp';

  /// Returns saved social links, or pre-filled defaults if not yet configured
  static Future<BrandSocialLinks> getSocialLinks() async {
    try {
      final ig = await _storage.read(key: _keyInstagram);
      final li = await _storage.read(key: _keyLinkedin);
      final wa = await _storage.read(key: _keyWhatsapp);

      return BrandSocialLinks(
        instagram: ig == null ? BrandSocialLinks.defaultInstagram : (ig.trim().isEmpty ? null : ig.trim()),
        linkedin: li == null ? BrandSocialLinks.defaultLinkedin : (li.trim().isEmpty ? null : li.trim()),
        whatsapp: wa == null ? BrandSocialLinks.defaultWhatsapp : (wa.trim().isEmpty ? null : wa.trim()),
      );
    } catch (_) {
      return BrandSocialLinks.defaultLinks;
    }
  }

  /// Persists social links to secure storage. Empty strings signify hidden links.
  static Future<void> saveSocialLinks(BrandSocialLinks links) async {
    await _storage.write(key: _keyInstagram, value: links.instagram?.trim() ?? '');
    await _storage.write(key: _keyLinkedin, value: links.linkedin?.trim() ?? '');
    await _storage.write(key: _keyWhatsapp, value: links.whatsapp?.trim() ?? '');
  }
}
