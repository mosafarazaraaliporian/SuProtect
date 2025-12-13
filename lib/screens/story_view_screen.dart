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
    debugPrint('[_handleActionTap] Called');
    final story = widget.stories[_currentIndex];
    debugPrint('[_handleActionTap] Story has action: ${story.onActionTap != null}');
    if (story.onActionTap != null) {
      debugPrint('[_handleActionTap] Executing action...');
      // Pause story progress
      setState(() {
        _isPaused = true;
      });
      // Execute action
      story.onActionTap!();
      debugPrint('[_handleActionTap] Action executed');
      // Resume after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isPaused = false;
          });
        }
      });
    } else {
      debugPrint('[_handleActionTap] No action to execute');
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
          body: Stack(
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
              // Content area - wrapped in IgnorePointer to prevent navigation interference
              IgnorePointer(
                ignoring: false, // Content should receive taps
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
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
                        if (story.onActionTap != null) ...[
                          SizedBox(height: 50.h),
                          // Action button - Material with InkWell for proper tap handling
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                debugPrint('[StoryView] Telegram button tapped!');
                                _handleActionTap();
                              },
                              borderRadius: BorderRadius.circular(30.r),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 20.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32.w,
                                  vertical: 18.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                      offset: Offset(0, 10.h),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      story.actionIcon ?? Icons.telegram,
                                      size: 30.sp,
                                      color: story.backgroundColor,
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      story.actionLabel ?? 'Join Telegram',
                                      style: TextStyle(
                                        fontSize: 20.sp,
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
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Navigation - ONLY on left and right edges (20% each), center 60% is blocked
              Positioned.fill(
                child: Row(
                  children: [
                    // Left 20% - Previous story
                    GestureDetector(
                      onTap: _previousStory,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        color: Colors.transparent,
                      ),
                    ),
                    // Center 60% - BLOCKED (content area) - use IgnorePointer to block navigation
                    Expanded(
                      child: IgnorePointer(
                        ignoring: true, // Block all navigation in center
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    // Right 20% - Next story
                    GestureDetector(
                      onTap: _nextStory,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        color: Colors.transparent,
                      ),
                    ),
                  ],
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
        );
      },
    );
  }
}
