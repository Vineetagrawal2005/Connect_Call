/// Central constants for ConnectCall.
///
/// MANUAL SETUP (do this before running):
/// 1. Create a project at https://console.cloud.google.com / Firebase console.
/// 2. Create a ZEGOCLOUD project at https://console.zegocloud.com and copy
///    your AppID + AppSign below.
class AppConstants {
  // Firestore collections (fixed by spec — do not rename).
  static const String usersCollection = 'users';
  static const String callHistoryCollection = 'callHistory';
  static const String callRecordsSubcollection = 'records';

  // ---- ZEGOCLOUD (REPLACE THESE — required for calling to work) ----
  // Dashboard: https://console.zegocloud.com → your project → AppID / AppSign
  static const int zegoAppID = 1052037988; // e.g. 1234567890
  static const String zegoAppSign = '4e24debbc259628a0db91425205ed4f5f0872f9e4fb7f308b9b04ca67ae116fc';

  static bool get isZegoConfigured => zegoAppID != 0 && zegoAppSign.isNotEmpty && zegoAppSign != 'YOUR_ZEGO_APP_SIGN';

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
}
