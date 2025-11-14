import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';

import '../widgets/header.dart';

class UtangScreen extends StatefulWidget {
  const UtangScreen({super.key});

  @override
  State<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends State<UtangScreen> {
  bool isCustomerSelected = true;

  final TextEditingController searchController = TextEditingController();
  bool hideHint = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      appBar: const AppHeader(title: 'Gasto', showBackButton: true),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // TOP TAB BUTTONS
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isCustomerSelected = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isCustomerSelected
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Customer Utang",
                        style: TextStyle(
                          color: isCustomerSelected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isCustomerSelected = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isCustomerSelected
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Owner Utang",
                        style: TextStyle(
                          color: !isCustomerSelected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // SEARCH BAR (Keyboard works normally; suggestion bar suppressed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black54),
                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: searchController,

                    onTap: () {
                      setState(() => hideHint = true);
                    },

                    onChanged: (value) {
                      setState(() => hideHint = value.isNotEmpty);
                    },

                    decoration: InputDecoration(
                      hintText: hideHint ? "" : "Pangalan sa Utangan",
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),

                    style: const TextStyle(fontSize: 16),

                    // ✅ Keyboard shows normally
                    keyboardType: TextInputType.visiblePassword,

                    // ❌ Suggestion bar OFF (as much as Android allows)
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // EMPTY STATE LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                SizedBox(height: 40),
                Center(
                  child: Text(
                    "No Customer Records",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
