import 'package:flutter/material.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  String pin = "";

  void _onKeyTap(String value) {
    setState(() {
      if (value == "back") {
        if (pin.isNotEmpty) {
          pin = pin.substring(0, pin.length - 1);
        }
      } else if (value.toLowerCase() == "enter") {
        if (pin == "1234") {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Incorrect PIN")));
          pin = "";
        }
      } else if (pin.length < 4) {
        pin += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 238, 224),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Column(
              children: [
                Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 10),
                const Text(
                  "E.M.P.O.W.E.R",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(26, 0, 0, 0),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                "Mobile Number: 0955555555",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "PIN",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < pin.length
                        ? Colors.black
                        : Colors.transparent,
                    border: Border.all(color: Colors.black54, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GridView.builder(
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    String label;
                    if (index < 9) {
                      label = "${index + 1}";
                    } else if (index == 9) {
                      label = "back";
                    } else if (index == 10) {
                      label = "0";
                    } else {
                      label = "enter";
                    }

                    IconData? icon;
                    Color textColor = Colors.black;
                    if (label == "back") {
                      icon = Icons.backspace_outlined;
                    } else if (label == "enter") {
                      textColor = Colors.green;
                    }

                    return GestureDetector(
                      onTap: () => _onKeyTap(label),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6F1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(26, 0, 0, 0),
                              blurRadius: 3,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: icon != null
                              ? Icon(icon, size: 26, color: Colors.black87)
                              : Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "BAG-ONG ACCOUNT",
                    style: TextStyle(
                      color: Color(0xFF4B3B88),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "NAKALIMOT SA PIN?",
                    style: TextStyle(
                      color: Color(0xFF4B3B88),
                      fontWeight: FontWeight.w600,
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
}
