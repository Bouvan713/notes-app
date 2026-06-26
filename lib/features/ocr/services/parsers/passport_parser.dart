import 'base_parser.dart';

class PassportParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};

    // 1. Passport Number
    final passportRegex = RegExp(r'\b([A-Z][0-9]{7})\b');
    fields['Passport Number'] = extractRegex(text, passportRegex);

    // 2. Nationality
    final nationalityRegex = RegExp(r'(?:nationality|nationalite)[:\s]*([a-zA-Z]+)', caseSensitive: false);
    String nationality = extractRegex(text, nationalityRegex);
    if (nationality.isEmpty) {
      if (text.toLowerCase().contains('indian')) {
        nationality = 'INDIAN';
      } else if (text.toLowerCase().contains('republic of india')) {
        nationality = 'INDIAN';
      }
    }
    fields['Nationality'] = nationality.toUpperCase();

    // 3. Expiry
    final expiryRegex = RegExp(
      r'(?:expiry|date\s+of\s+expiry|expiry\s+date|valid\s+until|valide\s+jusqu\s*au)[:\s]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4}|[0-9]{4}[-/][0-9]{2}[-/][0-9]{2})', 
      caseSensitive: false
    );
    fields['Expiry'] = extractRegex(text, expiryRegex);

    return fields;
  }
}
