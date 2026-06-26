import 'base_parser.dart';

class BusinessCardParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. Email
    fields['Email'] = extractEmail(text);

    // 2. Phone
    fields['Phone'] = extractPhone(text);

    // 3. Website
    final webRegex = RegExp(r'\b(?:https?://)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}\b');
    fields['Website'] = extractRegex(text, webRegex, group: 0);

    // 4. Name
    String name = '';
    int designationIndex = -1;
    final designations = ['manager', 'director', 'founder', 'ceo', 'president', 'engineer', 'developer', 'consultant', 'partner'];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (designations.any((d) => line.contains(d))) {
        designationIndex = i;
        break;
      }
    }

    if (designationIndex > 0) {
      name = lines[designationIndex - 1];
    } else {
      // Find a line that looks like a name (2-3 words, capitalized)
      for (final line in lines) {
        if (line.isNotEmpty && 
            RegExp(r'^[A-Z][a-z]+\s[A-Z][a-z]+(?:\s[A-Z][a-z]+)?$').hasMatch(line)) {
          name = line;
          break;
        }
      }
    }
    fields['Name'] = name;

    // 5. Company
    String company = '';
    for (final line in lines) {
      if (line.isNotEmpty &&
          line != name &&
          !line.contains('@') &&
          !line.toLowerCase().contains('www') &&
          !line.toLowerCase().contains('http') &&
          !line.contains(RegExp(r'\d')) &&
          line.length > 2) {
        company = line;
        break;
      }
    }
    fields['Company'] = company;

    return fields;
  }
}
