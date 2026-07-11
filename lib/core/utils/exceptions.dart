class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

class PermissionException extends AppException {
  const PermissionException(super.message);
}
