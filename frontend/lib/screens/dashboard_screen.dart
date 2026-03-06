import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentWeather;
  List<dynamic>? _forecast;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearchingLocation = false;

  // Default coordinates (Hanoi)
  double _lat = 21.0285;
  double _lon = 105.8542;

  @override
  void initState() {
    super.initState();
    _initLocationAndWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearchingLocation = true);
    final result = await ApiService.searchLocations(query);
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _searchResults = result['data'];
        }
        _isSearchingLocation = false;
      });
    }
  }

  void _selectLocation(double lat, double lon) {
    setState(() {
      _lat = lat;
      _lon = lon;
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
    });
    _fetchWeatherData();
  }

  Future<void> _initLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Position? position = await _determinePosition();
      if (position != null) {
        _lat = position.latitude;
        _lon = position.longitude;
      }
      await _fetchWeatherData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Fallback to default coordinates
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null; // Fallback to default coordinates
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentResult = await ApiService.getCurrentWeather(_lat, _lon);
      final forecastResult = await ApiService.getForecast(_lat, _lon);

      if (mounted) {
        setState(() {
          if (currentResult['success'] == true) {
            _currentWeather = currentResult['data'];
          } else {
            _error = currentResult['error'];
          }

          if (forecastResult['success'] == true) {
            _forecast = forecastResult['data']['list'];
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi không xác định: $e';
          _isLoading = false;
        });
      }
    }
  }

  IconData _getWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'drizzle':
        return Icons.grain;
      case 'rain':
        return Icons.beach_access;
      case 'snow':
        return Icons.ac_unit;
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      default:
        return Icons.cloud;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _currentWeather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchWeatherData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final weather = _currentWeather!;
    final main = weather['main'];
    final wind = weather['wind'];
    final weatherDesc = weather['weather'][0];

    return RefreshIndicator(
      onRefresh: _initLocationAndWeather,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Weather Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[400]!,
                    Colors.purple[400]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location or Search bar
                  _isSearching
                      ? Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Tìm thành phố...',
                                hintStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.search, color: Colors.white),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => setState(() => _isSearching = false),
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: _handleSearch,
                            ),
                            if (_isSearchingLocation)
                              const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.white),
                            if (_searchResults.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final res = _searchResults[index];
                                    return ListTile(
                                      title: Text(
                                        '${res['name']}, ${res['country']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      subtitle: res['state'] != null
                                          ? Text(res['state'], style: const TextStyle(color: Colors.white70))
                                          : null,
                                      onTap: () => _selectLocation(res['lat'], res['lon']),
                                    );
                                  },
                                ),
                              ),
                          ],
                        )
                      : InkWell(
                          onTap: () => setState(() => _isSearching = true),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                weather['name'] ?? 'Vị trí hiện tại',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                  const SizedBox(height: 16),
                  
                  // Main Temperature and Condition
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(main['temp'] as num).round()}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(_getWeatherIcon(weatherDesc['main']), color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                weatherDesc['description'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cảm giác như ${(main['feels_like'] as num).round()}°C',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _getWeatherIcon(weatherDesc['main']),
                        color: Colors.yellow[300],
                        size: 80,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        icon: Icons.water_drop,
                        label: 'Độ ẩm',
                        value: '${main['humidity']}%',
                      ),
                      _buildMetric(
                        icon: Icons.air,
                        label: 'Gió',
                        value: '${(wind['speed'] as num).toStringAsFixed(1)} m/s',
                      ),
                      _buildMetric(
                        icon: Icons.visibility,
                        label: 'Tầm nhìn',
                        value: '${(weather['visibility'] / 1000).toStringAsFixed(1)} km',
                      ),
                      _buildMetric(
                        icon: Icons.speed,
                        label: 'Áp suất',
                        value: '${main['pressure']}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Hourly Forecast Card
            if (_forecast != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dự báo theo giờ (3h)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 8, // Show next 24 hours (8 intervals of 3h)
                        itemBuilder: (context, index) {
                          final item = _forecast![index];
                          final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
                          final hourStr = '${time.hour}:00';
                          final temp = '${(item['main']['temp'] as num).round()}°';
                          final mainCond = item['weather'][0]['main'];
                          final rain = item['pop'] as num; // Probability of precipitation

                          return _buildHourlyItem(
                            hourStr,
                            _getWeatherIcon(mainCond),
                            temp,
                            hasRain: rain > 0,
                            rainPercent: '${(rain * 100).round()}%',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            // Daily Forecast Card
            if (_forecast != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dự báo 5 ngày tới',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Group by day - simple logic picking one entry per day
                    ..._buildDailyForecastList(),
                  ],
                ),
              ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDailyForecastList() {
    final List<Widget> widgets = [];
    final Set<String> processedDays = {};
    
    for (var item in _forecast!) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dayStr = _getDayName(date.weekday);
      
      // Basic logic: take the entry nearest to 12:00 PM for each day
      if (!processedDays.contains(dayStr) && widgets.length < 5) {
        processedDays.add(dayStr);
        final tempMin = (item['main']['temp_min'] as num).round();
        final tempMax = (item['main']['temp_max'] as num).round();
        final condition = item['weather'][0]['description'];
        final icon = _getWeatherIcon(item['weather'][0]['main']);

        widgets.add(_buildDailyItem(dayStr, icon, condition, tempMin, tempMax));
        if (widgets.length < 5) {
          widgets.add(const Divider(height: 24));
        }
      }
    }
    return widgets;
  }

  String _getDayName(int day) {
    if (DateTime.now().weekday == day) return 'Hôm nay';
    switch (day) {
      case 1: return 'Thứ 2';
      case 2: return 'Thứ 3';
      case 3: return 'Thứ 4';
      case 4: return 'Thứ 5';
      case 5: return 'Thứ 6';
      case 6: return 'Thứ 7';
      case 7: return 'Chủ Nhật';
      default: return '';
    }
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyItem(
    String time,
    IconData icon,
    String temp, {
    bool hasRain = false,
    String? rainPercent,
  }) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Icon(icon, color: Colors.blue[300], size: 22),
          const SizedBox(height: 6),
          Text(
            temp,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (hasRain && rainPercent != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 10, color: Colors.blue[400]),
                const SizedBox(width: 2),
                Text(
                  rainPercent,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyItem(
    String day,
    IconData icon,
    String condition,
    int lowTemp,
    int highTemp,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Icon(icon, color: Colors.orange[400], size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            condition[0].toUpperCase() + condition.substring(1),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          '$lowTemp°',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.yellow[300]!,
                  Colors.orange[400]!,
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$highTemp°',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
