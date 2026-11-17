/// Domain-level failure surfaced to the UI with a user-readable message.
class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DuplicateNameException extends AppException {
  DuplicateNameException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

/// Raised when a record from one profile is used with another profile.
class ProfileMismatchException extends AppException {
  ProfileMismatchException(super.message);
}
