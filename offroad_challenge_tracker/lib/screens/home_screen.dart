import 'package:flutter/material.dart';
import 'participant_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  late Animation<Offset> _titleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8),
    )..repeat(reverse: true);

    _alignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _colorAnimation1 = ColorTween(
      begin: Colors.purple,
      end: Colors.indigo,
    ).animate(_controller);

    _colorAnimation2 = ColorTween(
      begin: Colors.pinkAccent,
      end: Colors.cyan,
    ).animate(_controller);

    _titleAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Animated Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: _alignmentAnimation.value,
                      end: _alignmentAnimation.value * -1,
                      colors: [_colorAnimation1.value!, _colorAnimation2.value!],
                    ),
                  ),
                ),
              ),
              // Semi-transparent overlay
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
              // Foreground content
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SlideTransition(
                      position: _titleAnimation,
                      child: Text(
                        'Offroad Challenge Tracker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 12, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    _buildAnimatedMenuButton(
                      context,
                      icon: Icons.group,
                      label: "Manage Participants",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ParticipantScreen()),
                      ),
                    ),
                    SizedBox(height: 25),
                    _buildAnimatedMenuButton(
                      context,
                      icon: Icons.bar_chart,
                      label: "View Rankings",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RankingScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedMenuButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedScale(
          duration: Duration(milliseconds: 200),
          scale: 1.05,
          child: Card(
            color: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 10,
            margin: EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 28),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 30, color: Colors.deepPurple),
                  SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
