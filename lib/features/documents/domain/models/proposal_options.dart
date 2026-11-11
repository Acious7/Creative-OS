import 'dart:convert';

class PackageOption {
  final String
  title; // e.g. "Basic / Silver", "Standard / Gold", "Premium / Platinum"
  final double price;
  final List<String> deliverables;
  final bool isRecommended;

  PackageOption({
    required this.title,
    required this.price,
    required this.deliverables,
    this.isRecommended = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'price': price,
    'deliverables': deliverables,
    'isRecommended': isRecommended,
  };

  factory PackageOption.fromJson(Map<String, dynamic> json) => PackageOption(
    title: json['title'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    deliverables:
        (json['deliverables'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    isRecommended: json['isRecommended'] as bool? ?? false,
  );
}

class OptionalAddon {
  final String name;
  final double price;
  final String? details;
  final bool isSelected;

  OptionalAddon({
    required this.name,
    required this.price,
    this.details,
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'details': details,
    'isSelected': isSelected,
  };

  factory OptionalAddon.fromJson(Map<String, dynamic> json) => OptionalAddon(
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    details: json['details'] as String?,
    isSelected: json['isSelected'] as bool? ?? false,
  );
}

class PaymentMilestone {
  final String
  title; // e.g. "Deposit / Kickoff", "Production / Rough Cut", "Final Delivery"
  final double percentage; // e.g. 50.0 for 50%
  final double amount;
  final String? dueDateText;
  final bool isPaid;
  final int? invoiceId;

  PaymentMilestone({
    required this.title,
    this.percentage = 0.0,
    required this.amount,
    this.dueDateText,
    this.isPaid = false,
    this.invoiceId,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'percentage': percentage,
    'amount': amount,
    'dueDateText': dueDateText,
    'isPaid': isPaid,
    'invoiceId': invoiceId,
  };

  factory PaymentMilestone.fromJson(Map<String, dynamic> json) =>
      PaymentMilestone(
        title: json['title'] as String? ?? '',
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        dueDateText: json['dueDateText'] as String?,
        isPaid: json['isPaid'] as bool? ?? false,
        invoiceId: json['invoiceId'] as int?,
      );
}

class DocumentMetaData {
  final String? showreelUrl;
  final List<PackageOption> packages;
  final List<OptionalAddon> addons;
  final List<PaymentMilestone> milestones;

  DocumentMetaData({
    this.showreelUrl,
    this.packages = const [],
    this.addons = const [],
    this.milestones = const [],
  });

  Map<String, dynamic> toJson() => {
    'showreelUrl': showreelUrl,
    'packages': packages.map((p) => p.toJson()).toList(),
    'addons': addons.map((a) => a.toJson()).toList(),
    'milestones': milestones.map((m) => m.toJson()).toList(),
  };

  factory DocumentMetaData.fromJson(Map<String, dynamic> json) =>
      DocumentMetaData(
        showreelUrl: json['showreelUrl'] as String?,
        packages:
            (json['packages'] as List<dynamic>?)
                ?.map((e) => PackageOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        addons:
            (json['addons'] as List<dynamic>?)
                ?.map((e) => OptionalAddon.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        milestones:
            (json['milestones'] as List<dynamic>?)
                ?.map(
                  (e) => PaymentMilestone.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );

  static DocumentMetaData fromRawJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return DocumentMetaData();
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return DocumentMetaData.fromJson(decoded);
      }
    } catch (_) {}
    return DocumentMetaData();
  }

  String toRawJson() => json.encode(toJson());
}
