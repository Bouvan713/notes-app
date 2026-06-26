import 'base_parser.dart';

class UtilityBillParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};

    // 1. Consumer Number
    final consumerRegex = RegExp(
      r'(?:consumer\s*(?:no|number|id)|ca\s*no|account\s*(?:no|number|id)|meter\s*no)[:\s]*([0-9a-zA-Z-]+)',
      caseSensitive: false,
    );
    fields['Consumer Number'] = extractRegex(text, consumerRegex);

    // 2. Bill Date
    final billDateRegex = RegExp(
      r'(?:bill\s+date|billing\s+date|invoice\s+date|date\s+of\s+bill)[:\s]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4}|[0-9]{4}[-/][0-9]{2}[-/][0-9]{2})',
      caseSensitive: false,
    );
    String billDate = extractRegex(text, billDateRegex);
    if (billDate.isEmpty) {
      billDate = extractDate(text);
    }
    fields['Bill Date'] = billDate;

    // 3. Amount
    final amountRegex = RegExp(
      r'(?:amount\s*payable|net\s*payable|bill\s*amount|amount\s*due|total\s*amount|payable\s*amount|amount)[:\s]*[₹$]?\s*([0-9,]+\.[0-9]{2}|[0-9,]+)',
      caseSensitive: false,
    );
    fields['Amount'] = extractRegex(text, amountRegex);

    // 4. Due Date
    final dueDateRegex = RegExp(
      r'(?:due\s+date|pay\s+by|payment\s+due|due\s+on)[:\s]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4}|[0-9]{4}[-/][0-9]{2}[-/][0-9]{2})',
      caseSensitive: false,
    );
    fields['Due Date'] = extractRegex(text, dueDateRegex);

    return fields;
  }
}
