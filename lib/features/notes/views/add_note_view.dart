import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/responsive.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/notes_viewmodel.dart';

class AddNoteView extends StatefulWidget {
  const AddNoteView({super.key});

  @override
  State<AddNoteView> createState() => _AddNoteViewState();
}

class _AddNoteViewState extends State<AddNoteView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final notesViewModel = Provider.of<NotesViewModel>(context, listen: false);
      final userId = authViewModel.currentUser?.id ?? '';

      final success = await notesViewModel.addNote(
        userId,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note saved successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notesViewModel.errorMessage ?? 'Failed to save note.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notesViewModel = Provider.of<NotesViewModel>(context);
    final scaleFactor = context.scaleFactor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_rounded, size: 24 * scaleFactor),
          tooltip: 'Discard',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Note',
          style: TextStyle(
            fontSize: 20 * scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded, size: 28 * scaleFactor),
            tooltip: 'Save Note',
            onPressed: notesViewModel.isLoading ? null : _save,
          ),
          SizedBox(width: 8 * scaleFactor),
        ],
      ),
      body: Stack(
        children: [
          // Editor Fields
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(24.0 * scaleFactor),
                children: [
                  // Title Input
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24 * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                  Divider(height: 32 * scaleFactor, thickness: 1),
                  // Description Input
                  TextFormField(
                    controller: _descriptionController,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16 * scaleFactor,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts here...',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16 * scaleFactor,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (notesViewModel.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24 * scaleFactor),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 16 * scaleFactor),
                      Text(
                        'Saving note...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
