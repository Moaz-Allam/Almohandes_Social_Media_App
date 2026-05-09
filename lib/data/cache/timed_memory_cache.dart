final class TimedMemoryCache<T> {
  TimedMemoryCache({required this.ttl, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _now;

  T? _value;
  DateTime? _updatedAt;
  Future<T>? _inFlight;

  T? get value => _value;

  bool get hasValue => _value != null;

  bool get hasFreshValue {
    final updatedAt = _updatedAt;
    return _value != null &&
        updatedAt != null &&
        _now().difference(updatedAt) < ttl;
  }

  Future<T> read(Future<T> Function() fetcher, {bool forceRefresh = false}) {
    if (!forceRefresh && hasFreshValue) {
      return Future.value(_value as T);
    }

    final existingRequest = _inFlight;
    if (!forceRefresh && existingRequest != null) {
      return existingRequest;
    }

    final request = fetcher().then((freshValue) {
      put(freshValue);
      return freshValue;
    });

    _inFlight = request;
    return request.whenComplete(() {
      if (identical(_inFlight, request)) {
        _inFlight = null;
      }
    });
  }

  void put(T value) {
    _value = value;
    _updatedAt = _now();
  }

  void clear() {
    _value = null;
    _updatedAt = null;
    _inFlight = null;
  }
}
