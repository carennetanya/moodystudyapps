sealed class Failure {
  final String message;
  const Failure(this.message);
}

class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class AudioFailure extends Failure {
  const AudioFailure(String message) : super(message);
}

class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message);
}

class ServiceFailure extends Failure {
  const ServiceFailure(String message) : super(message);
}

class ParseFailure extends Failure {
  const ParseFailure(String message) : super(message);
}
