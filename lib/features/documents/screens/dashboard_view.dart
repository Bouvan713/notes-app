import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../data/models/document_model.dart';
import '../data/models/document_type.dart';
import '../provider/document_provider.dart';
import '../provider/sync_provider.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../../core/routes/app_routes.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial fetch of user documents (forced remote fetch to sync up first time)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      
      if (authViewModel.currentUser != null) {
        docProvider.fetchDocuments(authViewModel.currentUser!.id, syncFromRemote: true);
        syncProvider.updateDocumentProvider(docProvider);
        syncProvider.triggerBackgroundSync();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortFilterSheet(BuildContext context, DocumentProvider docProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Filter & Sort Options',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Filter by document type
                  const Text('Filter by Document Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Types'),
                          selected: docProvider.filterType == null,
                          onSelected: (selected) {
                            setSheetState(() => docProvider.setFilterType(null));
                          },
                        ),
                        const SizedBox(width: 8),
                        ...DocumentType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(type.displayName),
                              selected: docProvider.filterType == type,
                              onSelected: (selected) {
                                setSheetState(() => docProvider.setFilterType(selected ? type : null));
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Sort by Option
                  const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Newest First'),
                        selected: docProvider.sortBy == 'date_desc',
                        onSelected: (val) => setSheetState(() => docProvider.setSortBy('date_desc')),
                      ),
                      ChoiceChip(
                        label: const Text('Oldest First'),
                        selected: docProvider.sortBy == 'date_asc',
                        onSelected: (val) => setSheetState(() => docProvider.setSortBy('date_asc')),
                      ),
                      ChoiceChip(
                        label: const Text('Title A-Z'),
                        selected: docProvider.sortBy == 'name',
                        onSelected: (val) => setSheetState(() => docProvider.setSortBy('name')),
                      ),
                      ChoiceChip(
                        label: const Text('Type'),
                        selected: docProvider.sortBy == 'type',
                        onSelected: (val) => setSheetState(() => docProvider.setSortBy('type')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Changes'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getDocTypeColor(String typeStr, ThemeData theme) {
    final type = parseDocumentType(typeStr);
    switch (type) {
      case DocumentType.invoice: return Colors.blue;
      case DocumentType.receipt: return const Color(0xFF10B981);
      case DocumentType.panCard: return Colors.orange;
      case DocumentType.aadhaarCard: return Colors.teal;
      case DocumentType.passport: return Colors.indigo;
      case DocumentType.drivingLicense: return Colors.amber;
      case DocumentType.businessCard: return Colors.purple;
      case DocumentType.resume: return Colors.pink;
      case DocumentType.utilityBill: return Colors.red;
      case DocumentType.bankStatement: return Colors.cyan;
      default: return Colors.grey;
    }
  }

  String _getDocumentTitle(DocumentModel doc) {
    final type = parseDocumentType(doc.documentType);
    String title = '';
    switch (type) {
      case DocumentType.invoice:
        title = doc.parsedFields['Vendor Name'] ?? doc.parsedFields['Invoice Number'] ?? '';
        break;
      case DocumentType.receipt:
        title = doc.parsedFields['Store Name'] ?? '';
        break;
      case DocumentType.panCard:
      case DocumentType.aadhaarCard:
      case DocumentType.passport:
      case DocumentType.drivingLicense:
      case DocumentType.resume:
      case DocumentType.businessCard:
        title = doc.parsedFields['Name'] ?? '';
        break;
      case DocumentType.utilityBill:
        title = doc.parsedFields['Consumer Number'] ?? '';
        break;
      case DocumentType.bankStatement:
        title = doc.parsedFields['Account Number'] ?? '';
        break;
      default:
        title = '';
    }
    
    if (title.trim().isEmpty) {
      title = type.displayName;
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final docProvider = Provider.of<DocumentProvider>(context);
    final syncProvider = Provider.of<SyncProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: theme.brightness == Brightness.dark
                    ? [const Color(0xFF6366F1), const Color(0xFFA855F7)]
                    : [const Color(0xFF4F46E5), const Color(0xFF9333EA)],
              ).createShader(bounds),
              child: const Icon(Icons.document_scanner_rounded, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'OCR Scanner',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Connection Status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: syncProvider.isSyncing
                ? const SpinKitRing(color: Colors.purple, size: 22, lineWidth: 2)
                : Icon(
                    syncProvider.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_rounded,
                    color: syncProvider.isOnline ? Colors.green : Colors.orange,
                    size: 24,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await authViewModel.logout();
              if (context.mounted) {
                docProvider.clearState();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sync status banner if syncing
            if (syncProvider.syncStatusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: theme.colorScheme.primary.withOpacity(0.12),
                child: Row(
                  children: [
                    const SpinKitRing(color: Colors.indigo, size: 14, lineWidth: 1.5),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        syncProvider.syncStatusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Search and Filters bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search documents, types, or fields...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  docProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) {
                        docProvider.setSearchQuery(val);
                      },
                    ),
                  ),
                  //TODO : Filter Options hidden
                  /*const SizedBox(width: 12),
                  IconButton.filledTonal(
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: docProvider.filterType != null 
                          ? theme.colorScheme.primary 
                          : null,
                    ),
                    tooltip: 'Filter & Sort',
                    onPressed: () => _showSortFilterSheet(context, docProvider),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),*/
                ],
              ),
            ),
            
            // List contents
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (authViewModel.currentUser != null) {
                    await docProvider.fetchDocuments(authViewModel.currentUser!.id, syncFromRemote: true);
                    await syncProvider.triggerBackgroundSync();
                  }
                },
                child: docProvider.isLoading
                    ? Center(
                        child: SpinKitRing(
                          color: theme.colorScheme.primary,
                          size: 50,
                          lineWidth: 3.5,
                        ),
                      )
                    : docProvider.filteredDocuments.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildDocumentsList(docProvider, authViewModel.currentUser?.id, theme),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addNote), // Maps to OCR Screen
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan Doc'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final bool isSearchActive = _searchController.text.isNotEmpty || theme.brightness == Brightness.dark;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearchActive ? Icons.search_off_rounded : Icons.snippet_folder_rounded,
                size: 72,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                isSearchActive ? 'No Search Matches Found' : 'No Scanned Documents',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isSearchActive
                      ? 'Try updating your search phrase or clearing selected type filters.'
                      : 'Digitize your document records offline. Scan receipt vouchers, ID cards, statements, and more.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              if (!isSearchActive) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.addNote),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Start First Scan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: Size.zero,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList(DocumentProvider docProvider, String? userId, ThemeData theme) {
    final docs = docProvider.filteredDocuments;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final title = _getDocumentTitle(doc);
        final dateStr = DateFormat.yMMMd().add_jm().format(doc.createdAt);
        final tagColor = _getDocTypeColor(doc.documentType, theme);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.editNote, // Maps to Edit document arguments
                arguments: doc,
              );
            },
            child: Row(
              children: [
                // Thumbnail Left
                Container(
                  width: 90,
                  height: 110,
                  color: theme.brightness == Brightness.dark
                      ? Colors.black26
                      : Colors.grey.shade100,
                  child: doc.localImagePath.isNotEmpty && File(doc.localImagePath).existsSync()
                      ? Image.file(
                          File(doc.localImagePath),
                          fit: BoxFit.cover,
                        )
                      : doc.imageUrl.isNotEmpty
                          ? Image.network(
                              doc.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image_outlined, color: theme.colorScheme.primary.withOpacity(0.5)),
                            ),
                ),
                
                // Details Right
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Badge & Sync status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                parseDocumentType(doc.documentType).displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tagColor,
                                ),
                              ),
                            ),
                            Icon(
                              doc.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                              color: doc.isSynced ? Colors.green.shade400 : Colors.orange.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Title
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Subtitle
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Actions (Swipe or Quick delete)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                      onPressed: () => _confirmDelete(context, docProvider, userId, doc),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DocumentProvider docProvider, String? userId, DocumentModel doc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document?'),
          content: Text('Are you sure you want to delete this ${parseDocumentType(doc.documentType).displayName} document? This action is permanent.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (userId != null) {
                  final ok = await docProvider.deleteDocument(userId, doc.documentId);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document deleted successfully.')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
