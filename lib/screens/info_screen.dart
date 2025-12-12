import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

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
              'Info',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 50.sp,
                  color: const Color(0xFF9C88FF),
                ),
                SizedBox(height: 16.h),
                Text(
                  'About SuProtect',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'SuProtect is a comprehensive app protection solution designed to keep your applications secure and safe from various threats.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 24.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'support@suprotect.com',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildFeatureItem(
                  context,
                  Icons.security,
                  'Security Protection',
                  'Advanced security measures to protect your app',
                ),
                _buildFeatureItem(
                  context,
                  Icons.shield,
                  'Threat Detection',
                  'Real-time threat detection and prevention',
                ),
                _buildFeatureItem(
                  context,
                  Icons.lock,
                  'Data Encryption',
                  'Secure data encryption for sensitive information',
                ),
                _buildFeatureItem(
                  context,
                  Icons.analytics,
                  'Monitoring',
                  'Continuous monitoring of app security status',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF9C88FF),
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
