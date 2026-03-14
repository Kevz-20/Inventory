class SyncBackendConfig {
  const SyncBackendConfig._();

  // Replace this with your real backend URL when the server is ready.
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Optional bearer token if your backend requires authenticated sync.
  static const String authToken = '';

  static bool get isConfigured => baseUrl.trim().isNotEmpty;
}
