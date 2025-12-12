import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
  bool _hasSeenTour = false;
  int _tourStep = 0;
  bool _isProcessing = false; // For fake processing after upload
  final GlobalKey _storiesKey = GlobalKey();
  final GlobalKey _welcomeKey = GlobalKey();
  BuildContext? _tourDialogContext;

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
    _closeTourDialog();
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
    // Don't show tour automatically - it will be shown after welcome story is seen (only once)
  }

  void _showTour() {
    // Close any existing dialog first
    if (_tourDialogContext != null) {
      Navigator.of(_tourDialogContext!).pop();
      _tourDialogContext = null;
    }
    
    setState(() {
      _tourStep = 0;
    });
    
    // Wait a bit for the UI to be ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showTourStep();
      }
    });
  }

  void _closeTourDialog() {
    if (_tourDialogContext != null) {
      Navigator.of(_tourDialogContext!).pop();
      _tourDialogContext = null;
    }
  }

  void _showTourStep() async {
    if (!mounted) return;
    
    // Close previous dialog if exists
    _closeTourDialog();
    
    if (_tourStep >= 3) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_home_tour', true);
      if (mounted) {
        setState(() {
          _hasSeenTour = true;
        });
      }
      return;
    }

    String title = '';
    String description = '';
    GlobalKey? targetKey;

    switch (_tourStep) {
      case 0:
        title = 'Stories';
        description = 'These are important news and notifications';
        targetKey = _storiesKey;
        break;
      case 1:
        title = 'Your Apps';
        description = 'This shows your apps here';
        targetKey = _welcomeKey;
        break;
      case 2:
        title = 'Upload Button';
        description = 'Tap the + button to upload your APK file for protection.';
        targetKey = widget.fabKey;
        break;
    }

    // Wait a bit more if targetKey is not ready
    if (targetKey?.currentContext == null || !mounted) {
      // Try a few times before giving up
      int attempts = 0;
      while (attempts < 5 && mounted && (targetKey?.currentContext == null)) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
      
      if (targetKey?.currentContext == null || !mounted) {
        // Skip this step if still not found
        if (mounted) {
          setState(() {
            _tourStep++;
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _showTourStep();
          });
        }
        return;
      }
    }

    try {
      final RenderBox? renderBox = targetKey?.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize || !mounted) {
        // Skip this step
        if (mounted) {
          setState(() {
            _tourStep++;
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _showTourStep();
          });
        }
        return;
      }

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (dialogContext) {
          if (!mounted) return const SizedBox();
          _tourDialogContext = dialogContext;
          
          final screenSize = MediaQuery.of(dialogContext).size;
          final screenHeight = screenSize.height;
          final screenWidth = screenSize.width;
          
          // Calculate tooltip position
          double tooltipTop;
          
          if (_tourStep == 2) {
            // For FAB, show tooltip above
            tooltipTop = position.dy - 200;
            // Ensure it doesn't go above screen
            if (tooltipTop < 20) {
              tooltipTop = 20;
            }
          } else {
            // For stories and welcome, show tooltip below
            tooltipTop = position.dy + size.height + 20;
            // Ensure it doesn't go below screen (considering tooltip height ~250)
            if (tooltipTop + 250 > screenHeight) {
              tooltipTop = position.dy - 250; // Show above instead
              // If still doesn't fit, center it
              if (tooltipTop < 20) {
                tooltipTop = (screenHeight - 300) / 2;
              }
            }
          }

          // Clamp positions to valid ranges
          final clampedLeft = (position.dx - 8).clamp(0.0, screenWidth - size.width - 16);
          final clampedTop = (position.dy - 8).clamp(0.0, screenHeight - size.height - 16);
          final clampedTooltipTop = tooltipTop.clamp(20.0, screenHeight - 300.0);

          return Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Dark overlay
                Container(
                  color: Colors.black.withOpacity(0.7),
                ),
                // Highlight area
                Positioned(
                  left: clampedLeft,
                  top: clampedTop,
                  child: Container(
                    width: (size.width + 16).clamp(0.0, screenWidth - clampedLeft),
                    height: (size.height + 16).clamp(0.0, screenHeight - clampedTop),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF9C88FF),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                  left: 20,
                  right: 20,
                  top: clampedTooltipTop,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9C88FF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          // Show fake APK cards for step 1 (Welcome)
                          if (_tourStep == 1) ...[
                            const SizedBox(height: 16),
                            _buildFakeApkCards(),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_tourStep > 0)
                                TextButton(
                                  onPressed: () {
                                    _closeTourDialog();
                                    if (mounted) {
                                      setState(() {
                                        _tourStep--;
                                      });
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        if (mounted) _showTourStep();
                                      });
                                    }
                                  },
                                  child: const Text(
                                    'Previous',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                )
                              else
                                const SizedBox(),
                              Row(
                                children: List.generate(3, (index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 8,
                                    height: 8,
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
                                onPressed: () async {
                                  _closeTourDialog();
                                  if (!mounted) return;
                                  
                                  setState(() {
                                    _tourStep++;
                                  });
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  if (mounted) {
                                    if (_tourStep < 3) {
                                      _showTourStep();
                                    } else {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('has_seen_home_tour', true);
                                      if (mounted) {
                                        setState(() {
                                          _hasSeenTour = true;
                                        });
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9C88FF),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  _tourStep == 2 ? 'Finish' : 'Next',
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
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
        },
      );
    } catch (e) {
      // Handle error gracefully
      debugPrint('Tour guide error: $e');
      _closeTourDialog();
      if (mounted) {
        // If error occurs, mark tour as seen to prevent infinite loop
        if (_tourStep >= 2) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_seen_home_tour', true);
          setState(() {
            _hasSeenTour = true;
          });
        } else {
          setState(() {
            _tourStep++;
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _tourStep < 3) {
              _showTourStep();
            }
          });
        }
      }
    }
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
    
    // Show tour after story is viewed ONLY if not seen before
    if (mounted) {
      final hasSeenTour = await prefs.getBool('has_seen_home_tour') ?? false;
      if (!hasSeenTour && !_hasSeenTour) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Check again before showing
            SharedPreferences.getInstance().then((p) async {
              final stillNotSeen = await p.getBool('has_seen_home_tour') ?? false;
              if (mounted && !stillNotSeen) {
                _showTour();
              }
            });
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
          final url = Uri.parse('https://t.me/suprotect'); // Telegram channel link
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
      _isProcessing = true;
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

    // Keep processing state - don't reset, just show processing message
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Stories section - at the top
                  Container(
                    key: _storiesKey,
                    child: _buildStoriesSection(),
                  ),
                  
                  // Upload progress card - below stories
                  if (_isUploading || _uploadProgress > 0 || _isProcessing)
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
                                    _isProcessing ? Icons.build : Icons.cloud_upload,
                                    size: 24.sp,
                                    color: const Color(0xFF9C88FF),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isProcessing ? 'Processing APK' : 'Uploading APK',
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
                                  if (!_isProcessing)
                                    IconButton(
                                      icon: Icon(Icons.close, size: 20.sp),
                                      onPressed: _cancelUpload,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                              if (!_isProcessing) ...[
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
                              ] else ...[
                                SizedBox(height: 12.h),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Welcome section - centered vertically and horizontally
                  Expanded(
                    child: Container(
                      key: _welcomeKey,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isProcessing && !_isUploading && _uploadProgress == 0) ...[
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Upload a file to get started',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.rocket_launch,
                                    size: 20.sp,
                                    color: const Color(0xFF9C88FF),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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

  Widget _buildFakeApkCards() {
    return Column(
      children: [
        _buildFakeApkCard('yourappname.apk', 'Processing', Icons.build, Colors.orange),
        SizedBox(height: 8.h),
        _buildFakeApkCard('yourappname.apk', 'Protected', Icons.security, Colors.green),
        SizedBox(height: 8.h),
        _buildFakeApkCard('yourappname.apk', 'Completed', Icons.check_circle, Colors.blue),
      ],
    );
  }

  Widget _buildFakeApkCard(String fileName, String status, IconData icon, Color statusColor) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF9C88FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.android,
              size: 24.sp,
              color: const Color(0xFF9C88FF),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 14.sp,
                      color: statusColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
