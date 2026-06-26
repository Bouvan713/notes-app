import 'base_parser.dart';

class DrivingLicenseParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};

    // 1. DL Number (Indian driving license: DL-XX YYYY ZZZZZZZ or DL-XXXXXXXXXXXXXXXX)
    final dlRegex = RegExp(r'\b([A-Z]{2}[0-9]{2}\s?[0-9]{11})\b');
    String dlNum = extractRegex(text, dlRegex);
    if (dlNum.isEmpty) {
      // General DL regex
      final fallbackRegex = RegExp(r'(?:dl\s*no|license\s*no|licence\s*no)[:\s]*([A-Z0-9-\s]{10,16})', caseSensitive: false);
      dlNum = extractRegex(text, fallbackRegex);
    }
    fields['DL Number'] = dlNum.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 2. Expiry Date
    final expiryRegex = RegExp(
      r'(?:valid\s+till|expiry|valid\s+upto|validity|expiry\s+date)[:\s]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4}|[0-9]{4}[-/][0-9]{2}[-/][0-9]{2})', 
      caseSensitive: false
    );
    fields['Expiry'] = extractRegex(text, expiryRegex);

    // 3. DOB
    final dobRegex = RegExp(
      r'(?:dob|date\s+of\s+birth|d\.o\.b)[:\s]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4}|[0-9]{4}[-/][0-9]{2}[-/][0-9]{2})', 
      caseSensitive: false
    );
    fields['DOB'] = extractRegex(text, dobRegex);

    return fields;
  }
}
