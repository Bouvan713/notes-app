import 'package:flutter/material.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/auth/views/splash_view.dart';
import '../../features/documents/data/models/document_model.dart';
import '../../features/documents/screens/dashboard_view.dart';
import '../../features/documents/screens/edit_document_view.dart';
import '../../features/ocr/screens/ocr_capture_view.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String addNote = '/add-note'; // Maps to OcrCaptureView
  static const String editNote = '/edit-note'; // Maps to EditDocumentView
  static const String editDocument = '/edit-document'; // Support editDocument alias

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashView(), settings);
      case login:
        return _fadeRoute(const LoginView(), settings);
      case signup:
        return _fadeRoute(const SignupView(), settings);
      case dashboard:
        return _fadeRoute(const DashboardView(), settings);
      case addNote:
        return _slideUpRoute(const OcrCaptureView(), settings);
      case editNote:
      case editDocument:
        final doc = settings.arguments as DocumentModel?;
        if (doc == null) {
          return _errorRoute('Document parameter is missing for edit view.');
        }
        return _slideUpRoute(EditDocumentView(document: doc), settings);
      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideUpRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
