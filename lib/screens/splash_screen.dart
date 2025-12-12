import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
  late Animation<double> _line1Animation;
  late Animation<double> _line2Animation;
  late Animation<double> _line3Animation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style to match app color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF9C88FF),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF9C88FF),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Line animation controller
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade and scale animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Line animations (drawing effect)
    _line1Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _lineController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );

    _line2Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _lineController,
        curve: const Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );

    _line3Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _lineController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
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
    
    // Start fade animation after line animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    // Navigate after delay
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for animation and check auth
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    } else {
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
                  // Animated lines (Zoro style)
                  AnimatedBuilder(
                    animation: _lineController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(200.w, 200.h),
                        painter: ZoroLinesPainter(
                          line1Progress: _line1Animation.value,
                          line2Progress: _line2Animation.value,
                          line3Progress: _line3Animation.value,
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Logo text with fade and scale
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          Text(
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
                          SizedBox(height: 12.h),
                          Container(
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

// Custom painter for Zoro-style lines
class ZoroLinesPainter extends CustomPainter {
  final double line1Progress;
  final double line2Progress;
  final double line3Progress;

  ZoroLinesPainter({
    required this.line1Progress,
    required this.line2Progress,
    required this.line3Progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final lineLength = size.width * 0.4;

    // Line 1 - Top left to center
    if (line1Progress > 0) {
      final startX = centerX - lineLength;
      final startY = centerY - lineLength * 0.6;
      final endX = centerX;
      final endY = centerY;
      
      final currentEndX = startX + (endX - startX) * line1Progress;
      final currentEndY = startY + (endY - startY) * line1Progress;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(currentEndX, currentEndY),
        paint,
      );
    }

    // Line 2 - Center to bottom right
    if (line2Progress > 0) {
      final startX = centerX;
      final startY = centerY;
      final endX = centerX + lineLength;
      final endY = centerY + lineLength * 0.6;
      
      final currentEndX = startX + (endX - startX) * line2Progress;
      final currentEndY = startY + (endY - startY) * line2Progress;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(currentEndX, currentEndY),
        paint,
      );
    }

    // Line 3 - Bottom left to top right (diagonal)
    if (line3Progress > 0) {
      final startX = centerX - lineLength * 0.7;
      final startY = centerY + lineLength * 0.5;
      final endX = centerX + lineLength * 0.7;
      final endY = centerY - lineLength * 0.5;
      
      final currentEndX = startX + (endX - startX) * line3Progress;
      final currentEndY = startY + (endY - startY) * line3Progress;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(currentEndX, currentEndY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ZoroLinesPainter oldDelegate) {
    return oldDelegate.line1Progress != line1Progress ||
        oldDelegate.line2Progress != line2Progress ||
        oldDelegate.line3Progress != line3Progress;
  }
}
