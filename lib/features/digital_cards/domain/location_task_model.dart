class LocationTaskItem {
  final String id;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  final int? personId; // null = whole location task, non-null = person task
  final String? personName;
  final bool hasReminder;

  const LocationTaskItem({
    required this.id,
    required this.title,
    this.isDone = false,
    this.dueDate,
    this.personId,
    this.personName,
    this.hasReminder = false,
  });

  LocationTaskItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? dueDate,
    int? personId,
    String? personName,
    bool? hasReminder,
  }) {
    return LocationTaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isDone': isDone,
    'dueDate': dueDate?.toIso8601String(),
    'personId': personId,
    'personName': personName,
    'hasReminder': hasReminder,
  };

  factory LocationTaskItem.fromJson(Map<String, dynamic> json) =>
      LocationTaskItem(
        id:
            json['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        personId: json['personId'] as int?,
        personName: json['personName'] as String?,
        hasReminder: json['hasReminder'] as bool? ?? false,
      );
}
