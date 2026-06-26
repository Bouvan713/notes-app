import 'base_parser.dart';

class AadhaarParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. Aadhaar Number (format: XXXX XXXX XXXX)
    final aadhaarRegex = RegExp(r'\b[0-9]{4}\s[0-9]{4}\s[0-9]{4}\b');
    String number = extractRegex(text, aadhaarRegex, group: 0);
    if (number.isEmpty) {
      final fallbackRegex = RegExp(r'\b[0-9]{12}\b');
      number = extractRegex(text, fallbackRegex, group: 0);
    }
    fields['Aadhaar Number'] = number;

    // 2. Gender
    final genderRegex = RegExp(r'\b(MALE|FEMALE|TRANSGENDER)\b', caseSensitive: false);
    fields['Gender'] = extractRegex(text, genderRegex).toUpperCase();

    // 3. DOB
    final dobRegex = RegExp(r'(?:DOB|Year\s+of\s+Birth|Birth)[:\s]*([0-9]{2}/[0-9]{2}/[0-9]{4}|[0-9]{4})', caseSensitive: false);
    fields['DOB'] = extractRegex(text, dobRegex);

    // 4. Name
    String name = '';
    int dobOrGenderIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('dob') || 
          line.contains('year of birth') || 
          line.contains('male') || 
          line.contains('female')) {
        dobOrGenderIndex = i;
        break;
      }
    }

    if (dobOrGenderIndex > 0) {
      name = lines[dobOrGenderIndex - 1];
    } else {
      // Fallback
      for (final line in lines) {
        if (line.isNotEmpty &&
            RegExp(r'^[A-Z][a-zA-Z\s]+$').hasMatch(line) &&
            !line.toLowerCase().contains('government') &&
            !line.toLowerCase().contains('unique') &&
            !line.toLowerCase().contains('india') &&
            !line.toLowerCase().contains('authority')) {
          name = line;
          break;
        }
      }
    }
    fields['Name'] = name;

    // 5. Address
    String address = '';
    int addressIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('address:')) {
        addressIndex = i;
        break;
      }
    }

    if (addressIndex != -1) {
      final addrLines = <String>[];
      for (int i = addressIndex; i < lines.length; i++) {
        if (lines[i].contains(RegExp(r'\b[0-9]{4}\s[0-9]{4}\s[0-9]{4}\b'))) {
          break;
        }
        addrLines.add(lines[i]);
      }
      address = addrLines.join(', ').replaceAll(RegExp(r'address:\s*', caseSensitive: false), '');
    }
    fields['Address'] = address;

    return fields;
  }
}
