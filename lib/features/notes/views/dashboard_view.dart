import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/responsive.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/note_model.dart';
import '../viewmodels/notes_viewmodel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final notesViewModel = Provider.of<NotesViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.id ?? '';

    // StreamProvider feeding the list of notes to the DashboardBody child
    return StreamProvider<List<NoteModel>>.value(
      value: notesViewModel.getNotesStream(userId),
      initialData: const [],
      catchError: (context, error) {
        debugPrint('Firestore Stream Error: $error');
        return const [];
      },
      child: const DashboardBody(),
    );
  }
}

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final notesViewModel = Provider.of<NotesViewModel>(context, listen: false);

    // Confirmation dialog before logging out
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      notesViewModel.clearNotesState();
      await authViewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  void _confirmDelete(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final notesViewModel = Provider.of<NotesViewModel>(context, listen: false);
      final success = await notesViewModel.deleteNote(noteId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notesViewModel.errorMessage ?? 'Failed to delete note.'),
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
    final scaleFactor = context.scaleFactor;
    
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userName = authViewModel.currentUser?.name ?? 'User';
    
    // Read list of notes injected by StreamProvider
    final allNotes = Provider.of<List<NoteModel>>(context);
    
    // Filter notes locally by search query
    final notes = allNotes.where((note) {
      final query = _searchQuery.toLowerCase();
      return note.title.toLowerCase().contains(query) ||
             note.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Icon(Icons.notes_rounded, color: theme.colorScheme.primary, size: 28 * scaleFactor),
            // SizedBox(width: 8 * scaleFactor),
            Text(
              'Notes Manager',
              style: TextStyle(
                fontSize: 20 * scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, size: 24 * scaleFactor),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          SizedBox(width: 8 * scaleFactor),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addNote),
        icon: Icon(Icons.add_rounded, size: 24 * scaleFactor),
        label: Text(
          'New Note',
          style: TextStyle(
            fontSize: 14 * scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome / Stats Banner
          Padding(
            padding: EdgeInsets.fromLTRB(
              20 * scaleFactor,
              8 * scaleFactor,
              20 * scaleFactor,
              16 * scaleFactor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName 👋',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 22 * scaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        'Keep your workspace tidy and clean.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14 * scaleFactor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Premium Badge for Notes Count
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scaleFactor,
                    vertical: 10 * scaleFactor,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20 * scaleFactor),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.15),
                        theme.colorScheme.secondary.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        size: 16 * scaleFactor,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 6 * scaleFactor),
                      Text(
                        '${allNotes.length} Note${allNotes.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * scaleFactor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scaleFactor,
              vertical: 8 * scaleFactor,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(fontSize: 16 * scaleFactor),
              decoration: InputDecoration(
                hintText: 'Search notes by title or content...',
                prefixIcon: Icon(Icons.search_rounded, size: 22 * scaleFactor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 20 * scaleFactor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
              ),
            ),
          ),

          SizedBox(height: 12 * scaleFactor),

          // Notes Listing Grid/List
          Expanded(
            child: allNotes.isEmpty
                ? _buildEmptyState(theme, isDark, scaleFactor)
                : notes.isEmpty
                    ? _buildNoSearchResultsState(theme, scaleFactor)
                    : _buildNotesGrid(context, notes, theme, isDark, scaleFactor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, double scaleFactor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0 * scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24 * scaleFactor),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.08),
              ),
              child: Icon(
                Icons.notes_rounded,
                size: 64 * scaleFactor,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24 * scaleFactor),
            Text(
              'No Notes Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20 * scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8 * scaleFactor),
            Text(
              'Tap the "New Note" button below to add your first markdown or quick text card.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14 * scaleFactor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(ThemeData theme, double scaleFactor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0 * scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48 * scaleFactor,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            SizedBox(height: 16 * scaleFactor),
            Text(
              'No matches found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8 * scaleFactor),
            Text(
              'Try adjusting your search query or clear the input field.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14 * scaleFactor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesGrid(
    BuildContext context,
    List<NoteModel> notesList,
    ThemeData theme,
    bool isDark,
    double scaleFactor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Grid calculations: Responsive layout
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 900
            ? 3
            : width > 600
                ? 2
                : 1;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            20 * scaleFactor,
            8 * scaleFactor,
            20 * scaleFactor,
            96 * scaleFactor,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16 * scaleFactor,
            mainAxisSpacing: 16 * scaleFactor,
            mainAxisExtent: 180 * scaleFactor,
          ),
          itemCount: notesList.length,
          itemBuilder: (context, index) {
            final note = notesList[index];
            final formattedDate = DateFormat.yMMMd().format(note.updatedAt.toDate());

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20 * scaleFactor),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.editNote,
                    arguments: note,
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(18.0 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note Header: Title and action buttons
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16 * scaleFactor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, size: 18 * scaleFactor),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.editNote,
                                arguments: note,
                              );
                            },
                          ),
                          SizedBox(width: 12 * scaleFactor),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18 * scaleFactor, color: theme.colorScheme.error),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDelete(note.id),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      // Description Content
                      Expanded(
                        child: Text(
                          note.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14 * scaleFactor,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      // Timestamp footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 12 * scaleFactor,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                              SizedBox(width: 4 * scaleFactor),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11 * scaleFactor,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
