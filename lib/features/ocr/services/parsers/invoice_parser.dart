import 'base_parser.dart';

class InvoiceParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. Vendor Name
    String vendorName = '';
    for (final line in lines) {
      if (line.isNotEmpty &&
          !line.toLowerCase().contains('invoice') &&
          !line.toLowerCase().contains('tax') &&
          !line.toLowerCase().contains('gst') &&
          !line.toLowerCase().contains('date') &&
          line.length > 2) {
        vendorName = line;
        break;
      }
    }
    fields['Vendor Name'] = vendorName;

    // 2. Invoice Number
    final invRegex = RegExp(
      r'(?:invoice|inv|bill)(?:\s*number|\s*no|\s*#)?[:\s]*([a-zA-Z0-9-]+)',
      caseSensitive: false,
    );
    fields['Invoice Number'] = extractRegex(text, invRegex);

    // 3. Date
    fields['Date'] = extractDate(text);

    // 4. GSTIN
    final gstinRegex = RegExp(
      r'\b[0-9]{2}[a-zA-Z]{5}[0-9]{4}[a-zA-Z]{1}[1-9a-zA-Z]{1}[zZ]{1}[0-9a-zA-Z]{1}\b',
    );
    fields['GSTIN'] = extractRegex(text, gstinRegex, group: 0);

    // 5. Customer Name
    final billToRegex = RegExp(
      r'(?:bill\s+to|buyer|customer|bill\s+for)[:\s]*([^\n]+)',
      caseSensitive: false,
    );
    fields['Customer Name'] = extractRegex(text, billToRegex);

    // 6. Total Amount
    final totalRegex = RegExp(
      r'(?:grand\s+)?total(?:\s+amount|\s+due)?[:\s]*[₹$]?\s*([0-9,]+\.[0-9]{2}|[0-9,]+)',
      caseSensitive: false,
    );
    fields['Total Amount'] = extractRegex(text, totalRegex);

    // 7. Tax
    final taxRegex = RegExp(
      r'(?:tax|cgst|sgst|igst|vat|gst\s+amount)[:\s]*[₹$]?\s*([0-9,]+\.[0-9]{2}|[0-9,]+)',
      caseSensitive: false,
    );
    fields['Tax'] = extractRegex(text, taxRegex);

    return fields;
  }
}
