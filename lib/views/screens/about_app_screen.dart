import 'package:flutter/material.dart';
import '../widgets/header.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(title: 'About App', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SectionTitle('DSWD POS System'),
            SizedBox(height: 12),
            _BodyText(
              'The DSWD POS System is built to help associations manage '
              'their point-of-sale operations efficiently and securely. '
              'It simplifies daily transactions and system monitoring '
              'through a clean and intuitive interface.',
            ),
            SizedBox(height: 20),
            _BodyText(
              'Designed for reliability and ease of use, the system supports '
              'both small and large associations in maintaining accuracy, '
              'security, and operational efficiency.',
            ),
            SizedBox(height: 32),
            _SectionTitle('Development Team'),
            SizedBox(height: 12),
            _BodyText(
              'Project Manager\n'
              'Director Glicerio Baguia',
            ),
            SizedBox(height: 16),
            _BodyText(
              'Team Members\n'
              'Kevin Mejares\n'
              'Al Duane Mirasol\n'
              'Jay Suizo\n'
              'Jesel Cardiente\n'
              'Aiza Faith Allera\n'
              'Kristian Rusiana\n'
              'Ashley Mae Tanio\n'
              'Lhory Hiramis\n'
              'Lawrence Ivan Velchez',
            ),
            SizedBox(height: 32),
            Divider(height: 1),
            SizedBox(height: 16),
            _FooterText('Thank you for using the DSWD POS System.'),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
    );
  }
}

class _FooterText extends StatelessWidget {
  final String text;
  const _FooterText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.black54),
    );
  }
}
