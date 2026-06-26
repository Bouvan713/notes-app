import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String documentId;
  final String userId;
  final String documentType;
  final String rawText;
  final Map<String, String> parsedFields;
  final String imageUrl;
  final String localImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final bool isSynced;

  DocumentModel({
    required this.documentId,
    required this.userId,
    required this.documentType,
    required this.rawText,
    required this.parsedFields,
    required this.imageUrl,
    required this.localImagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.isEdited,
    required this.isSynced,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map, String docId) {
    return DocumentModel(
      documentId: docId,
      userId: map['userId'] ?? '',
      documentType: map['documentType'] ?? 'unknown',
      rawText: map['rawText'] ?? '',
      parsedFields: Map<String, String>.from(map['parsedFields'] ?? {}),
      imageUrl: map['imageUrl'] ?? '',
      localImagePath: map['localImagePath'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null 
              ? DateTime.parse(map['createdAt'].toString()) 
              : DateTime.now()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] != null 
              ? DateTime.parse(map['updatedAt'].toString()) 
              : DateTime.now()),
      isEdited: map['isEdited'] ?? false,
      isSynced: map['isSynced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'documentType': documentType,
      'rawText': rawText,
      'parsedFields': parsedFields,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEdited': isEdited,
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'userId': userId,
      'documentType': documentType,
      'rawText': rawText,
      'parsedFields': parsedFields,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEdited': isEdited,
      'isSynced': isSynced,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      documentId: json['documentId'] ?? '',
      userId: json['userId'] ?? '',
      documentType: json['documentType'] ?? 'unknown',
      rawText: json['rawText'] ?? '',
      parsedFields: Map<String, String>.from(json['parsedFields'] ?? {}),
      imageUrl: json['imageUrl'] ?? '',
      localImagePath: json['localImagePath'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString()) 
          : DateTime.now(),
      isEdited: json['isEdited'] ?? false,
      isSynced: json['isSynced'] ?? false,
    );
  }

  DocumentModel copyWith({
    String? documentId,
    String? userId,
    String? documentType,
    String? rawText,
    Map<String, String>? parsedFields,
    String? imageUrl,
    String? localImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isSynced,
  }) {
    return DocumentModel(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      rawText: rawText ?? this.rawText,
      parsedFields: parsedFields ?? this.parsedFields,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
