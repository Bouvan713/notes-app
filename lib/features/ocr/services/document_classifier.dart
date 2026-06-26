import '../../documents/data/models/document_type.dart';

class DocumentClassifier {
  static DocumentType classify(String text) {
    final lowerText = text.toLowerCase();
    
    // Map of DocumentType to scoring rules (keywords/regex and their weight)
    final Map<DocumentType, List<MapEntry<dynamic, int>>> scoringRules = {
      DocumentType.invoice: [
        const MapEntry('invoice', 5),
        const MapEntry('gst', 3),
        const MapEntry('tax invoice', 6),
        const MapEntry('invoice number', 6),
        const MapEntry('bill to', 4),
        const MapEntry('gstin', 5),
        const MapEntry('purchase order', 4),
        const MapEntry('invoice date', 4),
        MapEntry(RegExp(r'\binv-\d+'), 6),
      ],
      DocumentType.receipt: [
        const MapEntry('thank you', 5),
        const MapEntry('cash', 3),
        const MapEntry('receipt', 5),
        const MapEntry('subtotal', 5),
        const MapEntry('change due', 5),
        const MapEntry('merchant', 4),
        const MapEntry('items', 2),
        const MapEntry('total paid', 4),
        MapEntry(RegExp(r'\bqty\b'), 4),
      ],
      DocumentType.panCard: [
        const MapEntry('income tax department', 10),
        const MapEntry('permanent account number', 10),
        const MapEntry('govt of india', 5),
        const MapEntry('pan card', 8),
        MapEntry(RegExp(r'\b[a-z]{5}[0-9]{4}[a-z]\b'), 12),
      ],
      DocumentType.aadhaarCard: [
        const MapEntry('unique identification authority', 10),
        const MapEntry('aadhaar', 10),
        const MapEntry('government of india', 4),
        const MapEntry('enrollment no', 6),
        const MapEntry('male', 3),
        const MapEntry('female', 3),
        const MapEntry('dob', 2),
        const MapEntry('yob', 3),
        MapEntry(RegExp(r'\b[0-9]{4}\s[0-9]{4}\s[0-9]{4}\b'), 12),
      ],
      DocumentType.passport: [
        const MapEntry('passport', 10),
        const MapEntry('republic of india', 6),
        const MapEntry('republica de', 6),
        const MapEntry('passport no', 10),
        const MapEntry('place of issue', 6),
        MapEntry(RegExp(r'\b[a-z][0-9]{7}\b'), 10),
      ],
      DocumentType.drivingLicense: [
        const MapEntry('driving license', 10),
        const MapEntry('driving licence', 10),
        const MapEntry('dl number', 10),
        const MapEntry('licence to drive', 8),
        const MapEntry('dl no', 8),
        const MapEntry('transport department', 6),
        MapEntry(RegExp(r'\b[a-z]{2}[0-9]{2}\s?[0-9]{11}\b'), 12),
      ],
      DocumentType.businessCard: [
        const MapEntry('email', 2),
        const MapEntry('phone', 2),
        const MapEntry('website', 2),
        const MapEntry('mobile', 2),
        const MapEntry('tel', 2),
        const MapEntry('fax', 2),
        const MapEntry('ceo', 4),
        const MapEntry('manager', 3),
        const MapEntry('director', 3),
        const MapEntry('founder', 4),
        MapEntry(RegExp(r'\bwww\.[a-z0-9-]+\.[a-z]{2,}\b'), 5),
      ],
      DocumentType.resume: [
        const MapEntry('resume', 10),
        const MapEntry('curriculum vitae', 10),
        const MapEntry('education', 4),
        const MapEntry('experience', 4),
        const MapEntry('skills', 4),
        const MapEntry('projects', 3),
        const MapEntry('summary', 2),
        const MapEntry('objective', 3),
        const MapEntry('technologies', 4),
      ],
      DocumentType.bankStatement: [
        const MapEntry('bank statement', 10),
        const MapEntry('statement of account', 8),
        const MapEntry('account statement', 8),
        const MapEntry('closing balance', 8),
        const MapEntry('opening balance', 6),
        const MapEntry('transaction details', 6),
        const MapEntry('deposit', 4),
        const MapEntry('withdrawal', 4),
      ],
      DocumentType.utilityBill: [
        const MapEntry('utility bill', 10),
        const MapEntry('consumer number', 10),
        const MapEntry('bill date', 6),
        const MapEntry('electricity bill', 8),
        const MapEntry('power distribution', 6),
        const MapEntry('water bill', 8),
        const MapEntry('gas bill', 8),
        const MapEntry('due date', 6),
        const MapEntry('billing cycle', 6),
      ],
    };

    final Map<DocumentType, int> scores = {};
    for (final type in scoringRules.keys) {
      int score = 0;
      final rules = scoringRules[type]!;
      for (final rule in rules) {
        final matcher = rule.key;
        final weight = rule.value;
        if (matcher is String) {
          if (lowerText.contains(matcher.toLowerCase())) {
            score += weight;
          }
        } else if (matcher is RegExp) {
          if (matcher.hasMatch(lowerText)) {
            score += weight;
          }
        }
      }
      if (score > 0) {
        scores[type] = score;
      }
    }

    if (scores.isEmpty) {
      return DocumentType.unknown;
    }

    DocumentType highestType = DocumentType.unknown;
    int highestScore = 0;
    scores.forEach((type, score) {
      if (score > highestScore) {
        highestScore = score;
        highestType = type;
      }
    });

    return highestType;
  }
}
