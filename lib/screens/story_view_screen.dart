import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoryData {
  final String title;
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final IconData? actionIcon;

  StoryData({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    this.onActionTap,
    this.actionLabel,
    this.actionIcon,
  });
}

class StoryViewScreen extends StatefulWidget {
  final List<StoryData> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late int _currentIndex;
  double _progress = 0.0;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _startProgress();
  }

  void _startProgress() {
    _timer?.cancel();
    _progress = 0.0;
    _isPaused = false;
    
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1.0) {
            _progress = 1.0;
            timer.cancel();
            _nextStory();
          }
        });
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _progress = 0.0;
      });
      _startProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progress = 0.0;
      });
      _startProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _handleActionTap() {
    debugPrint('[StoryView] Action button tapped!');
    final story = widget.stories[_currentIndex];
    if (story.onActionTap != null) {
      debugPrint('[StoryView] Executing action...');
      // Pause story progress
      setState(() {
        _isPaused = true;
      });
      // Execute action
      story.onActionTap!();
      debugPrint('[StoryView] Action executed');
      // Resume after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isPaused = false;
          });
        }
      });
    } else {
      debugPrint('[StoryView] No action to execute');
    }
  }

  Color _getLighterColor(Color color) {
    return Color.fromRGBO(
      (color.red + 80).clamp(0, 255),
      (color.green + 80).clamp(0, 255),
      (color.blue + 80).clamp(0, 255),
      color.opacity,
    );
  }

  Color _getDarkerColor(Color color) {
    return Color.fromRGBO(
      (color.red - 80).clamp(0, 255),
      (color.green - 80).clamp(0, 255),
      (color.blue - 80).clamp(0, 255),
      color.opacity,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            // Tap on right side to go to next story, left side to go to previous
            onTapDown: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapX = details.globalPosition.dx;
              
              // Right side (more than 60% of screen) - next story
              if (tapX > screenWidth * 0.6) {
                _nextStory();
              }
              // Left side (less than 40% of screen) - previous story
              else if (tapX < screenWidth * 0.4) {
                _previousStory();
              }
              // Center - pause/resume
              else {
                setState(() => _isPaused = true);
              }
            },
            onTapUp: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapX = details.globalPosition.dx;
              
              // Only resume if tapped in center
              if (tapX >= screenWidth * 0.4 && tapX <= screenWidth * 0.6) {
                setState(() => _isPaused = false);
              }
            },
            onTapCancel: () {
              setState(() => _isPaused = false);
            },
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getLighterColor(story.backgroundColor),
                        story.backgroundColor,
                        _getDarkerColor(story.backgroundColor),
                      ],
                    ),
                  ),
                ),
                // Progress bars at top
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Row(
                      children: List.generate(widget.stories.length, (index) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 2.w),
                            height: 3.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Stack(
                              children: [
                                if (index < _currentIndex)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  )
                                else if (index == _currentIndex)
                                  FractionallySizedBox(
                                    widthFactor: _progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // Content area
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            story.icon,
                            size: 70.sp,
                            color: story.backgroundColor,
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          story.title,
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 5.h),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          story.message,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Telegram button - Fixed at bottom, always visible
                if (story.onActionTap != null)
                  Positioned(
                    bottom: 40.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _handleActionTap,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 24.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: Offset(0, 8.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                story.actionIcon ?? Icons.telegram,
                                size: 28.sp,
                                color: story.backgroundColor,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                story.actionLabel ?? 'Join Telegram',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: story.backgroundColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Close button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28.sp,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
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
