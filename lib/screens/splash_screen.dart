import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
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
  late AnimationController _sDrawController;
  late AnimationController _glowController;
  late AnimationController _textController;
  late AnimationController _particleController;
  
  late Animation<double> _sDrawAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    LoggerService.logMethod('SplashScreen', 'initState');

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF9C88FF),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF9C88FF),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _sDrawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _sDrawAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _sDrawController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _sDrawController.forward();
    LoggerService.d('SplashScreen', 'S drawing animation started');
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _textController.forward();
        LoggerService.d('SplashScreen', 'Text animation started');
      }
    });

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    LoggerService.logMethod('SplashScreen', '_navigateToNext');
    
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) {
      LoggerService.w('SplashScreen', 'Widget not mounted, skipping navigation');
      return;
    }

    LoggerService.d('SplashScreen', 'Checking auth status');
    
    try {
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
    } catch (e) {
      LoggerService.e('SplashScreen', 'Navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    LoggerService.logMethod('SplashScreen', 'dispose');
    _sDrawController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _particleController.dispose();
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
                  const Color(0xFF8B7AEE),
                  const Color(0xFF7B68EE),
                  const Color(0xFF6A5ACD),
                ],
              ),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: ParticlesPainter(
                        progress: _particleController.value,
                      ),
                    );
                  },
                ),
                
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 200.w,
                                height: 200.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(
                                        0.1 * _glowAnimation.value,
                                      ),
                                      blurRadius: 80 * _glowAnimation.value,
                                      spreadRadius: 20 * _glowAnimation.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          AnimatedBuilder(
                            animation: _sDrawAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(150.w, 180.h),
                                painter: AnimatedSPainter(
                                  progress: _sDrawAnimation.value,
                                  glowIntensity: _glowAnimation.value,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textFadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _textSlideAnimation.value),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 40.w),
                                  Text(
                                    'uProtect',
                                    style: TextStyle(
                                      fontSize: 42.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: Offset(0, 4.h),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 30.h),
                      
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textFadeAnimation.value,
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedSPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;

  AnimatedSPainter({
    required this.progress,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * glowIntensity)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    
    final centerX = size.width / 2;
    final topY = size.height * 0.2;
    final middleY = size.height * 0.5;
    final bottomY = size.height * 0.8;
    final curveOffset = size.width * 0.25;

    path.moveTo(centerX + curveOffset, topY);
    path.cubicTo(
      centerX + curveOffset, topY,
      centerX - curveOffset, topY + (middleY - topY) * 0.3,
      centerX - curveOffset, middleY - (middleY - topY) * 0.2,
    );
    path.cubicTo(
      centerX - curveOffset, middleY,
      centerX + curveOffset * 0.8, middleY,
      centerX + curveOffset * 0.8, middleY,
    );
    path.cubicTo(
      centerX + curveOffset * 0.8, middleY,
      centerX - curveOffset, middleY + (bottomY - middleY) * 0.3,
      centerX - curveOffset, bottomY,
    );

    final totalLength = _calculatePathLength(path);
    final drawLength = totalLength * progress;

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0, drawLength);

    canvas.drawPath(extractPath, glowPaint);
    canvas.drawPath(extractPath, paint);

    if (progress > 0.9) {
      final double sparkleProgress = (progress - 0.9) / 0.1;
      _drawSparkles(canvas, size, sparkleProgress);
    }
  }

  double _calculatePathLength(Path path) {
    final pathMetrics = path.computeMetrics().first;
    return pathMetrics.length;
  }

  void _drawSparkles(Canvas canvas, Size size, double progress) {
    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(progress * 0.8)
      ..style = PaintingStyle.fill;

    final sparkles = [
      Offset(size.width * 0.7, size.height * 0.25),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.75),
    ];

    for (var sparkle in sparkles) {
      canvas.drawCircle(sparkle, 3 * progress, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(AnimatedSPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

class ParticlesPainter extends CustomPainter {
  final double progress;

  ParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + (progress * 100)) % size.height;
      final radius = random.nextDouble() * 2 + 1;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}