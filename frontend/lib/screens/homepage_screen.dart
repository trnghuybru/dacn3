import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../widgets/app_header.dart';
import 'map_screen.dart';
import 'news_screen.dart';
import 'sos_screen.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    _buildHomeContent(),
    const MapScreen(),
    const NewsScreen(),
    const SosScreen(),
    const ProfileScreen(),
  ];

  Future<void> _handleLogout() async {
    await ApiService.removeToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),

      // Floating Action Button (SOS)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Handle SOS action
        },
        backgroundColor: Colors.red,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.info, color: Colors.white, size: 16),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'Tin tức',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning, color: Colors.red),
              label: 'SOS',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // App Header
        AppHeader(
          onLogout: _handleLogout,
          onRefresh: () {
            // TODO: Refresh weather data
          },
        ),

        // Main Content - Using DashboardScreen widget
        const Expanded(child: DashboardScreen()),
      ],
    );
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
          style: const TextStyle(color: Colors.white70, fontSize: 11),
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
            condition,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        Text(
          '$lowTemp',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow[300]!, Colors.orange[400]!],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$highTemp',
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
