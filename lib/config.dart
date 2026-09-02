const String _remoteBaseUrl =
    'https://vetclinicapp.online/veterinaria/public/api';
const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

String get baseUrl {
  if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
  return _remoteBaseUrl;
}
