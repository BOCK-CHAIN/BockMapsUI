import 'package:flutter/material.dart';

class ContributePage extends StatelessWidget {
  const ContributePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF914294);
    const Color borderColor = Color(0xFF6A2E6F);
    const Color bgColor = Color(0x22914294);

    Widget buildOption(IconData icon, String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              print("Pressed: $label");
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Icon(icon, color: mainColor, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildOption(Icons.add_location_alt, "Add Place"),
          buildOption(Icons.edit_location_alt, "Edit Place"),
          buildOption(Icons.reviews, "Add Review"),
          buildOption(Icons.add_a_photo, "Add Photo"),
          buildOption(Icons.update, "Update Address"),
        ],
      ),
    );
  }
}
