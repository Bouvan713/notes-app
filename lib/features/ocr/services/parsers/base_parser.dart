abstract class BaseParser {
  Map<String, String> parse(String text);

  // Helper helper method to search with regex and return first capture group or empty string
  String extractRegex(String text, RegExp regex, {int group = 1}) {
    final match = regex.firstMatch(text);
    if (match != null && match.groupCount >= group) {
      return match.group(group)?.trim() ?? '';
    }
    return '';
  }

  // Common Date extraction helper
  String extractDate(String text) {
    // Matches formats: DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD, etc.
    final dateRegex = RegExp(
      r'(?:date|dt)[:\s]*([0-9]{2}[-/][0-9]{2}[-/][0-9]{4}|[0-9]{4}[-/][0-9]{2}[-/][0-9]{2})',
      caseSensitive: false,
    );
    final date = extractRegex(text, dateRegex);
    if (date.isNotEmpty) return date;

    // Generic date match in text
    final genericDateRegex = RegExp(
      r'\b([0-9]{2}[-/][0-9]{2}[-/][0-9]{4}|[0-9]{4}[-/][0-9]{2}[-/][0-9]{2})\b',
    );
    return extractRegex(text, genericDateRegex, group: 1);
  }

  // Common Email extraction helper
  String extractEmail(String text) {
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
    );
    return extractRegex(text, emailRegex, group: 0);
  }

  // Common Phone extraction helper
  String extractPhone(String text) {
    final phoneRegex = RegExp(
      r'\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b',
    );
    return extractRegex(text, phoneRegex, group: 0);
  }
}
