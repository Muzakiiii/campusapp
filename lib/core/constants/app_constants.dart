class AppConstants {
  static const String appName = 'CampusApp';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aplikasi untuk kebutuhan kampus';
  
  // Durasi
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Warna
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFF1976D2;
  static const int accentColor = 0xFFFFC107;
  static const int backgroundColor = 0xFFF5F5F5;
  
  // Assets
  static const String fontFamily = 'Poppins';
  
  // Routes
  static const String splashRoute = '/';
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String gateRoute = '/gate';
  static const String studentLogin = '/login/student';
  static const String adminLogin = '/login/admin';
  
  // Keys
  static const String splashKey = 'splash_screen';
  static const String homeKey = 'home_screen';
}

class AssetConstants {
  static const String logoPath = 'assets/images/logo.png';
  static const String backgroundPath = 'assets/images/background.png';
  static const String iconPath = 'assets/icons/';
  
  // Fonts
  static const String poppinsRegular = 'Poppins-Regular';
  static const String poppinsMedium = 'Poppins-Medium';
  static const String poppinsBold = 'Poppins-Bold';
}