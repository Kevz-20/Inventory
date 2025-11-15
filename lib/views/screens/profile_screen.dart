import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../widgets/nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            const CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage("assets/profile.png"),
            ),
            const SizedBox(height: 15),

            const Text(
              'Ashley Mae Tanio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 6),
                  Text('Verified Beneficiary'),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _sectionTitle('Personal Information'),
            _infoCard([
              _infoRow(Icons.person, 'Full Name', 'Oirec Dior'),
              _infoRow(Icons.cake, 'Birthday', ' '),
              _infoRow(Icons.phone, 'Contact Number', ' '),
              _infoRow(Icons.location_on, 'Address', ' '),
            ]),

            const SizedBox(height: 20),

            _sectionTitle('Beneficiary Information'),
            _infoCard([
              _infoRow(Icons.badge, 'Category', '4Ps Beneficiary'),
              _infoRow(Icons.info, 'Status', 'Active'),
            ]),

            const SizedBox(height: 20),

            _sectionTitle('Uploaded Documents'),
            _infoCard([
              _infoRow(Icons.picture_as_pdf, 'Valid ID', 'Uploaded'),
              _infoRow(Icons.receipt_long, 'Barangay Certificate', 'Uploaded'),
              _infoRow(
                Icons.insert_drive_file,
                'Birth Certificate',
                'Uploaded',
              ),
            ]),

            const SizedBox(height: 20),

            _sectionTitle('Assistance History'),
            _infoCard([
              _infoRow(Icons.check, 'Last Assistance', 'Food Package'),
              _infoRow(Icons.calendar_today, 'Date Received', 'Oct 18, 2025'),
            ]),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: const Text('Edit Profile'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _sectionTitle(String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _infoCard(List<Widget> children) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.3),
          spreadRadius: 1,
          blurRadius: 5,
        ),
      ],
    ),
    child: Column(children: children),
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Column(
    children: [
      Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      const Divider(height: 20),
    ],
  );
}
