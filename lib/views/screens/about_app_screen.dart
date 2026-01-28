// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/header.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Main gradient animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Animated title
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(begin: Colors.black, end: Colors.black)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Animated gradient background
        final gradient = LinearGradient(
          colors: [
            Colors.green.withOpacity(0.3 + 0.2 * _animationController.value),
            Colors.green.withOpacity(0.1 + 0.1 * _animationController.value),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const AppHeader(title: 'About App', showBackButton: true),
          body: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated Title at the top
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Text(
                            "E.M.P.O.W.E.R",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _colorAnimation.value,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  blurRadius: 12,
                                  color: _colorAnimation.value!.withOpacity(
                                    0.7,
                                  ),
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    // Main glowing content box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 2, color: Colors.green),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        """This app empowers associations to efficiently manage their Point-of-Sale system. With this tool, you can:

• Edit Profile
• Change PIN
• Record Sales
• Track History
• Balance Sheet
• Income Statement
• Record Utangan
• Stock In
• and more! 

Created by the students of CTU Ginatilan:

Project Manager:
• Director GLicerio Baguia

Developers:
• Kevin Mejares
• Al Duane Mirasol
• Jessel Cardeinte
• Jay Suizo
• Mariel Duhig
• Aiza Allera
• Kristian Russiana
• Ashleyy Tanio
• Lhory Hiramis
• Ivan Velchez

Thank you for using the DSWD POS System!""",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Footer tip
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.4),
                            Colors.green.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Text(
                        "Tip: Keep your security PIN confidential to protect your account.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
