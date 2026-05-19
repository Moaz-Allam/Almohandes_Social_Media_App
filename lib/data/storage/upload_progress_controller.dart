import 'package:flutter/foundation.dart';

/// App-wide channel for "an upload is in progress" so any screen can render
/// a shared progress bar without each call site needing to wire its own
/// loading state.
///
/// Usage:
/// ```dart
/// final ticket = UploadProgressController.instance.begin('story.mp4');
/// try {
///   await doWork();
/// } finally {
///   ticket.complete();
/// }
/// ```
///
/// The Supabase Storage SDK does not expose per-byte progress callbacks for
/// `uploadBinary`, so this controller exposes:
///   - `activeCount`  → how many uploads are running (controls visibility)
///   - `latestLabel`  → optional caption shown above the bar
final class UploadProgressController extends ChangeNotifier {
  UploadProgressController._();

  static final UploadProgressController instance = UploadProgressController._();

  final List<_UploadTicket> _tickets = [];

  int get activeCount => _tickets.length;
  bool get isUploading => _tickets.isNotEmpty;
  String? get latestLabel => _tickets.isEmpty ? null : _tickets.last.label;

  UploadTicket begin(String label) {
    final ticket = _UploadTicket(label, _remove);
    _tickets.add(ticket);
    notifyListeners();
    return ticket;
  }

  void _remove(_UploadTicket ticket) {
    if (_tickets.remove(ticket)) {
      notifyListeners();
    }
  }
}

abstract class UploadTicket {
  void complete();
}

class _UploadTicket implements UploadTicket {
  _UploadTicket(this.label, this._onComplete);

  final String label;
  final void Function(_UploadTicket) _onComplete;
  bool _done = false;

  @override
  void complete() {
    if (_done) {
      return;
    }
    _done = true;
    _onComplete(this);
  }
}
