import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../screens/story_view_screen.dart';

class StoriesService {
  static final StoriesService _instance = StoriesService._internal();
  factory StoriesService() => _instance;
  StoriesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<StoryData>? _cachedStories;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Fetch stories from Firestore
  /// Returns cached stories if available and not expired
  Future<List<StoryData>> getStories({bool forceRefresh = false}) async {
    try {
      // Return cached stories if available and not expired
      if (!forceRefresh && 
          _cachedStories != null && 
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        debugPrint('[StoriesService] Returning cached stories');
        return _cachedStories!;
      }

      debugPrint('[StoriesService] Fetching stories from Firestore...');
      
      // Fetch from Firestore collection 'stories'
      // Stories should be ordered by 'order' field
      final querySnapshot = await _firestore
          .collection('stories')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('[StoriesService] No stories found in Firestore, returning default');
        return _getDefaultStories();
      }

      final stories = <StoryData>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          
          // Parse color from hex string or use default
          Color backgroundColor;
          if (data['backgroundColor'] != null) {
            final colorString = data['backgroundColor'] as String;
            backgroundColor = _parseColor(colorString);
          } else {
            backgroundColor = const Color(0xFF9C88FF); // Default purple
          }

          // Parse icon from string
          IconData icon = Icons.info;
          if (data['icon'] != null) {
            icon = _parseIcon(data['icon'] as String);
          }

          // Create story data
          final story = StoryData(
            title: data['title'] as String? ?? 'Story',
            message: data['message'] as String? ?? '',
            backgroundColor: backgroundColor,
            icon: icon,
            actionLabel: data['actionLabel'] as String?,
            actionIcon: data['actionIcon'] != null 
                ? _parseIcon(data['actionIcon'] as String)
                : null,
            onActionTap: data['actionUrl'] != null
                ? () => _handleActionUrl(data['actionUrl'] as String)
                : null,
          );

          stories.add(story);
        } catch (e) {
          debugPrint('[StoriesService] Error parsing story ${doc.id}: $e');
        }
      }

      // Cache the stories
      _cachedStories = stories;
      _cacheTime = DateTime.now();
      
      debugPrint('[StoriesService] Fetched ${stories.length} stories from Firestore');
      return stories;
    } catch (e, stackTrace) {
      debugPrint('[StoriesService] Error fetching stories: $e');
      debugPrint('[StoriesService] Stack trace: $stackTrace');
      
      // Return default stories on error
      return _getDefaultStories();
    }
  }

  /// Parse color from hex string (e.g., "#9C88FF" or "0xFF9C88FF")
  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.startsWith('0x') || hex.startsWith('0X')) {
        hex = hex.substring(2);
      }
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if missing
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      debugPrint('[StoriesService] Error parsing color: $colorString, using default');
      return const Color(0xFF9C88FF);
    }
  }

  /// Parse icon from string name (e.g., "celebration", "star", "telegram")
  IconData _parseIcon(String iconName) {
    // Map common icon names to IconData
    final iconMap = {
      'celebration': Icons.celebration,
      'star': Icons.star,
      'lightbulb': Icons.lightbulb,
      'telegram': Icons.telegram,
      'info': Icons.info,
      'security': Icons.security,
      'shield': Icons.shield,
      'lock': Icons.lock,
      'check_circle': Icons.check_circle,
      'warning': Icons.warning,
      'error': Icons.error,
      'favorite': Icons.favorite,
      'thumb_up': Icons.thumb_up,
      'notifications': Icons.notifications,
      'settings': Icons.settings,
    };
    
    return iconMap[iconName.toLowerCase()] ?? Icons.info;
  }

  /// Handle action URL (for Telegram link, etc.)
  void _handleActionUrl(String url) {
    // This will be handled by the story view screen
    // We'll pass the URL through the onActionTap callback
    debugPrint('[StoriesService] Action URL: $url');
  }

  /// Get default stories (fallback)
  List<StoryData> _getDefaultStories() {
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
        onActionTap: () {
          // This will be handled in home_screen
        },
      ),
    ];
  }

  /// Clear cache
  void clearCache() {
    _cachedStories = null;
    _cacheTime = null;
    debugPrint('[StoriesService] Cache cleared');
  }
}

