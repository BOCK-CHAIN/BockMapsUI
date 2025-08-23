import 'package:flutter/material.dart';

class ContributePage extends StatelessWidget {
  const ContributePage({super.key});

  final List<_ContributeItem> items = const [
    _ContributeItem(Icons.add_location_alt, "Add a place"),
    _ContributeItem(Icons.edit_location_alt, "Update a place"),
    _ContributeItem(Icons.rate_review, "Write a review"),
    _ContributeItem(Icons.photo_camera, "Add a photo"),
    _ContributeItem(Icons.map, "Fix a map"),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // First row → 3 items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.take(3).map((item) => _buildItem(context, item)).toList(),
          ),
          const SizedBox(height: 30),
          // Second row → 2 items aligned between the first row’s gaps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 40), // pushes first icon a bit inward
              ...items.skip(3).map((item) => _buildItem(context, item)).toList(),
              const SizedBox(width: 40), // pushes second icon a bit inward
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, _ContributeItem item) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tapped on ${item.title}")),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF914294).withOpacity(0.1),
            child: Icon(item.icon, size: 28, color: const Color(0xFF914294)),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF914294),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributeItem {
  final IconData icon;
  final String title;
  const _ContributeItem(this.icon, this.title);
}
