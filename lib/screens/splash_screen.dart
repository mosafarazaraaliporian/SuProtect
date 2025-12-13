import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/logger_service.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lineController;
  late AnimationController _fadeController;
  late Animation<double> _topLineAnimation;
  late Animation<double> _bottomLineAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    LoggerService.logMethod('SplashScreen', 'initState');

    // Set system UI overlay style to match app color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF9C88FF),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF9C88FF),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Line animation controller for S lines
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade and scale animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Top line animation (from top to S)
    _topLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _lineController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Bottom line animation (from bottom to S)
    _bottomLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _lineController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Fade and scale animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _lineController.forward();
    LoggerService.d('SplashScreen', 'Line animation started');
    
    // Start fade animation after line animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _fadeController.forward();
        LoggerService.d('SplashScreen', 'Fade animation started');
      }
    });

    // Navigate after delay
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    LoggerService.logMethod('SplashScreen', '_navigateToNext');
    
    // Wait for animation and check auth
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) {
      LoggerService.w('SplashScreen', 'Widget not mounted, skipping navigation');
      return;
    }

    LoggerService.d('SplashScreen', 'Checking auth status');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) {
      LoggerService.w('SplashScreen', 'Widget not mounted after auth check');
      return;
    }

    if (authProvider.isLoggedIn) {
      LoggerService.logNavigation('SplashScreen', 'MainNavigation');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    } else {
      LoggerService.logNavigation('SplashScreen', 'LoginScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    LoggerService.logMethod('SplashScreen', 'dispose');
    _lineController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF9C88FF),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF9C88FF),
                  const Color(0xFF9C88FF).withOpacity(0.8),
                  const Color(0xFF7B68EE),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated S with lines
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Text "SuProtect"
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            'SuProtect',
                            style: TextStyle(
                              fontSize: 48.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Animated lines for S
                      AnimatedBuilder(
                        animation: _lineController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(300.w, 200.h),
                            painter: SLinesPainter(
                              topLineProgress: _topLineAnimation.value,
                              bottomLineProgress: _bottomLineAnimation.value,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Underline
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 100.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for S lines (top and bottom)
class SLinesPainter extends CustomPainter {
  final double topLineProgress;
  final double bottomLineProgress;

  SLinesPainter({
    required this.topLineProgress,
    required this.bottomLineProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Calculate S position (first letter of "SuProtect")
    // S is approximately at the start of the text
    final sCenterX = centerX - 80; // Approximate position of S
    final sTopY = centerY - 20; // Top of S
    final sBottomY = centerY + 20; // Bottom of S
    final lineLength = 60.0;

    // Top line - from top of screen to top of S
    if (topLineProgress > 0) {
      final startY = 0.0;
      final endY = sTopY;
      final currentEndY = startY + (endY - startY) * topLineProgress;
      
      canvas.drawLine(
        Offset(sCenterX, startY),
        Offset(sCenterX, currentEndY),
        paint,
      );
    }

    // Bottom line - from bottom of screen to bottom of S
    if (bottomLineProgress > 0) {
      final startY = size.height;
      final endY = sBottomY;
      final currentEndY = startY - (startY - endY) * bottomLineProgress;
      
      canvas.drawLine(
        Offset(sCenterX, startY),
        Offset(sCenterX, currentEndY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SLinesPainter oldDelegate) {
    return oldDelegate.topLineProgress != topLineProgress ||
        oldDelegate.bottomLineProgress != bottomLineProgress;
  }
}
