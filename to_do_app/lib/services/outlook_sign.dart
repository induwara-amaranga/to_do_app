import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msal_auth/msal_auth.dart';

class OutlookAuthService {
  static const _clientId = '6450d522-3a1c-4005-ae93-1fdc7f91aea2';
  static const _redirectUri =
      "msauth://com.example.to_do_app/Oust7aZi9rTbGkNnTUHkeg3V6WQ%3D";
  //static const _scopes = ['User.Read', 'Calendars.ReadWrite'];

  //static late PublicClientApplication _pca;
  static String? _accessToken;
  static String? get accessToken => _accessToken;

  static final storage = FlutterSecureStorage();

  static late SingleAccountPca _pca;

  static Future<bool> restoreLastSession() async {
    print("🔄 Attempting to restore last Outlook session...");

    try {
      // 1️⃣ Read saved access token
      final savedToken = await storage.read(key: 'outlook_cal_accessToken');

      if (savedToken == null) {
        print("⚠️ No saved Outlook session found.");
        return false;
      }

      print("🔐 Found saved token, verifying silently...");

      _accessToken = savedToken;

      // 2️⃣ Try silent token acquisition (refresh internal state)
      final silentToken = await acquireTokenSilently();

      if (silentToken != null) {
        print("✅ Outlook session restored silently!");
        _accessToken = silentToken;

        // Update storage with refreshed token
        await storage.write(
          key: 'outlook_cal_accessToken',
          value: _accessToken,
        );

        return true;
      }

      // 3️⃣ Silent failed → Token expired
      print("⚠️ Saved token invalid/expired. Need full login.");
      return false;
    } catch (e) {
      print("❌ Error restoring Outlook session: $e");
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _pca.signOut();
      print("✅ Signed out successfully");
      _accessToken = null;
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

      print("🔑 Silent token acquired: ${result.accessToken}");
      return result.accessToken;
    } catch (e) {
      print("⚠️ Silent token failed: $e");
      return null; // will trigger interactive login
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
      //await _pca.signOut();
      final result = await _pca.acquireToken(
        scopes: [
          'https://graph.microsoft.com/User.Read',
          'https://graph.microsoft.com/Calendars.ReadWrite',
        ],
        prompt: Prompt.login,
      );

      print('Access Token: ${result.accessToken}');
      return result.accessToken;
    } catch (e) {
      print("❌sign in error $e");
      return null;
    }
  }

  static Future<bool> initialize() async {
    try {
      await init(); // initialize PCA instance

      print("🔍 Trying silent sign-in...");
      final silentToken = await acquireTokenSilently();

      if (silentToken != null) {
        await storage.write(
          key: 'outlook_cal_accessToken',
          value: _accessToken,
        );
        print("✅ Silent sign-in success");
        _accessToken = silentToken;
        return true;
      }

      print("⚠️ Silent failed → doing interactive sign-in...");
      _accessToken = await signIn();

      if (_accessToken != null) {
        print("✅ Interactive sign-in success");
        await storage.write(
          key: 'outlook_cal_accessToken',
          value: _accessToken,
        );
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ initialize error: $e");
      return false;
    }
  }
}
