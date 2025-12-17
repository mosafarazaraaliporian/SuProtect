import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'info_screen.dart';
import 'upload_apk_screen.dart';
import '../providers/theme_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Start with Home (index 1)
  String? _uploadFileName;
  final GlobalKey _fabKey = GlobalKey();
  bool _isTourActive = false; // Track if tour is active

  List<Widget> get _screens => [
    const ProfileScreen(),
    HomeScreen(
      jobId: _uploadFileName,
      fabKey: _fabKey,
      onTourStateChanged: (isActive) {
        setState(() {
          _isTourActive = isActive;
        });
      },
    ),
    const InfoScreen(),
  ];

  void _onItemTapped(int index) {
    // Prevent navigation during tour
    if (_isTourActive) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style based on theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: themeProvider.isDarkMode
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: themeProvider.isDarkMode
              ? const Color(0xFF121212)
              : Colors.white,
          systemNavigationBarIconBrightness: themeProvider.isDarkMode
              ? Brightness.light
              : Brightness.dark,
        ),
      );
    });
  }

  void _onUploadPressed() async {
    // Navigate to upload screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadApkScreen(),
      ),
    );

    // If file was selected, switch to Home tab and start upload
    if (result != null && result is String) {
      setState(() {
        _currentIndex = 1; // Switch to Home
        _uploadFileName = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = const Color(0xFF9C88FF);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          floatingActionButton: _currentIndex == 1 // Always show on Home (even during tour)
              ? FloatingActionButton(
                  key: _fabKey,
                  onPressed: _isTourActive ? null : _onUploadPressed,
                  backgroundColor: primaryColor,
                  elevation: 8,
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 70.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.person_outline, 'Profile', 0, isDark, primaryColor),
                    _buildHomeButton(1, isDark, primaryColor),
                    _buildNavItem(Icons.info_outline, 'Info', 2, isDark, primaryColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark, Color primaryColor) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: _isTourActive ? null : () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12.r),
        child: Opacity(
          opacity: _isTourActive ? 0.5 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(int index, bool isDark, Color primaryColor) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: _isTourActive ? null : () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16.r),
        child: Opacity(
          opacity: _isTourActive ? 0.5 : 1.0,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? primaryColor : (isDark ? Colors.grey[400]! : Colors.grey[300]!),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.home,
                    color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    size: 20.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Home',
                  style: TextStyle(
                    color: isSelected ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
