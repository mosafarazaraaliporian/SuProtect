import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import 'story_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSeenWelcomeStory = false;

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
