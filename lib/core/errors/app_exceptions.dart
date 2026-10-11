class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'AppException: $message ${code != null ? '($code)' : ''}';
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

class SpeechRecognitionException extends AppException {
  const SpeechRecognitionException(super.message,
      {super.code, super.originalError});
}

class TtsException extends AppException {
  const TtsException(super.message, {super.code, super.originalError});
}

class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.originalError});
}

class BackupException extends AppException {
  const BackupException(super.message, {super.code, super.originalError});
}

class NotificationException extends AppException {
  const NotificationException(super.message, {super.code, super.originalError});
}
