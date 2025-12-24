class AppConfig {
  static const String apiBaseUrl =
  String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://13.203.221.152:3501/v1',
  );

  static const String imageBaseUrl =
  String.fromEnvironment(
    'IMAGE_BASE_URL',
    defaultValue: 'http://13.203.221.152:3501/uploads/product/',
  );

  static const bool isProduction =
  bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);

  static const googleApiKey = "AIzaSyCqSNtY8Y7DPKJ5s8j5ENm1d4e5lkOfoVk";
}

//http://10.0.2.2:3501