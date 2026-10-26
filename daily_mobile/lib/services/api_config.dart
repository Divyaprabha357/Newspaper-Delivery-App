class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'DAILY_API_BASE_URL',
    defaultValue: 'https://daily-backend-ku7k.onrender.com/api',
  );
}
