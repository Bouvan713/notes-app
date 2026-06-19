class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class AuthException extends AppException {
  AuthException(super.message, [super.code]);
}

class NotesException extends AppException {
  NotesException(super.message, [super.code]);
}
