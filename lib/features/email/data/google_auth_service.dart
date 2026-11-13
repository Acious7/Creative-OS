import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/google_email_account.dart';

enum GoogleConnectionStatus { notConnected, connected, reconnectNeeded }

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  static const String gmailSendScope =
      'https://www.googleapis.com/auth/gmail.send';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[gmailSendScope],
  );

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  static const _accountKey = 'etole_google_connected_account';

  /// Saves account metadata to secure storage
  Future<void> saveAccount(GoogleEmailAccount account) async {
    try {
      await _storage.write(
        key: _accountKey,
        value: jsonEncode(account.toJson()),
      );
    } catch (_) {}
  }

  /// Returns the cached account metadata from secure storage, or recovers it from Google Play Services
  Future<GoogleEmailAccount?> getSavedAccount() async {
    try {
      final jsonStr = await _storage.read(key: _accountKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return GoogleEmailAccount.fromJson(jsonDecode(jsonStr));
      }
    } catch (_) {}

    // Fallback: Recover from GoogleSignIn session directly (e.g. across app reinstalls/updates)
    try {
      final currentUser =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (currentUser != null) {
        final account = GoogleEmailAccount(
          email: currentUser.email,
          displayName: currentUser.displayName ?? 'Creative Studio',
          photoUrl: currentUser.photoUrl,
          connectedAt: DateTime.now(),
        );
        await saveAccount(account);
        return account;
      }
    } catch (_) {}

    return null;
  }

  /// Honest check of connection status:
  /// - [notConnected]: No Google account is saved or signed in.
  /// - [connected]: Valid active Google session with working send permissions.
  /// - [reconnectNeeded]: Account exists, but token expired / needs re-authentication.
  Future<GoogleConnectionStatus> getConnectionStatus() async {
    final account = await getSavedAccount();
    if (account == null) {
      return GoogleConnectionStatus.notConnected;
    }

    try {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        return GoogleConnectionStatus.connected;
      }
    } catch (_) {}

    return GoogleConnectionStatus.reconnectNeeded;
  }

  /// Check if the user is currently signed in and active
  Future<bool> isSignedIn() async {
    final status = await getConnectionStatus();
    return status == GoogleConnectionStatus.connected;
  }

  /// Initiates interactive Google Sign In
  Future<GoogleEmailAccount?> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in dialog
        return null;
      }

      final account = GoogleEmailAccount(
        email: googleUser.email,
        displayName: googleUser.displayName ?? 'Creative Studio',
        photoUrl: googleUser.photoUrl,
        connectedAt: DateTime.now(),
      );

      await saveAccount(account);
      return account;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out and clear stored session
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _storage.delete(key: _accountKey);
    } catch (_) {}
  }

  /// Get valid OAuth2 access token, automatically refreshing if needed
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    try {
      var currentUser = _googleSignIn.currentUser;
      currentUser ??= await _googleSignIn.signInSilently();

      if (currentUser == null) {
        return null;
      }

      if (forceRefresh) {
        await currentUser.clearAuthCache();
      }

      final auth = await currentUser.authentication;
      return auth.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Ensures a valid access token is available.
  /// 1. Tries silent refresh first.
  /// 2. If that fails and [allowInteractive] is true, triggers interactive signIn().
  Future<String?> ensureValidAccessToken({
    bool allowInteractive = false,
  }) async {
    // 1. Try silent refresh with cache clear
    String? token = await getAccessToken(forceRefresh: true);
    if (token != null && token.isNotEmpty) {
      return token;
    }

    // 2. Try regular token fetch
    token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }

    // 3. If silent attempts failed and interactive prompt is allowed, prompt user
    if (allowInteractive) {
      final account = await signIn();
      if (account != null) {
        return await getAccessToken();
      }
    }

    return null;
  }

  /// Get currently signed in Google account object
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }
}
