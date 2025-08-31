import 'package:flutter/material.dart';

class ContributePage extends StatelessWidget {
  const ContributePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF914294);
    const Color borderColor = Color(0xFF6A2E6F);
    const Color bgColor = Color(0x22914294);

    Widget buildIcon(IconData icon, String label) {
      return InkWell(
        onTap: () {
          print("tapped");
        },
        borderRadius: BorderRadius.circular(100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: mainColor, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildIcon(Icons.add_location_alt, "Add \n place"),
            buildIcon(Icons.edit_location_alt, "Edit \n place"),
            buildIcon(Icons.reviews, "Add \n review"),
            buildIcon(Icons.add_a_photo, "Add \n photo"),
            buildIcon(Icons.update, "Update \n address"),
          ],
        ),
      ),
    );
  }
}
