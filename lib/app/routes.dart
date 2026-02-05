import 'package:flutter/material.dart';
import 'package:campusapp/features/splash/presentation/screens/splash_screen.dart';
import 'package:campusapp/features/auth/presentation/screens/gate_screen.dart';
import 'package:campusapp/features/auth/presentation/screens/login_screen.dart';
import 'package:campusapp/features/auth/presentation/screens/admin_login_screen.dart';
import 'package:campusapp/features/home/presentation/screens/main_wrapper.dart';
import 'package:campusapp/features/search/presentation/screens/search_screen.dart';
import 'package:campusapp/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_event_list_screen.dart';
import '../features/admin/presentation/screens/admin_create_event_screen.dart';
import '../features/admin/presentation/screens/admin_edit_event_screen.dart';
import '../features/admin/presentation/screens/admin_payment_verification_screen.dart';

class Routes {
  // Nama route untuk seluruh aplikasi
  static const String splash = '/';
  static const String gate = '/gate';
  static const String studentLogin = '/login/student'; // INI YANG BENAR
  static const String adminLogin = '/login/admin'; // INI YANG BENAR
  static const String mainWrapper = '/main';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String leaderboard = '/leaderboard';
  static const String eventRegistration = '/event-registration';
  static const String payment = '/payment';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminEventList = '/admin-event-list';
  static const String adminCreateEvent = '/admin-create-event';
  static const String adminEditEvent = '/admin-edit-event';
  static const String adminPaymentVerification = '/admin-payment-verification';

  // Generator route
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case gate:
        return MaterialPageRoute(builder: (_) => const GateScreen());

      case studentLogin:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());

      case mainWrapper:
        return MaterialPageRoute(builder: (_) => const MainWrapper());

      case leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case adminEventList:
        return MaterialPageRoute(builder: (_) => const AdminEventListScreen());

      case adminCreateEvent:
        return MaterialPageRoute(
          builder: (_) => const AdminCreateEventScreen(),
        );

      case adminEditEvent:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AdminEditEventScreen(eventId: args?['eventId'] ?? ''),
        );

      case adminPaymentVerification:
        return MaterialPageRoute(
          builder: (_) => const AdminPaymentVerificationScreen(),
        );

      case search:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: args?['query'] as String?),
        );

      // Tambahkan untuk halaman yang belum diimplementasi
      case notifications:
      case eventRegistration:
      case payment:
        return _buildPlaceholderRoute(
          title: settings.name?.replaceAll('/', '').replaceAll('-', ' ').toUpperCase() ?? 'Coming Soon',
          icon: _getIconForRoute(settings.name ?? ''),
        );

      default:
        return _buildErrorRoute('Route "${settings.name}" tidak ditemukan');
    }
  }

  // Helper untuk mendapatkan icon berdasarkan route
  static IconData _getIconForRoute(String routeName) {
    switch (routeName) {
      case notifications:
        return Icons.notifications;
      case eventRegistration:
        return Icons.event;
      case payment:
        return Icons.payment;
      default:
        return Icons.build;
    }
  }

  // Method untuk membuat placeholder route
  static MaterialPageRoute _buildPlaceholderRoute({
    required String title,
    required IconData icon,
  }) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                'Halaman $title',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('Akan segera diimplementasi'),
            ],
          ),
        ),
      ),
    );
  }

  // Method untuk membuat error route
  static MaterialPageRoute _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method untuk navigasi
  static Future<dynamic> pushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<dynamic> pushReplacementNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }
}