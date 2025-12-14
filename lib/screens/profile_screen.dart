import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = const Color(0xFF9C88FF);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Profile',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16.h),
                CircleAvatar(
                  radius: 40.r,
                  backgroundColor: primaryColor,
                  child: Icon(
                    Icons.person,
                    size: 40.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  authProvider.username ?? 'User',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  authProvider.email ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 32.h),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit_outlined, size: 20.sp, color: primaryColor),
                        title: Text('Edit Profile', style: TextStyle(fontSize: 14.sp)),
                        trailing: Icon(Icons.chevron_right, size: 20.sp),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Edit profile feature coming soon', style: TextStyle(fontSize: 12.sp)),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.dark_mode_outlined, size: 20.sp, color: primaryColor),
                        title: Text('Dark Mode', style: TextStyle(fontSize: 14.sp)),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) => themeProvider.toggleTheme(),
                          activeColor: primaryColor,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.settings_outlined, size: 20.sp, color: primaryColor),
                        title: Text('Settings', style: TextStyle(fontSize: 14.sp)),
                        trailing: Icon(Icons.chevron_right, size: 20.sp),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Settings feature coming soon', style: TextStyle(fontSize: 12.sp)),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.help_outline, size: 20.sp, color: primaryColor),
                        title: Text('Help & Support', style: TextStyle(fontSize: 14.sp)),
                        trailing: Icon(Icons.chevron_right, size: 20.sp),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Help & Support feature coming soon', style: TextStyle(fontSize: 12.sp)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: Icon(Icons.logout, size: 18.sp),
                    label: Text('Logout', style: TextStyle(fontSize: 14.sp)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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
