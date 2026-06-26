import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

import '../../documents/data/models/document_model.dart';
import '../../documents/data/models/document_type.dart';
import '../../documents/data/repository/document_repository.dart';
import '../services/ocr_service.dart';
import '../services/document_classifier.dart';
import '../services/parsers/invoice_parser.dart';
import '../services/parsers/receipt_parser.dart';
import '../services/parsers/pan_parser.dart';
import '../services/parsers/aadhaar_parser.dart';
import '../services/parsers/passport_parser.dart';
import '../services/parsers/driving_license_parser.dart';
import '../services/parsers/business_card_parser.dart';
import '../services/parsers/resume_parser.dart';
import '../services/parsers/utility_bill_parser.dart';
import '../services/parsers/bank_statement_parser.dart';

class OcrProvider extends ChangeNotifier {
  final OcrService _ocrService = OcrService();
  final DocumentRepository _repository;

  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;
  DocumentModel? _draftDocument;
  File? _processedImage;

  OcrProvider(this._repository);

  // Getters
  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  DocumentModel? get draftDocument => _draftDocument;
  File? get processedImage => _processedImage;

  void clearDraft() {
    _draftDocument = null;
    _processedImage = null;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  // Setters/Modifications for editing fields
  void updateField(String key, String value) {
    if (_draftDocument == null) return;
    final fields = Map<String, String>.from(_draftDocument!.parsedFields);
    fields[key] = value;
    _draftDocument = _draftDocument!.copyWith(parsedFields: fields, isEdited: true);
    notifyListeners();
  }

  void addField(String key, String value) {
    if (_draftDocument == null) return;
    final fields = Map<String, String>.from(_draftDocument!.parsedFields);
    fields[key] = value;
    _draftDocument = _draftDocument!.copyWith(parsedFields: fields, isEdited: true);
    notifyListeners();
  }

  void deleteField(String key) {
    if (_draftDocument == null) return;
    final fields = Map<String, String>.from(_draftDocument!.parsedFields);
    fields.remove(key);
    _draftDocument = _draftDocument!.copyWith(parsedFields: fields, isEdited: true);
    notifyListeners();
  }

  void renameField(String oldKey, String newKey, String value) {
    if (_draftDocument == null) return;
    final fields = Map<String, String>.from(_draftDocument!.parsedFields);
    fields.remove(oldKey);
    fields[newKey] = value;
    _draftDocument = _draftDocument!.copyWith(parsedFields: fields, isEdited: true);
    notifyListeners();
  }

  void changeDocumentType(DocumentType newType) {
    if (_draftDocument == null) return;
    
    // Reparse the original rawText with the new type parser if the user changes the type,
    // to populate matching fields automatically
    final parsed = _parseTextForType(_draftDocument!.rawText, newType);
    
    _draftDocument = _draftDocument!.copyWith(
      documentType: newType.name,
      parsedFields: parsed,
      isEdited: true,
    );
    notifyListeners();
  }

  // Processing pipeline
  Future<bool> processDocument(String userId, ImageSource source) async {
    print('Requesting permissions...');
    _setProcessing(true, 'Requesting permissions...');
    _errorMessage = null;

    try {
      // 1. Permissions check
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied) {
          throw Exception('Camera permission denied.');
        }
      } else {
        // Photos permission request (platform-dependent)
        // if (Platform.isAndroid) {
        //   final status = await Permission.photos.request();
        //
        //   if (!status.isGranted) {
        //     throw Exception("Photos permission denied");
        //   }
        // } else {
        //   final photosStatus = await Permission.photos.request();
        //   if (photosStatus.isDenied) {
        //     throw Exception('Photos permission denied.');
        //   }
        // }
        if (Platform.isIOS) {
          final status = await Permission.photos.request();

          if (!status.isGranted) {
            throw Exception('Photos permission denied.');
          }
        }
      }

      // 2. Pick Image
      print('Picking image...');
      _setStatus('Picking image...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 100, // retrieve original quality; we compress later
      );
      if (pickedFile == null) {
        _setProcessing(false);
        return false;
      }

      final imageFile = File(pickedFile.path);

      // 3. Crop Image
      print('Cropping image...');
      _setStatus('Cropping image...');
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: const Color(0xFF4F46E5), // matching theme Indigo
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF9333EA),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Document',
          ),
        ],
      );

      if (croppedFile == null) {
        _setProcessing(false);
        return false;
      }

      final croppedImage = File(croppedFile.path);

      // 4. Compress Image
      print('Compressing image...');
      _setStatus('Compressing image...');
      final compressedImage = await _compressImageFile(croppedImage);
      if (compressedImage == null) {
        throw Exception('Failed to compress image.');
      }
      _processedImage = compressedImage;

      // 5. OCR Text Recognition
      print('Running OCR text recognition...');
      _setStatus('Running OCR text recognition...');
      final rawText = await _ocrService.recognizeText(compressedImage);
      if (rawText.trim().isEmpty) {
        throw Exception('OCR completed but failed to recognize any text in the image.');
      }

      // 6. Classification
      print('Classifying document type...');
      _setStatus('Classifying document type...');
      final docType = DocumentClassifier.classify(rawText);

      // 7. Parse fields
      print('Extracting data fields...');
      _setStatus('Extracting data fields...');
      final parsedFields = _parseTextForType(rawText, docType);

      // 8. Create draft DocumentModel
      final docId = const Uuid().v4();
      _draftDocument = DocumentModel(
        documentId: docId,
        userId: userId,
        documentType: docType.name,
        rawText: rawText,
        parsedFields: parsedFields,
        imageUrl: '',
        localImagePath: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEdited: false,
        isSynced: false,
      );

      _setProcessing(false);
      print('Failed at the end');
      return true;
    } catch (e,st) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Harry Exception = $e');
      print('Harry Exception = $st');
      _setProcessing(false);
      return false;
    }
  }

  // Save the currently active draft document
  Future<bool> saveDraft() async {
    if (_draftDocument == null || _processedImage == null) {
      _errorMessage = 'No document to save.';
      notifyListeners();
      return false;
    }

    _setProcessing(true, 'Saving document...');
    _errorMessage = null;

    try {
      final savedDoc = await _repository.saveDocument(_draftDocument!, _processedImage!);
      print('Kratos = ${savedDoc.documentId}');
      print('Kratos userID = ${savedDoc.userId}');
      _draftDocument = savedDoc;
      _setProcessing(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setProcessing(false);
      return false;
    }
  }

  // Update existing document (from Edit Screen)
  Future<bool> updateExistingDocument(DocumentModel doc) async {
    _setProcessing(true, 'Updating document...');
    _errorMessage = null;

    try {
      final updated = await _repository.updateDocument(doc);
      _draftDocument = updated;
      _setProcessing(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setProcessing(false);
      return false;
    }
  }

  // Parser selector helper
  Map<String, String> _parseTextForType(String text, DocumentType type) {
    switch (type) {
      case DocumentType.invoice:
        return InvoiceParser().parse(text);
      case DocumentType.receipt:
        return ReceiptParser().parse(text);
      case DocumentType.panCard:
        return PanParser().parse(text);
      case DocumentType.aadhaarCard:
        return AadhaarParser().parse(text);
      case DocumentType.passport:
        return PassportParser().parse(text);
      case DocumentType.drivingLicense:
        return DrivingLicenseParser().parse(text);
      case DocumentType.businessCard:
        return BusinessCardParser().parse(text);
      case DocumentType.resume:
        return ResumeParser().parse(text);
      case DocumentType.utilityBill:
        return UtilityBillParser().parse(text);
      case DocumentType.bankStatement:
        return BankStatementParser().parse(text);
      case DocumentType.unknown:
        return <String, String>{};
    }
  }

  // Helper compression function
  Future<File?> _compressImageFile(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (_) {
      return null;
    }
  }

  void _setProcessing(bool value, [String? message]) {
    _isProcessing = value;
    _statusMessage = message;
    print('Harry Msg = $message');
    notifyListeners();
  }

  void _setStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
