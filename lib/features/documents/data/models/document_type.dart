enum DocumentType {
  invoice,
  receipt,
  panCard,
  aadhaarCard,
  passport,
  drivingLicense,
  businessCard,
  resume,
  bankStatement,
  utilityBill,
  unknown,
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.receipt:
        return 'Receipt';
      case DocumentType.panCard:
        return 'PAN Card';
      case DocumentType.aadhaarCard:
        return 'Aadhaar Card';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.drivingLicense:
        return 'Driving License';
      case DocumentType.businessCard:
        return 'Business Card';
      case DocumentType.resume:
        return 'Resume';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.utilityBill:
        return 'Utility Bill';
      case DocumentType.unknown:
        return 'Other/Unknown';
    }
  }

  String get name => toString().split('.').last;
}

DocumentType parseDocumentType(String value) {
  return DocumentType.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => DocumentType.unknown,
  );
}
