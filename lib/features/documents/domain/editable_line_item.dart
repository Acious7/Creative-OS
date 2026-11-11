class EditableLineItem {
  String id;
  String description;
  String details;
  double quantity;
  String unit;
  double unitPrice;
  double discountPercent;
  String category;

  EditableLineItem({
    required this.id,
    this.description = '',
    this.details = '',
    this.quantity = 1.0,
    this.unit = 'item',
    this.unitPrice = 0.0,
    this.discountPercent = 0.0,
    this.category = 'General',
  });

  double get total {
    final raw = quantity * unitPrice;
    if (discountPercent <= 0) return raw;
    final disc = raw * (discountPercent / 100.0);
    return (raw - disc).clamp(0.0, double.infinity);
  }

  EditableLineItem copyWith({
    String? id,
    String? description,
    String? details,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? discountPercent,
    String? category,
  }) {
    return EditableLineItem(
      id: id ?? this.id,
      description: description ?? this.description,
      details: details ?? this.details,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      category: category ?? this.category,
    );
  }
}
