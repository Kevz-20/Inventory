import 'package:flutter/material.dart';
import '../widgets/header.dart';

class StockinScreen extends StatefulWidget {
  const StockinScreen({super.key});

  @override
  State<StockinScreen> createState() => _StockinScreenState();
}

class _StockinScreenState extends State<StockinScreen> {
  bool isCash = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: const AppHeader(title: 'Rekord sa Halin', showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isCash = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isCash
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFEAE7DC),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  'Cash',
                                  style: TextStyle(
                                    color: isCash ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isCash = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !isCash
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFEAE7DC),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  'Utang',
                                  style: TextStyle(
                                    color: !isCash
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // ... rest of the body remains unchanged
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
