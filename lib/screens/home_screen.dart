import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stories section
            _buildStoriesSection(),
            
            const SizedBox(height: 24),
            
            // Main content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.home,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to SuProtect',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your app protection solution',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.security,
                            size: 48,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Protection Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Welcome story
          _buildStoryItem(
            title: 'Welcome',
            icon: Icons.celebration,
            color: Colors.deepPurple,
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
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
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
                      width: isNew ? 3 : 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fiber_new,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
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
}
