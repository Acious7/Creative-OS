/// Category tags for personal secret spots
enum SpotVibe {
  quietCafe('Quiet Cafe', '☕'),
  sunsetView('Sunset Viewpoint', '🌅'),
  acousticLounge('Acoustic / Live Music', '🎷'),
  bookstoreLibrary('Bookstore & Library', '📚'),
  creativeStudio('Studio / Workshop', '🎨'),
  lateNight('Late Night Hideout', '🌙');

  final String label;
  final String emoji;

  const SpotVibe(this.label, this.emoji);
}

/// A curated personal secret spot with optional ambient sound recording
class SecretSpot {
  final String id;
  final String name;
  final String city;
  final String address;
  final double? latitude;
  final double? longitude;
  final SpotVibe vibe;
  final String personalNotes;
  final String? audioMemoPath; // Ambient sound of the spot
  final int rating; // 1 to 5 stars
  final DateTime createdAt;

  SecretSpot({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    this.latitude,
    this.longitude,
    required this.vibe,
    required this.personalNotes,
    this.audioMemoPath,
    this.rating = 5,
    required this.createdAt,
  });

  SecretSpot copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    SpotVibe? vibe,
    String? personalNotes,
    String? audioMemoPath,
    int? rating,
    DateTime? createdAt,
  }) => SecretSpot(
    id: id ?? this.id,
    name: name ?? this.name,
    city: city ?? this.city,
    address: address ?? this.address,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    vibe: vibe ?? this.vibe,
    personalNotes: personalNotes ?? this.personalNotes,
    audioMemoPath: audioMemoPath ?? this.audioMemoPath,
    rating: rating ?? this.rating,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'vibe': vibe.name,
    'personalNotes': personalNotes,
    'audioMemoPath': audioMemoPath,
    'rating': rating,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SecretSpot.fromJson(Map<String, dynamic> json) => SecretSpot(
    id: json['id'] as String,
    name: json['name'] as String,
    city: json['city'] as String? ?? 'Nairobi',
    address: json['address'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    vibe: SpotVibe.values.firstWhere(
      (v) => v.name == json['vibe'],
      orElse: () => SpotVibe.quietCafe,
    ),
    personalNotes: json['personalNotes'] as String? ?? '',
    audioMemoPath: json['audioMemoPath'] as String?,
    rating: json['rating'] as int? ?? 5,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// A biometric-locked private journal entry (100% on-device), with gratitude and time-lock support
class BlackBoxJournalEntry {
  final String id;
  final String title;
  final String content;
  final String moodEmoji;
  final String locationTag;
  final bool isGratitude;
  final List<String> gratitudePoints;
  final bool isTimeLocked;
  final DateTime? unlockDate;
  final DateTime timestamp;

  BlackBoxJournalEntry({
    required this.id,
    required this.title,
    required this.content,
    this.moodEmoji = '✨',
    this.locationTag = '',
    this.isGratitude = false,
    this.gratitudePoints = const [],
    this.isTimeLocked = false,
    this.unlockDate,
    required this.timestamp,
  });

  bool get isLockedNow =>
      isTimeLocked && unlockDate != null && DateTime.now().isBefore(unlockDate!);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'moodEmoji': moodEmoji,
    'locationTag': locationTag,
    'isGratitude': isGratitude,
    'gratitudePoints': gratitudePoints,
    'isTimeLocked': isTimeLocked,
    'unlockDate': unlockDate?.toIso8601String(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory BlackBoxJournalEntry.fromJson(Map<String, dynamic> json) => BlackBoxJournalEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    moodEmoji: json['moodEmoji'] as String? ?? '✨',
    locationTag: json['locationTag'] as String? ?? '',
    isGratitude: json['isGratitude'] as bool? ?? false,
    gratitudePoints: (json['gratitudePoints'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    isTimeLocked: json['isTimeLocked'] as bool? ?? false,
    unlockDate: json['unlockDate'] != null ? DateTime.tryParse(json['unlockDate'] as String) : null,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

/// A creative swatch extracted from the real world
class ExtractedColorSwatch {
  final String hex;
  final String label;

  ExtractedColorSwatch({required this.hex, required this.label});

  Map<String, dynamic> toJson() => {'hex': hex, 'label': label};
  factory ExtractedColorSwatch.fromJson(Map<String, dynamic> json) =>
      ExtractedColorSwatch(hex: json['hex'] as String, label: json['label'] as String);
}

/// A spontaneous creative thought note, sketch, or voice capsule
class ScrapbookItem {
  final String id;
  final String text;
  final String? sketchPath;
  final String? audioPath; // Voice Capsule path
  final int? audioDurationSeconds;
  final List<ExtractedColorSwatch> swatches;
  final DateTime createdAt;

  ScrapbookItem({
    required this.id,
    required this.text,
    this.sketchPath,
    this.audioPath,
    this.audioDurationSeconds,
    this.swatches = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sketchPath': sketchPath,
    'audioPath': audioPath,
    'audioDurationSeconds': audioDurationSeconds,
    'swatches': swatches.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ScrapbookItem.fromJson(Map<String, dynamic> json) => ScrapbookItem(
    id: json['id'] as String,
    text: json['text'] as String,
    sketchPath: json['sketchPath'] as String?,
    audioPath: json['audioPath'] as String?,
    audioDurationSeconds: json['audioDurationSeconds'] as int?,
    swatches: (json['swatches'] as List<dynamic>?)
            ?.map((e) => ExtractedColorSwatch.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Shared memory entry between you and an inner circle connection
class SharedLoreItem {
  final String dateText;
  final String story;

  SharedLoreItem({required this.dateText, required this.story});

  Map<String, dynamic> toJson() => {'dateText': dateText, 'story': story};
  factory SharedLoreItem.fromJson(Map<String, dynamic> json) => SharedLoreItem(
    dateText: json['dateText'] as String? ?? '',
    story: json['story'] as String? ?? '',
  );
}

/// Inner Circle relationship contact metadata with lore and milestones
class InnerCircleMetadata {
  final int personId;
  final bool isInnerCircle;
  final int cadenceDays; // check in every 14, 30, 60, or 90 days
  final DateTime lastContactDate;
  final List<String> giftIdeas;
  final String personalInterests;
  final String? upcomingMilestone; // e.g. "Birthday: 24th Nov"
  final List<SharedLoreItem> sharedLore;

  InnerCircleMetadata({
    required this.personId,
    this.isInnerCircle = false,
    this.cadenceDays = 30,
    required this.lastContactDate,
    this.giftIdeas = const [],
    this.personalInterests = '',
    this.upcomingMilestone,
    this.sharedLore = const [],
  });

  Map<String, dynamic> toJson() => {
    'personId': personId,
    'isInnerCircle': isInnerCircle,
    'cadenceDays': cadenceDays,
    'lastContactDate': lastContactDate.toIso8601String(),
    'giftIdeas': giftIdeas,
    'personalInterests': personalInterests,
    'upcomingMilestone': upcomingMilestone,
    'sharedLore': sharedLore.map((e) => e.toJson()).toList(),
  };

  factory InnerCircleMetadata.fromJson(Map<String, dynamic> json) => InnerCircleMetadata(
    personId: json['personId'] as int,
    isInnerCircle: json['isInnerCircle'] as bool? ?? false,
    cadenceDays: json['cadenceDays'] as int? ?? 30,
    lastContactDate:
        DateTime.tryParse(json['lastContactDate'] as String? ?? '') ?? DateTime.now(),
    giftIdeas: (json['giftIdeas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    personalInterests: json['personalInterests'] as String? ?? '',
    upcomingMilestone: json['upcomingMilestone'] as String?,
    sharedLore: (json['sharedLore'] as List<dynamic>?)
            ?.map((e) => SharedLoreItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  /// Days remaining before warmth dims
  int get daysSinceLastContact => DateTime.now().difference(lastContactDate).inDays;
  double get warmthRatio => (1.0 - (daysSinceLastContact / cadenceDays)).clamp(0.0, 1.0);
}
