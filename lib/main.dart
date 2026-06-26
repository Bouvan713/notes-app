import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/documents/data/repository/document_repository.dart';
import 'features/documents/provider/document_provider.dart';
import 'features/documents/provider/sync_provider.dart';
import 'features/ocr/provider/ocr_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using current platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  runApp(const NotesManagerApp());
}

class NotesManagerApp extends StatelessWidget {
  const NotesManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<DocumentRepository>(
          create: (_) => DocumentRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthViewModel(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              DocumentProvider(context.read<DocumentRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              OcrProvider(context.read<DocumentRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SyncProvider(context.read<DocumentRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'OCR Document Scanner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
