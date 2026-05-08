import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msal_auth/msal_auth.dart';

class OutlookAuthService {
  // F-01: must match msal_config.json client_id
  static const _clientId = '1046c7a4-3a52-4845-b477-81163b44f47e';
  static const _redirectUri =
      "msauth://com.example.to_do_app/Oust7aZi9rTbGkNnTUHkeg3V6WQ%3D";

  static String? _accessToken;
  static String? get accessToken => _accessToken;

  static final storage = FlutterSecureStorage();

  static late SingleAccountPca _pca;

  // B-02: only assign _accessToken after verification succeeds
  // static Future<bool> restoreLastSession() async {
  //   print("🔄 Attempting to restore last Outlook session...");

  //   try {
  //     final savedToken = await storage.read(key: 'outlook_cal_accessToken');

  //     if (savedToken == null) {
  //       print("⚠️ No saved Outlook session found.");
  //       return false;
  //     }

  //     print("🔐 Found saved token, verifying silently...");

  //     final silentToken = await acquireTokenSilently();

  //     if (silentToken != null) {
  //       print("✅ Outlook session restored silently!");
  //       _accessToken = silentToken;
  //       await storage.write(
  //         key: 'outlook_cal_accessToken',
  //         value: silentToken,
  //       );
  //       return true;
  //     }

  //     // Silent failed → token expired; clear stale token
  //     _accessToken = null;
  //     print("⚠️ Saved token invalid/expired. Need full login.");
  //     return false;
  //   } catch (e) {
  //     print("❌ Error restoring Outlook session: $e");
  //     _accessToken = null;
  //     return false;
  //   }
  // }

  // F-09: delete stored token on sign-out
  static Future<void> signOut() async {
    try {
      await _pca.signOut();
      _accessToken = null;
      await storage.delete(key: 'outlook_cal_accessToken');
      print("✅ Signed out successfully");
    } catch (e) {
      print("❌ Sign-out failed: $e");
    }
  }

  static Future<String?> acquireTokenSilently() async {
    try {
      await init();
      final result = await _pca.acquireTokenSilent(
        scopes: [
          'https://graph.microsoft.com/User.Read',
          'https://graph.microsoft.com/Calendars.ReadWrite',
        ],
      );

      // F-04: never log the full token
      print("🔑 Silent token acquired");
      return result.accessToken;
    } catch (e) {
      print("⚠️ Silent token failed: $e");
      return null;
    }
  }

  static Future<void> init() async {
    try {
      _pca = await SingleAccountPca.create(
        clientId: _clientId,
        androidConfig: AndroidConfig(
          configFilePath: 'assets/msal_config.json',
          redirectUri: _redirectUri,
        ),
      );
    } catch (e) {
      print("❌init error: $e");
    }
  }

  static Future<String?> signIn() async {
    try {
      final result = await _pca.acquireToken(
        scopes: [
          'https://graph.microsoft.com/User.Read',
          'https://graph.microsoft.com/Calendars.ReadWrite',
        ],
        prompt: Prompt.login,
      );

      // F-04: never log the full token
      print('✅ Interactive sign-in succeeded');
      return result.accessToken;
    } catch (e) {
      print("❌sign in error $e");
      return null;
    }
  }

  // F-02: silent sign-in only at startup; interactive triggered by user action
  // B-01: assign _accessToken before writing to storage
  static Future<bool> initialize() async {
    try {
      await init();

      print("🔍 Trying silent sign-in...");
      final silentToken = await acquireTokenSilently();

      if (silentToken != null) {
        _accessToken = silentToken;
        await storage.write(key: 'outlook_cal_accessToken', value: silentToken);
        print("✅ Silent sign-in success");
        return true;
      }

      print("⚠️ Silent sign-in failed — interactive sign-in required.");
      return false;
    } catch (e) {
      print("❌ initialize error: $e");
      return false;
    }
  }
}
