class GoogleEmailAccount {
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime connectedAt;

  GoogleEmailAccount({
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.connectedAt,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'connectedAt': connectedAt.toIso8601String(),
  };

  factory GoogleEmailAccount.fromJson(Map<String, dynamic> json) =>
      GoogleEmailAccount(
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        connectedAt: json['connectedAt'] != null
            ? DateTime.tryParse(json['connectedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
