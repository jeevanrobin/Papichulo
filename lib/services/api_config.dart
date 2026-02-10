class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api',
  );

  static const String adminKey = String.fromEnvironment(
    'ADMIN_API_KEY',
    defaultValue: '',
  );
}
