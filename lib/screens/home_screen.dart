import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/logger_service.dart';
import '../services/api_service.dart';
import 'story_view_screen.dart';
import 'upload_apk_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? jobId; // Changed from uploadFileName to jobId
  final GlobalKey? fabKey;
  
  const HomeScreen({super.key, this.jobId, this.fabKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSeenWelcomeStory = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _currentJobId;
  Timer? _statusCheckTimer;
  bool _hasSeenTour = false;
  int _tourStep = 0;
  bool _isProcessing = false;
  String? _processingMessage;
  String? _downloadUrl;
  final GlobalKey _storiesKey = GlobalKey();
  final GlobalKey _welcomeKey = GlobalKey();
  BuildContext? _tourDialogContext;

  @override
  void initState() {
    super.initState();
    LoggerService.logMethod('HomeScreen', 'initState', {
      'jobId': widget.jobId,
    });
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
      LoggerService.logUserAction('screen_view', {'screen': 'home'});
      FirebaseService().logEvent('screen_view', {
        'screen_name': 'home',
        'screen_class': 'HomeScreen',
      });
      // If job_id is provided, start checking status
      if (widget.jobId != null && 
          !_isProcessing && 
          _currentJobId == null) {
        LoggerService.i('HomeScreen', 'Starting status check for job: ${widget.jobId}');
        _currentJobId = widget.jobId;
        _startStatusCheck();
      }
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If job_id changed and we're not currently processing, start checking status
    if (widget.jobId != null && 
        widget.jobId != oldWidget.jobId &&
        !_isProcessing &&
        _currentJobId == null) {
      LoggerService.i('HomeScreen', 'Starting new status check for job: ${widget.jobId}');
      _currentJobId = widget.jobId;
      _startStatusCheck();
    }
  }

  @override
  void dispose() {
    LoggerService.logMethod('HomeScreen', 'dispose');
    _statusCheckTimer?.cancel();
    _closeTourDialog();
    super.dispose();
  }

  Future<void> _checkWelcomeStory() async {
    LoggerService.logMethod('HomeScreen', '_checkWelcomeStory');
    final prefs = await SharedPreferences.getInstance();
    _hasSeenWelcomeStory = prefs.getBool('has_seen_welcome_story') ?? false;
    LoggerService.d('HomeScreen', 'Has seen welcome story: $_hasSeenWelcomeStory');
    
    if (!_hasSeenWelcomeStory && mounted) {
      // Show welcome story after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          LoggerService.logUserAction('show_welcome_story');
          _showWelcomeStory();
        }
      });
    }
  }

  Future<void> _checkTour() async {
    LoggerService.logMethod('HomeScreen', '_checkTour');
    final prefs = await SharedPreferences.getInstance();
    _hasSeenTour = prefs.getBool('has_seen_home_tour') ?? false;
    LoggerService.d('HomeScreen', 'Has seen tour: $_hasSeenTour');
    // Don't show tour automatically - it will be shown after welcome story is seen (only once)
  }

  void _showTour() {
    LoggerService.logMethod('HomeScreen', '_showTour');
    LoggerService.logUserAction('show_tour');
    
    // Close any existing dialog first
    if (_tourDialogContext != null) {
      LoggerService.w('HomeScreen', 'Closing existing tour dialog');
      Navigator.of(_tourDialogContext!).pop();
      _tourDialogContext = null;
    }
    
    setState(() {
      _tourStep = 0;
    });
    LoggerService.d('HomeScreen', 'Tour step reset to 0');
    
    // Wait a bit for the UI to be ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        LoggerService.d('HomeScreen', 'Starting tour step after delay');
        _showTourStep();
      } else {
        LoggerService.w('HomeScreen', 'Widget not mounted, cannot start tour');
      }
    });
  }

  void _closeTourDialog() {
    if (_tourDialogContext != null) {
      LoggerService.d('HomeScreen', 'Closing tour dialog');
      Navigator.of(_tourDialogContext!).pop();
      _tourDialogContext = null;
    } else {
      LoggerService.v('HomeScreen', 'No tour dialog to close');
    }
  }

  void _showTourStep() async {
    LoggerService.logMethod('HomeScreen', '_showTourStep', {
      'tourStep': _tourStep,
      'mounted': mounted,
    });
    
    if (!mounted) {
      LoggerService.w('HomeScreen', 'Widget not mounted, cannot show tour step');
      return;
    }
    
    // Close previous dialog if exists
    _closeTourDialog();
    
    if (_tourStep >= 3) {
      LoggerService.i('HomeScreen', 'Tour completed, marking as seen');
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
        LoggerService.d('HomeScreen', 'Tour step 0: Stories section');
        break;
      case 1:
        title = 'Your Apps';
        description = 'This shows your apps here';
        targetKey = _welcomeKey;
        LoggerService.d('HomeScreen', 'Tour step 1: Welcome section');
        break;
      case 2:
        title = 'Upload Button';
        description = 'Tap the + button to upload your APK file for protection.';
        targetKey = widget.fabKey;
        LoggerService.d('HomeScreen', 'Tour step 2: Upload button (FAB)');
        break;
    }

    // Wait for next frame to ensure widget is fully built
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    // Wait for target key to be available with more attempts
    int attempts = 0;
    while (attempts < 15 && mounted && (targetKey?.currentContext == null)) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    if (targetKey?.currentContext == null || !mounted) {
      LoggerService.w('HomeScreen', 'Target key not found after $attempts attempts, skipping step');
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

    try {
      // Get render box - NEW APPROACH: use context directly
      final BuildContext? targetContext = targetKey?.currentContext;
      if (targetContext == null || !mounted) {
        LoggerService.w('HomeScreen', 'Target context is null');
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

      final RenderBox? renderBox = targetContext.findRenderObject() as RenderBox?;
      
      if (renderBox == null || !renderBox.hasSize || !mounted) {
        LoggerService.w('HomeScreen', 'Cannot get render box, skipping step');
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

      // Get position relative to screen - NEW APPROACH: use localToGlobal correctly
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      
      LoggerService.d('HomeScreen', 'Element position: $position, size: $size');
      
      if (!mounted) return;

      // Show dialog with correct positioning
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.75),
        builder: (dialogContext) {
          if (!mounted) return const SizedBox();
          
          _tourDialogContext = dialogContext;
          
          final screenSize = MediaQuery.of(dialogContext).size;
          final screenHeight = screenSize.height;
          final screenWidth = screenSize.width;
          
          // NEW APPROACH: Use actual position directly, with padding
          final padding = 8.0;
          final highlightLeft = (position.dx - padding).clamp(0.0, screenWidth);
          final highlightTop = (position.dy - padding).clamp(0.0, screenHeight);
          final highlightRight = (position.dx + size.width + padding).clamp(0.0, screenWidth);
          final highlightBottom = (position.dy + size.height + padding).clamp(0.0, screenHeight);
          final highlightWidth = highlightRight - highlightLeft;
          final highlightHeight = highlightBottom - highlightTop;
          
          // Calculate tooltip position
          double tooltipTop;
          if (_tourStep == 2) {
            // FAB - show above
            tooltipTop = (position.dy - 220).clamp(20.0, screenHeight - 300.0);
          } else {
            // Stories/Welcome - show below, or above if not enough space
            tooltipTop = position.dy + size.height + 30;
            if (tooltipTop + 250 > screenHeight) {
              tooltipTop = (position.dy - 250).clamp(20.0, screenHeight - 300.0);
            }
            tooltipTop = tooltipTop.clamp(20.0, screenHeight - 300.0);
          }
          
          LoggerService.v('HomeScreen', 'Highlight: ($highlightLeft, $highlightTop) ${highlightWidth}x$highlightHeight');
          LoggerService.v('HomeScreen', 'Tooltip top: $tooltipTop');

          return Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Dark overlay
                Container(
                  color: Colors.black.withOpacity(0.7),
                ),
                // Highlight area - use calculated position and size
                Positioned(
                  left: highlightLeft,
                  top: highlightTop,
                  child: Container(
                    width: highlightWidth,
                    height: highlightHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF9C88FF),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C88FF).withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                // Tooltip
                Positioned(
                  left: 20,
                  right: 20,
                  top: tooltipTop,
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
                                    LoggerService.logUserAction('tour_previous', {'step': _tourStep});
                                    _closeTourDialog();
                                    if (mounted) {
                                      setState(() {
                                        _tourStep--;
                                      });
                                      LoggerService.d('HomeScreen', 'Tour step changed to: ${_tourStep - 1}');
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
                                  LoggerService.logUserAction('tour_next', {
                                    'currentStep': _tourStep,
                                    'isFinish': _tourStep == 2,
                                  });
                                  _closeTourDialog();
                                  if (!mounted) {
                                    LoggerService.w('HomeScreen', 'Widget not mounted, cannot proceed');
                                    return;
                                  }
                                  
                                  setState(() {
                                    _tourStep++;
                                  });
                                  LoggerService.d('HomeScreen', 'Tour step incremented to: $_tourStep');
                                  
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  if (mounted) {
                                    if (_tourStep < 3) {
                                      LoggerService.d('HomeScreen', 'Showing next tour step');
                                      _showTourStep();
                                    } else {
                                      LoggerService.i('HomeScreen', 'Tour finished, saving state');
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('has_seen_home_tour', true);
                                      if (mounted) {
                                        setState(() {
                                          _hasSeenTour = true;
                                        });
                                        LoggerService.i('HomeScreen', 'Tour marked as seen');
                                      }
                                    }
                                  } else {
                                    LoggerService.w('HomeScreen', 'Widget not mounted after delay');
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
    } catch (e, stackTrace) {
      // Handle error gracefully
      LoggerService.e('HomeScreen', 'Tour guide error', e, stackTrace);
      debugPrint('Tour guide error: $e');
      _closeTourDialog();
      if (mounted) {
        // If error occurs, mark tour as seen to prevent infinite loop
        if (_tourStep >= 2) {
          LoggerService.w('HomeScreen', 'Error at step $_tourStep, marking tour as seen');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_seen_home_tour', true);
          setState(() {
            _hasSeenTour = true;
          });
        } else {
          LoggerService.w('HomeScreen', 'Error at step $_tourStep, skipping to next step');
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
    // Use WidgetsBinding to ensure widget is built before showing tour
    if (mounted) {
      final hasSeenTour = await prefs.getBool('has_seen_home_tour') ?? false;
      if (!hasSeenTour && !_hasSeenTour) {
        // Wait for next frame to ensure widget is fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              SharedPreferences.getInstance().then((p) async {
                final stillNotSeen = await p.getBool('has_seen_home_tour') ?? false;
                if (mounted && !stillNotSeen) {
                  LoggerService.d('HomeScreen', 'Starting tour after welcome story');
                  _showTour();
                }
              });
            }
          });
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

  void _startStatusCheck() {
    LoggerService.logMethod('HomeScreen', '_startStatusCheck', {
      'jobId': _currentJobId,
    });
    
    if (_currentJobId == null) return;
    
    setState(() {
      _isProcessing = true;
      _uploadProgress = 0.0;
      _processingMessage = 'Checking status...';
    });

    // Check status every 2 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _currentJobId == null) {
        timer.cancel();
        return;
      }

      try {
        final status = await ApiService.getJobStatus(_currentJobId!);
        final jobStatus = status['status'] as String;
        final progress = (status['progress'] as int?) ?? 0;
        final message = status['message'] as String? ?? 'Processing...';

        if (mounted) {
          setState(() {
            _uploadProgress = progress / 100.0;
            _processingMessage = message;
          });

          if (jobStatus == 'completed') {
            timer.cancel();
            final downloadUrl = status['download_url'] as String?;
            _completeProcessing(downloadUrl);
          } else if (jobStatus == 'failed') {
            timer.cancel();
            final error = status['error'] as String? ?? 'Processing failed';
            _handleProcessingError(error);
          }
        }
      } catch (e) {
        LoggerService.e('HomeScreen', 'Status check error', e);
        if (mounted) {
          setState(() {
            _processingMessage = 'Error checking status: ${e.toString()}';
          });
        }
      }
    });
  }

  void _completeProcessing(String? downloadUrl) {
    LoggerService.logMethod('HomeScreen', '_completeProcessing', {
      'jobId': _currentJobId,
      'downloadUrl': downloadUrl,
    });
    
    setState(() {
      _isProcessing = false;
      _uploadProgress = 1.0;
      _processingMessage = 'Processing completed!';
      _downloadUrl = downloadUrl;
    });

    // Show completion notification
    NotificationService().showUploadCompleteNotification(
      'APK processed successfully',
    );

    // Show success message with download button
    if (downloadUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processing completed!', style: TextStyle(fontSize: 12.sp)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Download',
            textColor: Colors.white,
            onPressed: () async {
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processing completed!', style: TextStyle(fontSize: 12.sp)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Reset state after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _uploadProgress = 0.0;
          _currentJobId = null;
          _processingMessage = null;
          _downloadUrl = null;
        });
      }
    });
  }

  void _handleProcessingError(String error) {
    LoggerService.e('HomeScreen', 'Processing error: $error');
    
    setState(() {
      _isProcessing = false;
      _uploadProgress = 0.0;
      _processingMessage = 'Processing failed: $error';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing failed: $error', style: TextStyle(fontSize: 12.sp)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );

    // Reset state after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentJobId = null;
          _processingMessage = null;
        });
      }
    });
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
                  
                  // Processing progress card - below stories
                  if (_isProcessing || _uploadProgress > 0)
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
                                    Icons.build,
                                    size: 24.sp,
                                    color: const Color(0xFF9C88FF),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Processing APK',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          _processingMessage ?? 'Processing...',
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
                                  if (_downloadUrl != null)
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final uri = Uri.parse(_downloadUrl!);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      icon: Icon(Icons.download, size: 16.sp),
                                      label: Text('Download', style: TextStyle(fontSize: 11.sp)),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
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
                            if (!_isProcessing && _uploadProgress == 0) ...[
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
