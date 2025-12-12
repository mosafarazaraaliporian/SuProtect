import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'story_view_screen.dart';
import 'upload_apk_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSeenWelcomeStory = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;
  Timer? _uploadTimer;

  @override
  void initState() {
    super.initState();
    _checkWelcomeStory();
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    // Log screen view to Firebase Analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseService().logEvent('screen_view', {
        'screen_name': 'home',
        'screen_class': 'HomeScreen',
      });
    });
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkWelcomeStory() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenWelcomeStory = prefs.getBool('has_seen_welcome_story') ?? false;
    
    if (!_hasSeenWelcomeStory && mounted) {
      // Show welcome story after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showWelcomeStory();
        }
      });
    }
  }

  Future<void> _showWelcomeStory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryViewScreen(
          title: 'Welcome to SuProtect!',
          message: 'Your comprehensive app protection solution. Keep your applications secure and safe from various threats.',
          icon: Icons.celebration,
        ),
      ),
    );
    
    // Mark as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome_story', true);
    setState(() {
      _hasSeenWelcomeStory = true;
    });
  }


  void _startFakeUpload() {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Initialize notification service
    NotificationService().initialize();

    // Start fake upload progress
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          _uploadProgress += 0.02;
          if (_uploadProgress >= 1.0) {
            _uploadProgress = 1.0;
            timer.cancel();
            _completeUpload();
          }
        });

        // Update notification
        NotificationService().showUploadProgressNotification(
          progress: (_uploadProgress * 100).toInt(),
          fileName: _uploadingFileName ?? 'app.apk',
        );
      } else {
        timer.cancel();
      }
    });
  }

  void _completeUpload() {
    setState(() {
      _isUploading = false;
    });

    // Show completion notification
    NotificationService().showUploadCompleteNotification(
      _uploadingFileName ?? 'app.apk',
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload completed successfully!', style: TextStyle(fontSize: 12.sp)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Reset after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _uploadProgress = 0.0;
          _uploadingFileName = null;
        });
      }
    });
  }

  void _cancelUpload() {
    _uploadTimer?.cancel();
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
      _uploadingFileName = null;
    });

    // Cancel notification
    NotificationService().cancelNotification();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload cancelled', style: TextStyle(fontSize: 12.sp)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Home',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload progress card
                if (_isUploading || _uploadProgress > 0) ...[
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_upload,
                                  size: 24.sp,
                                  color: const Color(0xFF9C88FF),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Uploading APK',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _uploadingFileName ?? 'app.apk',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 20.sp),
                                  onPressed: _cancelUpload,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 6.h,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF9C88FF),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF9C88FF),
                                  ),
                                ),
                                if (_isUploading)
                                  Text(
                                    'Uploading...',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Stories section
                _buildStoriesSection(),
                
                SizedBox(height: 16.h),
                
                // Main content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home,
                        size: 50.sp,
                        color: const Color(0xFF9C88FF),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Welcome to SuProtect',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Your app protection solution',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 0),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            children: [
                              Icon(
                                Icons.security,
                                size: 32.sp,
                                color: const Color(0xFF9C88FF),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Protection Status',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildStoriesSection() {
    return Container(
      height: 90.h,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: [
          // Welcome story
          _buildStoryItem(
            title: 'Welcome',
            icon: Icons.celebration,
            color: const Color(0xFF9C88FF),
            onTap: _showWelcomeStory,
            isNew: !_hasSeenWelcomeStory,
          ),
          // Add more stories here in the future
          _buildStoryItem(
            title: 'Features',
            icon: Icons.star,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoryViewScreen(
                    title: 'Features',
                    message: 'Discover powerful features:\n\n• Security Protection\n• Threat Detection\n• Data Encryption\n• Real-time Monitoring',
                    icon: Icons.star,
                    backgroundColor: Colors.orange,
                  ),
                ),
              );
            },
          ),
          _buildStoryItem(
            title: 'Tips',
            icon: Icons.lightbulb,
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoryViewScreen(
                    title: 'Tips',
                    message: 'Best Practices:\n\n• Keep your app updated\n• Use strong passwords\n• Enable all security features\n• Regular security checks',
                    icon: Icons.lightbulb,
                    backgroundColor: Colors.amber,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isNew = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        margin: EdgeInsets.only(right: 10.w),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getLighterColor(color),
                        _getDarkerColor(color),
                      ],
                    ),
                    border: Border.all(
                      color: isNew ? Colors.red : Colors.grey.shade300,
                      width: isNew ? 2.5 : 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fiber_new,
                        color: Colors.white,
                        size: 10.sp,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getLighterColor(Color color) {
    return Color.fromRGBO(
      (color.red + 50).clamp(0, 255),
      (color.green + 50).clamp(0, 255),
      (color.blue + 50).clamp(0, 255),
      color.opacity,
    );
  }

  Color _getDarkerColor(Color color) {
    return Color.fromRGBO(
      (color.red - 50).clamp(0, 255),
      (color.green - 50).clamp(0, 255),
      (color.blue - 50).clamp(0, 255),
      color.opacity,
    );
  }
}
