class ClauseParser {
  static String parse(
    String template, {
    String? clientName,
    String? brandName,
    double? depositPercent,
    int? revisionCount,
    int? validityDays,
    String? projectName,
  }) {
    var text = template;
    text = text.replaceAll('{client_name}', clientName ?? 'Client');
    text = text.replaceAll('{brand_name}', brandName ?? 'Brand');
    text = text.replaceAll('{deposit_percent}', '${(depositPercent ?? 50.0).toStringAsFixed(0)}%');
    text = text.replaceAll('{revision_count}', '${revisionCount ?? 2}');
    text = text.replaceAll('{validity_days}', '${validityDays ?? 14}');
    text = text.replaceAll('{project_name}', projectName ?? 'the Assignment');
    return text;
  }
}
