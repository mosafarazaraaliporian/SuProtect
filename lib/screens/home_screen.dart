import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'story_view_screen.dart';
import 'upload_apk_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? uploadFileName;
  final GlobalKey? fabKey;
  
  const HomeScreen({super.key, this.uploadFileName, this.fabKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSeenWelcomeStory = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;
  Timer? _uploadTimer;
  bool _hasSeenUploadGuide = false;
  bool _hasSeenTour = false;
  int _tourStep = 0;
  final GlobalKey _storiesKey = GlobalKey();
  final GlobalKey _welcomeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkWelcomeStory();
    _checkTour();
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
      // If upload file name is provided, start upload
      if (widget.uploadFileName != null && !_isUploading && _uploadingFileName == null) {
        _uploadingFileName = widget.uploadFileName;
        _startFakeUpload();
      }
      // Show upload guide if first time
      _checkUploadGuide();
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If upload file name changed and we're not currently uploading, start upload
    if (widget.uploadFileName != null && 
        widget.uploadFileName != oldWidget.uploadFileName &&
        !_isUploading && 
        _uploadingFileName == null) {
      _uploadingFileName = widget.uploadFileName;
      _startFakeUpload();
    }
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

  Future<void> _checkTour() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenTour = prefs.getBool('has_seen_home_tour') ?? false;
    // Don't show tour automatically - it will be shown after welcome story is seen
  }

  Future<void> _checkUploadGuide() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenUploadGuide = prefs.getBool('has_seen_upload_guide') ?? false;
    
    if (!_hasSeenUploadGuide && mounted) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && !_hasSeenUploadGuide && widget.fabKey?.currentContext != null) {
          _showUploadGuide();
        }
      });
    }
  }

  void _showUploadGuide() {
    if (widget.fabKey?.currentContext == null) return;
    
    final RenderBox? renderBox = widget.fabKey?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Stack(
        children: [
          Positioned(
            left: position.dx - 80.w,
            top: position.dy - 60.h,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C88FF),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Tap here to upload APK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Icon(
                    Icons.arrow_upward,
                    color: const Color(0xFF9C88FF),
                    size: 40.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        Navigator.of(context).pop();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_upload_guide', true);
      }
    });
  }

  void _showTour() {
    setState(() {
      _tourStep = 0;
    });
    _showTourStep();
  }

  void _showTourStep() {
    if (_tourStep >= 3) {
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) => p.setBool('has_seen_home_tour', true));
      return;
    }

    String title = '';
    String description = '';
    GlobalKey? targetKey;

    switch (_tourStep) {
      case 0:
        title = 'Stories';
        description = 'Check out our stories for updates, tips, and features!';
        targetKey = _storiesKey;
        break;
      case 1:
        title = 'Welcome';
        description = 'Welcome to SuProtect! Your app protection solution.';
        targetKey = _welcomeKey;
        break;
      case 2:
        title = 'Upload Button';
        description = 'Tap the + button to upload your APK file for protection.';
        targetKey = widget.fabKey;
        break;
    }

    if (targetKey?.currentContext == null) {
      setState(() {
        _tourStep++;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showTourStep();
      });
      return;
    }

    final RenderBox? renderBox = targetKey?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      setState(() {
        _tourStep++;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showTourStep();
      });
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Stack(
        children: [
          // Highlight area
          Positioned(
            left: position.dx - 8.w,
            top: position.dy - 8.h,
            child: Container(
              width: size.width + 16.w,
              height: size.height + 16.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF9C88FF),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C88FF).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          // Tooltip
          Positioned(
            left: 20.w,
            right: 20.w,
            top: position.dy + size.height + 20.h,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9C88FF),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_tourStep > 0)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() {
                                _tourStep--;
                              });
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) _showTourStep();
                              });
                            },
                            child: Text(
                              'Previous',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: List.generate(3, (index) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _tourStep
                                    ? const Color(0xFF9C88FF)
                                    : Colors.grey[300],
                              ),
                            );
                          }),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _tourStep++;
                            });
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                if (_tourStep < 3) {
                                  _showTourStep();
                                } else {
                                  final prefs = SharedPreferences.getInstance();
                                  prefs.then((p) => p.setBool('has_seen_home_tour', true));
                                }
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C88FF),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                          ),
                          child: Text(
                            _tourStep == 2 ? 'Finish' : 'Next',
                            style: TextStyle(fontSize: 12.sp, color: Colors.white),
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
      ),
    );
  }

  Future<void> _showWelcomeStory() async {
    final stories = _getStoriesList(0);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewScreen(
          stories: stories,
          initialIndex: 0,
        ),
      ),
    );
    
    // Mark as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome_story', true);
    setState(() {
      _hasSeenWelcomeStory = true;
    });
    
    // Show tour after story is viewed
    if (mounted) {
      final hasSeenTour = prefs.getBool('has_seen_home_tour') ?? false;
      if (!hasSeenTour) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showTour();
          }
        });
      }
    }
  }

  List<StoryData> _getStoriesList(int startIndex) {
    return [
      StoryData(
        title: 'Welcome to SuProtect!',
        message: 'Your comprehensive app protection solution. Keep your applications secure and safe from various threats.',
        icon: Icons.celebration,
        backgroundColor: const Color(0xFF9C88FF),
      ),
      StoryData(
        title: 'Features',
        message: 'Discover powerful features:\n\n• Security Protection\n• Threat Detection\n• Data Encryption\n• Real-time Monitoring',
        icon: Icons.star,
        backgroundColor: Colors.orange,
      ),
      StoryData(
        title: 'Tips',
        message: 'Best Practices:\n\n• Keep your app updated\n• Use strong passwords\n• Enable all security features\n• Regular security checks',
        icon: Icons.lightbulb,
        backgroundColor: Colors.amber,
      ),
      StoryData(
        title: 'Join Our Telegram',
        message: 'Stay updated with the latest news, updates, and tips!\n\nJoin our Telegram channel for exclusive content and support.',
        icon: Icons.telegram,
        backgroundColor: const Color(0xFF0088cc),
        actionLabel: 'Join Channel',
        actionIcon: Icons.telegram,
        onActionTap: () async {
          Navigator.pop(context); // Close story first
          final url = Uri.parse('https://t.me/your_channel'); // Replace with your Telegram channel
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not open Telegram', style: TextStyle(fontSize: 12.sp)),
                ),
              );
            }
          }
        },
      ),
    ];
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Stories section - at the top
                Container(
                  key: _storiesKey,
                  child: _buildStoriesSection(),
                ),
                
                // Upload progress card - below stories
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
                
                // Welcome section - centered
                Container(
                  key: _welcomeKey,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
          _buildStoryItem(
            title: 'Features',
            icon: Icons.star,
            color: Colors.orange,
            onTap: () {
              final stories = _getStoriesList(1);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryViewScreen(
                    stories: stories,
                    initialIndex: 1,
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
              final stories = _getStoriesList(2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryViewScreen(
                    stories: stories,
                    initialIndex: 2,
                  ),
                ),
              );
            },
          ),
          _buildStoryItem(
            title: 'Telegram',
            icon: Icons.telegram,
            color: const Color(0xFF0088cc),
            onTap: () {
              final stories = _getStoriesList(3);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryViewScreen(
                    stories: stories,
                    initialIndex: 3,
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
