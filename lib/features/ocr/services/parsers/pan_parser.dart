import 'base_parser.dart';

class PanParser extends BaseParser {
  @override
  Map<String, String> parse(String text) {
    final fields = <String, String>{};
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. PAN Number
    final panRegex = RegExp(r'\b([A-Z]{5}[0-9]{4}[A-Z]{1})\b');
    fields['PAN Number'] = extractRegex(text, panRegex);

    // 2. DOB
    final dobRegex = RegExp(r'\b([0-9]{2}/[0-9]{2}/[0-9]{4})\b');
    fields['DOB'] = extractRegex(text, dobRegex);

    // 3. Name & Father's Name
    String name = '';
    String fatherName = '';

    int fatherLabelIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains("father's name") || 
          line.contains("father name") || 
          line.contains("father")) {
        fatherLabelIndex = i;
        break;
      }
    }

    if (fatherLabelIndex != -1) {
      // Usually, on older PAN cards:
      // Line: Name
      // Line: Father's Name Label
      // Line: Father's Name
      if (fatherLabelIndex > 0) {
        name = lines[fatherLabelIndex - 1];
        if (name.toLowerCase() == 'name' && fatherLabelIndex > 1) {
          name = lines[fatherLabelIndex - 2];
        }
      }
      if (fatherLabelIndex < lines.length - 1) {
        fatherName = lines[fatherLabelIndex + 1];
      }
    } else {
      // Fallback: Look for lines containing only uppercase words (Indian names)
      final candidateNames = <String>[];
      for (final line in lines) {
        if (line.isNotEmpty &&
            RegExp(r'^[A-Z\s]+$').hasMatch(line) &&
            !line.contains('INCOME TAX') &&
            !line.contains('DEPARTMENT') &&
            !line.contains('INDIA') &&
            !line.contains('GOVT') &&
            !line.contains('CARD') &&
            line.length > 3) {
          candidateNames.add(line);
        }
      }
      if (candidateNames.isNotEmpty) {
        name = candidateNames[0];
        if (candidateNames.length > 1) {
          fatherName = candidateNames[1];
        }
      }
    }

    fields['Name'] = name;
    fields['Father Name'] = fatherName;

    return fields;
  }
}
