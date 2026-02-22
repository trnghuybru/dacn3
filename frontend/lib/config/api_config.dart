class ApiConfig {
  // For Android emulator, use 'http://10.0.2.2:5000'
  // For iOS simulator, use 'http://localhost:5000'
  // For physical device, use your computer's IP address, e.g., 'http://192.168.1.100:5000'
  static const String baseUrl = 'http://192.168.1.14:5000';
  
  // Timeout duration for API calls
  static const Duration timeout = Duration(seconds: 30);
}
