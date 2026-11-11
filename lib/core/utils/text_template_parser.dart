class TextTemplateParser {
  static String parse(
    String template, {
    String clientName = '',
    String documentNumber = '',
    String documentType = '',
    String amount = '',
    String dueDate = '',
    String brandName = '',
    String currency = '',
    String balance = '',
  }) {
    return template
        .replaceAll('{client_name}', clientName)
        .replaceAll('{document_number}', documentNumber)
        .replaceAll('{document_type}', documentType)
        .replaceAll('{amount}', amount)
        .replaceAll('{due_date}', dueDate)
        .replaceAll('{brand_name}', brandName)
        .replaceAll('{currency}', currency)
        .replaceAll('{balance}', balance);
  }
}
