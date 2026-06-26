import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../data/models/document_model.dart';
import '../data/models/document_type.dart';
import '../../ocr/provider/ocr_provider.dart';
import '../provider/document_provider.dart';

class FieldDraft {
  String key;
  String value;
  FieldDraft({required this.key, required this.value});
}

class EditDocumentView extends StatefulWidget {
  final DocumentModel document;

  const EditDocumentView({super.key, required this.document});

  @override
  State<EditDocumentView> createState() => _EditDocumentViewState();
}

class _EditDocumentViewState extends State<EditDocumentView> {
  late DocumentType _selectedType;
  final List<FieldDraft> _fields = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = parseDocumentType(widget.document.documentType);
    
    // Initialize list of fields from map
    widget.document.parsedFields.forEach((k, v) {
      _fields.add(FieldDraft(key: k, value: v));
    });
  }

  void _addNewField() {
    setState(() {
      _fields.add(FieldDraft(key: '', value: ''));
    });
  }

  void _removeField(int index) {
    print('Kratos Index = $index');
    print('Kratos Fields = $_fields');
    _fields.forEach((element) {
      print('Harry Before = ${element.key}, =  ${element.value}');
    },);
    setState(() {
      _fields.removeAt(index);
    });

    _fields.forEach((element) {
      print('Harry After = ${element.key}, =  ${element.value}');
    },);
  }

  void _saveDocument() async {
    // 1. Validate
    final Map<String, String> finalFields = {};
    for (final field in _fields) {
      final trimmedKey = field.key.trim();
      final trimmedVal = field.value.trim();
      if (trimmedKey.isNotEmpty) {
        finalFields[trimmedKey] = trimmedVal;
      }
    }

    setState(() => _isSaving = true);

    try {
      final ocrProvider = Provider.of<OcrProvider>(context, listen: false);
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

      final isNewScan = widget.document.localImagePath.isEmpty && widget.document.imageUrl.isEmpty;

      // Update model
      final updatedDoc = widget.document.copyWith(
        documentType: _selectedType.name,
        parsedFields: finalFields,
        isEdited: true,
      );

      bool success = false;
      DocumentModel savedDoc;

      if (isNewScan) {
        // Saving a newly processed scan
        // First update local ocrProvider draft
        ocrProvider.changeDocumentType(_selectedType);
        // Clear draft fields and override with final fields
        for (final k in ocrProvider.draftDocument!.parsedFields.keys.toList()) {
          ocrProvider.deleteField(k);
        }
        finalFields.forEach((k, v) {
          ocrProvider.addField(k, v);
        });

        success = await ocrProvider.saveDraft();
        savedDoc = ocrProvider.draftDocument ?? updatedDoc;
      } else {
        // Editing an existing document
        success = await ocrProvider.updateExistingDocument(updatedDoc);
        savedDoc = ocrProvider.draftDocument ?? updatedDoc;
      }

      if (success && mounted) {
        // Sync document changes in list provider locally
        documentProvider.updateLocalDocument(savedDoc);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(savedDoc.isSynced 
                ? 'Document saved and synced to cloud!' 
                : 'Saved locally. Will sync when internet is available.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ocrProvider.errorMessage ?? 'Failed to save document.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 28),
            onPressed: _isSaving ? null : _saveDocument,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Preview Card
                  _buildImagePreview(size, theme),
                  const SizedBox(height: 24),

                  // Classification Dropdown
                  DropdownButtonFormField<DocumentType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Document Type',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: DocumentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (newType) {
                      if (newType != null) {
                        setState(() {
                          _selectedType = newType;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Collapsible Raw OCR Text
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(Icons.text_fields_rounded, color: theme.colorScheme.primary),
                        title: const Text(
                          'View Raw Recognized Text',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.black26
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  widget.document.rawText.isEmpty 
                                      ? 'No text recognized.' 
                                      : widget.document.rawText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Fields Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extracted Data Fields',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add Field'),
                        onPressed: _addNewField,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Field List
                  _fields.isEmpty
                      ? _buildEmptyFieldsView(theme)
                      : ListView.separated(
                    key: ValueKey(_fields.length),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _fields.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildFieldRow(index, theme);
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          // Saving overlay
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitFadingCube(
                          color: theme.colorScheme.primary,
                          size: 40.0,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Saving changes...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Size size, ThemeData theme) {
    final hasLocal = widget.document.localImagePath.isNotEmpty;
    final hasRemote = widget.document.imageUrl.isNotEmpty;

    return Container(
      height: size.height * 0.22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.shade300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasLocal && File(widget.document.localImagePath).existsSync())
            Image.file(
              File(widget.document.localImagePath),
              fit: BoxFit.cover,
            )
          else if (hasRemote)
            Image.network(
              widget.document.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SpinKitRing(
                    color: theme.colorScheme.primary,
                    size: 40,
                    lineWidth: 3,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
              ),
            )
          else
            const Center(
              child: Icon(Icons.document_scanner_rounded, size: 64, color: Colors.grey),
            ),
          
          // Gradient cover
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.bottomLeft,
              child: const Text(
                'Document Capture Frame',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyFieldsView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.rule_folder_rounded, size: 48, color: theme.colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text(
            'No fields extracted.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Add Field" to manually define structured keys and values.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(int index, ThemeData theme) {
    final field = _fields[index];
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Key (Rename Field)
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: field.key,
            decoration: const InputDecoration(
              labelText: 'Field Key',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            onChanged: (val) {
              field.key = val;
            },
          ),
        ),
        const SizedBox(width: 12),
        // Field Value
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: field.value,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Value',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (val) {
              field.value = val;
            },
          ),
        ),
        const SizedBox(width: 8),
        // Delete field action
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          onPressed: () => _removeField(index),
          padding: const EdgeInsets.only(top: 14),
        )
      ],
    );
  }
}
