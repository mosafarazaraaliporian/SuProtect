import 'package:flutter/material.dart';
import 'dart:async';

class StoryViewScreen extends StatefulWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final IconData icon;

  const StoryViewScreen({
    super.key,
    required this.title,
    required this.message,
    this.backgroundColor = Colors.deepPurple,
    this.icon = Icons.celebration,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  double _progress = 0.0;
  Timer? _timer;

  Color _getLighterColor(Color color) {
    return Color.fromRGBO(
      (color.red + 80).clamp(0, 255),
      (color.green + 80).clamp(0, 255),
      (color.blue + 80).clamp(0, 255),
      color.opacity,
    );
  }

  Color _getDarkerColor(Color color) {
    return Color.fromRGBO(
      (color.red - 80).clamp(0, 255),
      (color.green - 80).clamp(0, 255),
      (color.blue - 80).clamp(0, 255),
      color.opacity,
    );
  }

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1.0) {
            _progress = 1.0;
            timer.cancel();
            // Auto close after 5 seconds
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getLighterColor(widget.backgroundColor),
                    widget.backgroundColor,
                    _getDarkerColor(widget.backgroundColor),
                  ],
                ),
              ),
            ),
            // Progress bar at top
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 70,
                        color: widget.backgroundColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Close button
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

