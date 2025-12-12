import 'package:flutter/material.dart';
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
            onTapDown: (_) => setState(() => _isPaused = true),
            onTapUp: (_) => setState(() => _isPaused = false),
            onTapCancel: () => setState(() => _isPaused = false),
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
                // Content
                Center(
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
                          SizedBox(height: 40.h),
                          ElevatedButton.icon(
                            onPressed: story.onActionTap,
                            icon: Icon(
                              story.actionIcon ?? Icons.telegram,
                              size: 24.sp,
                            ),
                            label: Text(
                              story.actionLabel ?? 'Join Telegram',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: story.backgroundColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Navigation areas
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _previousStory,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _nextStory,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
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
