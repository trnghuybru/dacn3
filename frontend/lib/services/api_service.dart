import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  
  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Remove token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Register user
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
  
  // Login user
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Save token
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
  
  // Get current user info
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'Chưa đăng nhập'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Lỗi lấy thông tin người dùng'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Weather API Methods
  static const String weatherApiKey = ApiConfig.weatherApiKey;
  static const String weatherBaseUrl = ApiConfig.weatherBaseUrl;

  // Get current weather by coordinates
  static Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$weatherBaseUrl/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric&lang=vi'),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Lỗi lấy dữ liệu thời tiết'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Lỗi kết nối thời tiết: ${e.toString()}'};
    }
  }

  // Get 5 day / 3 hour forecast
  static Future<Map<String, dynamic>> getForecast(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$weatherBaseUrl/forecast?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric&lang=vi'),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Lỗi lấy dữ liệu dự báo'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Lỗi kết nối dự báo: ${e.toString()}'};
    }
  }

  // Geocoding API - Search locations by name
  static Future<Map<String, dynamic>> searchLocations(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$weatherApiKey'),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Lỗi tìm kiếm địa điểm'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Lỗi kết nối tìm kiếm: ${e.toString()}'};
    }
  }
}
