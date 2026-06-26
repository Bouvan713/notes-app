import 'base_parser.dart';

class BankStatementParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};

    // 1. Account Number
    final accRegex = RegExp(
      r'(?:account\s*number|acc\s*no|ac\s*no|a/c\s*no|account\s*no|a/c\s*number)[:\s]*([0-9Xx*]{8,18})',
      caseSensitive: false,
    );
    fields['Account Number'] = extractRegex(text, accRegex);

    // 2. Closing Balance
    final balanceRegex = RegExp(
      r'(?:closing\s*balance|ledger\s*balance|net\s*balance|available\s*balance|balance)[:\s]*[₹$]?\s*(-?[0-9,]+\.[0-9]{2}|-?[0-9,]+)',
      caseSensitive: false,
    );
    fields['Closing Balance'] = extractRegex(text, balanceRegex);

    // 3. Statement Period
    final periodRegex = RegExp(
      r'(?:statement\s*period|period|statement\s*for\s*the\s*period|from)[:\s]*([a-zA-Z0-9\s\.\/-]+to[a-zA-Z0-9\s\.\/-]+|[0-9./-]+\s*to\s*[0-9./-]+)',
      caseSensitive: false,
    );
    fields['Statement Period'] = extractRegex(text, periodRegex).replaceAll(RegExp(r'\s+'), ' ').trim();

    return fields;
  }
}
