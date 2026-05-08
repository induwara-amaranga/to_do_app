import 'package:flutter/foundation.dart';

// F-07: Central auth state — single source of truth for all sign-in states.
class AuthProvider extends ChangeNotifier {
  bool _isGoogleSignedIn;
  bool _isOutlookSignedIn;
  String _displayName;

  AuthProvider({
    bool isGoogleSignedIn = false,
    bool isOutlookSignedIn = false,
    String displayName = '',
  }) : _isGoogleSignedIn = isGoogleSignedIn,
       _isOutlookSignedIn = isOutlookSignedIn,
       _displayName = displayName;

  bool get isGoogleSignedIn => _isGoogleSignedIn;
  bool get isOutlookSignedIn => _isOutlookSignedIn;
  String get displayName => _displayName;

  void setGoogleSignedIn(bool value, {String displayName = ''}) {
    _isGoogleSignedIn = value;
    if (value) _displayName = displayName;
    notifyListeners();
  }

  void setOutlookSignedIn(bool value) {
    _isOutlookSignedIn = value;
    notifyListeners();
  }

  void signOutGoogle() {
    _isGoogleSignedIn = false;
    _displayName = '';
    notifyListeners();
  }

  void signOutOutlook() {
    _isOutlookSignedIn = false;
    notifyListeners();
  }
}
