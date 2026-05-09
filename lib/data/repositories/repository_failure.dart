final class RepositoryFailure implements Exception {
  const RepositoryFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    return message;
  }
}
