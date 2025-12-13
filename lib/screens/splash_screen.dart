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
  late AnimationController _sController;
  late AnimationController _uController;
  late AnimationController _protectController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _waveController;
  
  late Animation<double> _sDrawAnimation;
  late Animation<double> _sScaleAnimation;
  late Animation<double> _uFadeAnimation;
  late Animation<double> _uSlideAnimation;
  late Animation<double> _protectRevealAnimation;
  late Animation<double> _protectGlowAnimation;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    LoggerService.logMethod('SplashScreen', 'initState');

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1a0033),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1a0033),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _sController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _uController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _protectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _sDrawAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sController, curve: Curves.easeInOut),
    );

    _sScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sController, curve: Curves.elasticOut),
    );

    _uFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _uController, curve: Curves.easeIn),
    );

    _uSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _uController, curve: Curves.easeOut),
    );

    _protectRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _protectController, curve: Curves.easeOutCubic),
    );

    _protectGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _protectController, curve: Curves.easeIn),
    );

    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startAnimations();
    _navigateToNext();
  }

  void _startAnimations() {
    _sController.forward().then((_) {
      if (mounted) {
        _uController.forward().then((_) {
          if (mounted) {
            _protectController.forward();
          }
        });
      }
    });
  }

  Future<void> _navigateToNext() async {
    LoggerService.logMethod('SplashScreen', '_navigateToNext');
    
    await Future.delayed(const Duration(milliseconds: 4000));

    if (!mounted) {
      LoggerService.w('SplashScreen', 'Widget not mounted, skipping navigation');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();

      if (!mounted) return;

      if (authProvider.isLoggedIn) {
        LoggerService.logNavigation('SplashScreen', 'MainNavigation');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        LoggerService.logNavigation('SplashScreen', 'LoginScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      LoggerService.e('SplashScreen', 'Navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    LoggerService.logMethod('SplashScreen', 'dispose');
    _sController.dispose();
    _uController.dispose();
    _protectController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _waveController.dispose();
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a0033),
                  const Color(0xFF2d1b4e),
                  const Color(0xFF4a2c6f),
                  const Color(0xFF6a3d91),
                  const Color(0xFF9C88FF),
                ],
              ),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: WaveBackgroundPainter(
                        progress: _waveController.value,
                      ),
                    );
                  },
                ),
                
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: EnhancedParticlesPainter(
                        progress: _particleController.value,
                      ),
                    );
                  },
                ),
                
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _glowPulse,
                                builder: (context, child) {
                                  return Container(
                                    width: 120.w * _glowPulse.value,
                                    height: 120.h * _glowPulse.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF9C88FF).withOpacity(0.3),
                                          blurRadius: 60 * _glowPulse.value,
                                          spreadRadius: 20 * _glowPulse.value,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              AnimatedBuilder(
                                animation: Listenable.merge([_sDrawAnimation, _sScaleAnimation]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _sScaleAnimation.value,
                                    child: CustomPaint(
                                      size: Size(80.w, 100.h),
                                      painter: AnimatedSPainter(
                                        progress: _sDrawAnimation.value,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          SizedBox(width: 8.w),
                          
                          AnimatedBuilder(
                            animation: Listenable.merge([_uFadeAnimation, _uSlideAnimation]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_uSlideAnimation.value, 0),
                                child: Opacity(
                                  opacity: _uFadeAnimation.value,
                                  child: Stack(
                                    children: [
                                      Text(
                                        'u',
                                        style: TextStyle(
                                          fontSize: 72.sp,
                                          fontWeight: FontWeight.bold,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 3
                                            ..color = Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            const Color(0xFFFFFFFF),
                                            const Color(0xFF9C88FF),
                                          ],
                                        ).createShader(bounds),
                                        child: Text(
                                          'u',
                                          style: TextStyle(
                                            fontSize: 72.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 30.h),
                      
                      AnimatedBuilder(
                        animation: Listenable.merge([_protectRevealAnimation, _protectGlowAnimation]),
                        builder: (context, child) {
                          return ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: _protectRevealAnimation.value,
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    painter: ProtectGlowPainter(
                                      intensity: _protectGlowAnimation.value,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                      child: ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            const Color(0xFFFFD700),
                                            const Color(0xFFFFFFFF),
                                            const Color(0xFF9C88FF),
                                            const Color(0xFFFFD700),
                                          ],
                                          stops: const [0.0, 0.3, 0.7, 1.0],
                                        ).createShader(bounds),
                                        child: Text(
                                          'PROTECT',
                                          style: TextStyle(
                                            fontSize: 36.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 8,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: const Color(0xFF9C88FF).withOpacity(0.8),
                                                blurRadius: 20,
                                              ),
                                              Shadow(
                                                color: Colors.white.withOpacity(0.5),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  if (_protectGlowAnimation.value > 0.8)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: SparklesPainter(
                                          progress: (_protectGlowAnimation.value - 0.8) / 0.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      AnimatedBuilder(
                        animation: _protectRevealAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _protectRevealAnimation.value,
                            child: Container(
                              width: 120.w * _protectRevealAnimation.value,
                              height: 4.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFFFFD700),
                                    Colors.white,
                                    const Color(0xFFFFD700),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.6),
                                    blurRadius: 12,
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

  AnimatedSPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final gradient = LinearGradient(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFFFFFF),
        const Color(0xFF9C88FF),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = gradient;
    glowPaint.color = const Color(0xFF9C88FF).withOpacity(0.6);

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    path.moveTo(w * 0.75, h * 0.15);
    path.cubicTo(w * 0.75, h * 0.15, w * 0.15, h * 0.25, w * 0.15, h * 0.45);
    path.cubicTo(w * 0.15, h * 0.5, w * 0.85, h * 0.5, w * 0.85, h * 0.5);
    path.cubicTo(w * 0.85, h * 0.55, w * 0.25, h * 0.7, w * 0.25, h * 0.85);

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0, pathMetrics.length * progress);

    canvas.drawPath(extractPath, glowPaint);
    canvas.drawPath(extractPath, paint);

    if (progress > 0.95) {
      final sparkle = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.75, h * 0.15), 4, sparkle);
      canvas.drawCircle(Offset(w * 0.25, h * 0.85), 4, sparkle);
    }
  }

  @override
  bool shouldRepaint(AnimatedSPainter oldDelegate) => oldDelegate.progress != progress;
}

class ProtectGlowPainter extends CustomPainter {
  final double intensity;

  ProtectGlowPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity > 0) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0xFFFFD700).withOpacity(0.3 * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * intensity);

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(ProtectGlowPainter oldDelegate) => oldDelegate.intensity != intensity;
}

class SparklesPainter extends CustomPainter {
  final double progress;

  SparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(progress)
      ..style = PaintingStyle.fill;

    final sparkles = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.8),
    ];

    for (var pos in sparkles) {
      canvas.drawCircle(pos, 2 * progress, paint);
      
      canvas.drawLine(
        Offset(pos.dx - 6 * progress, pos.dy),
        Offset(pos.dx + 6 * progress, pos.dy),
        paint..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(pos.dx, pos.dy - 6 * progress),
        Offset(pos.dx, pos.dy + 6 * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SparklesPainter oldDelegate) => oldDelegate.progress != progress;
}

class WaveBackgroundPainter extends CustomPainter {
  final double progress;

  WaveBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = (progress + i * 0.3) % 1.0;
      final y = size.height * 0.5 + math.sin(offset * 2 * math.pi) * 50;
      
      paint.color = Color(0xFF9C88FF).withOpacity(0.05 - i * 0.01);
      
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 10) {
        final waveY = y + math.sin((x / size.width + offset) * 4 * math.pi) * 30;
        path.lineTo(x, waveY);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WaveBackgroundPainter oldDelegate) => oldDelegate.progress != progress;
}

class EnhancedParticlesPainter extends CustomPainter {
  final double progress;

  EnhancedParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = math.Random(42);
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final speed = random.nextDouble() * 0.5 + 0.5;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + (progress * 200 * speed)) % size.height;
      final radius = random.nextDouble() * 2.5 + 0.5;
      final opacity = random.nextDouble() * 0.3 + 0.1;
      
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(EnhancedParticlesPainter oldDelegate) => oldDelegate.progress != progress;
}