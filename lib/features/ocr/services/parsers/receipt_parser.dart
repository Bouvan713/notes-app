import 'base_parser.dart';

class ReceiptParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. Store Name
    String storeName = '';
    for (final line in lines) {
      if (line.isNotEmpty && 
          !line.toLowerCase().contains('receipt') && 
          !line.toLowerCase().contains('welcome') && 
          line.length > 2) {
        storeName = line;
        break;
      }
    }
    fields['Store Name'] = storeName;

    // 2. Date
    fields['Date'] = extractDate(text);

    // 3. Total
    final totalRegex = RegExp(
      r'(?:total|net\s+amount|cash|paid|amount\s+paid|subtotal)[:\s]*[₹$]?\s*([0-9,]+\.[0-9]{2}|[0-9,]+)',
      caseSensitive: false,
    );
    fields['Total'] = extractRegex(text, totalRegex);

    // 4. Items
    final itemsList = <String>[];
    for (final line in lines) {
      if (line.contains(RegExp(r'\d+\.\d{2}')) &&
          !line.toLowerCase().contains('total') &&
          !line.toLowerCase().contains('subtotal') &&
          !line.toLowerCase().contains('tax') &&
          !line.toLowerCase().contains('gst') &&
          !line.toLowerCase().contains('cash') &&
          !line.toLowerCase().contains('change') &&
          !line.toLowerCase().contains('card') &&
          line.length > 3) {
        itemsList.add(line);
      }
    }
    fields['Items'] = itemsList.take(5).join(', '); // limit items list summary

    return fields;
  }
}
