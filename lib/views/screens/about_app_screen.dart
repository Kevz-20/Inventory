import 'package:flutter/material.dart';
import '../widgets/header.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: const AppHeader(title: 'About App', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "About DSWD POS System\n\n"
                "This app is designed to empower associations in managing their "
                "Point-of-Sale system efficiently and seamlessly. With this tool, "
                "you can easily edit your profile, change your PIN, view system "
                "settings, track transactions, and more.\n\n"
                "The DSWD POS system is intuitive and reliable, ensuring that "
                "your association can handle daily operations quickly while maintaining "
                "accuracy and security. Whether you are a small team or a large association, "
                "this app is tailored to support your needs.\n\n"
                "We strive to provide a smooth experience for all users, making "
                "account management simple and effective.\n\n"
                "Created by the students of CTU Ginatilan:\n"
                "Project Manager: Director GLicerio Baguia\n"
                "Team Members: Kevin Mejares, Al Duane Mirasol, Jay Suizo, "
                "Jessel Cardeinte, Mariel, Aiza, Shen, Ashleyy, Lhory, Velchez \n \n\n"
                "Thank you for using the DSWD POS System!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
