import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../provider/ocr_provider.dart';

class OcrCaptureView extends StatelessWidget {
  const OcrCaptureView({super.key});

  @override
  Widget build(BuildContext context) {
    final ocrProvider = Provider.of<OcrProvider>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // visual banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: theme.brightness == Brightness.dark
                            ? [const Color(0xFF6366F1), const Color(0xFFA855F7)]
                            : [const Color(0xFF4F46E5), const Color(0xFF9333EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.document_scanner_rounded, size: 64, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'Digitize Documents',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan receipts, invoices, IDs, passports, cards, or resumes to extract details instantly.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Select capture source:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SourceCard(
                          icon: Icons.camera_alt_rounded,
                          title: 'Camera',
                          description: 'Take photo of document',
                          onTap: () => _startOcr(context, ocrProvider, authViewModel.currentUser?.id, ImageSource.camera),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SourceCard(
                          icon: Icons.photo_library_rounded,
                          title: 'Gallery',
                          description: 'Import from photos',
                          onTap: () => _startOcr(context, ocrProvider, authViewModel.currentUser?.id, ImageSource.gallery),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surface.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Hold the document flat, align it in the viewfinder, and ensure good lighting for optimal results.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (ocrProvider.isProcessing)
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
                        Text(
                          ocrProvider.statusMessage ?? 'Processing...',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  void _startOcr(BuildContext context, OcrProvider ocrProvider, String? userId, ImageSource source) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated.')),
      );
      return;
    }

    final success = await ocrProvider.processDocument(userId, source);
    if (success && context.mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.editDocument,
        arguments: ocrProvider.draftDocument,
      );
    } else if (ocrProvider.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ocrProvider.errorMessage!),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _startOcr(context, ocrProvider, userId, source),
          ),
        ),
      );
    }
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade300,
          ),
          color: theme.brightness == Brightness.dark
              ? theme.cardTheme.color
              : Colors.white,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(icon, size: 28, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
