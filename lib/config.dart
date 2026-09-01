import 'package:flutter/foundation.dart';

const String _localWebBaseUrl = 'http://localhost/veterinaria/public/api';
const String _localAndroidEmulatorBaseUrl =
    'http://10.0.2.2/veterinaria/public/api';
const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

String get baseUrl {
  if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return _localAndroidEmulatorBaseUrl;
  }
  return _localWebBaseUrl;
}
